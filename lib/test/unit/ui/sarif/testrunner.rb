require 'json'
require 'test/unit/version'
require 'test/unit/code-snippet-fetcher'
require 'test/unit/fault-location-detector'
require 'test/unit/ui/testrunner'
require 'test/unit/ui/testrunnermediator'
require 'test/unit/ui/testrunnerutilities'

module Test
  module Unit
    module UI
      module Sarif

        # Runs a Test::Unit::TestSuite and outputs SARIF.
        class TestRunner < UI::TestRunner

          # Creates a new TestRunner for running the passed
          # suite. :output option specifies where runner
          # output should go to; defaults to STDOUT.
          def initialize(suite, options={})
            super

            @output = @options[:output] || STDOUT
            if @options[:output_file_descriptor]
              @output = IO.new(@options[:output_file_descriptor], "w")
            end

            @code_snippet_fetcher = CodeSnippetFetcher.new

            test_unit_gem_spec = Gem::loaded_specs['test-unit']
            test_unit_ext_gem_specs = Gem::loaded_specs.select {|k,v| k.start_with?('test-unit-')}

            @all_successful = true

            @result = {
              version: '2.1.0',
              :$schema => 'https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Documents/CommitteeSpecifications/2.1.0/sarif-schema-2.1.0.json',
              runs: [
                {
                  tool: {
                    driver: {
                      name: 'test-unit',
                      semanticVersion: test_unit_gem_spec.version.to_s,
                      informationUri: test_unit_gem_spec.homepage
                    },
                    extensions: test_unit_ext_gem_specs.map do |name, gemspec|
                      {
                        name: name,
                        semanticVersion: gemspec.version.to_s,
                        informationUri: gemspec.homepage
                      }
                    end
                  },
                  invocations: [{}],
                  results: []
                }
              ]
            }
          end

          private

          def attach_to_mediator
            @mediator.add_listener(TestResult::PASS_ASSERTION, &method(:result_pass_assertion))
            @mediator.add_listener(TestResult::FAULT, &method(:result_fault))
            @mediator.add_listener(TestRunnerMediator::STARTED, &method(:started))
            @mediator.add_listener(TestRunnerMediator::FINISHED, &method(:finished))
            @mediator.add_listener(TestCase::STARTED_OBJECT, &method(:start_test))
          end

          def started(result)
            @result[:runs].first[:invocations].first[:startTimeUtc] = Time.now.iso8601
          end

          def start_test(test)
            @current_test = test
          end

          def result_pass_assertion(result)
            @result[:runs].first[:results] << {
              kind: 'pass',
              level: 'none',
              ruleId: @current_test.to_s,
              message: {
                text: 'Success',
                markdown: 'Success'
              }
            }
          end

          def result_fault(fault)
            extract_backtrace(fault)
            @all_successful = false
            kind, level = get_level(fault)
            data = {
              level: level,
              kind: kind,
              ruleId: fault.test_name,
              message: {
                text: "#{fault.class.name}: #{fault.message}",
                markdown: "__#{fault.class.name}__: #{fault.message}"
              },
              locations: extract_backtrace(fault).map do |loc|
                {
                  physicalLocation: {
                    artifactLocation: {
                      uri: loc[:file]
                    },
                    region: {
                      startLine: loc[:lineno],
                      snippet: {
                        text: loc[:line]
                      }
                    },
                    contextRegion: {
                      startLine: loc[:snippet][:start],
                      endLine: loc[:snippet][:end],
                      snippet: {
                        text: loc[:snippet][:text]
                      }
                    }
                  }
                }
              end
            }
            if fault.is_a?(Test::Unit::Failure)
              data[:properties] = {
                expected: fault.expected.to_s,
                actual: fault.actual.to_s
              }
            end
            @result[:runs].first[:results] << data
          end

          def finished(elapsed_time)
            @result[:runs].first[:invocations].first[:endTimeUtc] = Time.now.iso8601
            @result[:runs].first[:invocations].first[:executionSuccessful] = @all_successful
            @output.puts @result.to_json
          end

          def get_level(fault)
            case fault
            when Omission
              ['notApplicable', 'none']
            when Notification
              ['fail', 'note']
            when Pending
              ['notApplicable', 'none']
            when Error
              ['fail', 'warning']
            when Failure
              ['fail', 'error']
            else
              ['review', 'none']
            end
          end

          def extract_backtrace(fault)
            result = []
            detector = FaultLocationDetector.new(fault, @code_snippet_fetcher)
            backtrace = fault.location || []
            backtrace.each_with_index do |entry, i|
              file, line = detector.split_backtrace_entry(entry)
              lines = @code_snippet_fetcher.fetch(file, line)
              result << {
                file: file,
                lineno: line,
                line: lines.select {|l| l.last[:target_line?] }.first[1],
                snippet: {
                  start: lines.first.first,
                  end: lines.last.first,
                  text: lines.map{ |l| l[1] }.join("\n")
                }
              }
            end
            return result
          end
        end
      end
    end
  end
end
