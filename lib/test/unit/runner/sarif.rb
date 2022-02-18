require 'test/unit'

module Test
  module Unit
    AutoRunner.register_runner(:sarif) do |auto_runner|
      require 'test/unit/ui/sarif/testrunner'
      Test::Unit::UI::Sarif::TestRunner
    end

    AutoRunner.setup_option do |auto_runner, opts|
      opts.on('--output-file=filename', String, 'Outputs to file filename') do |filename|
        auto_runner.runner_options[:filename] = filename
      end
    end

    module Runner
      module Sarif
        VERSION = "0.0.1"
      end
    end
  end
end
