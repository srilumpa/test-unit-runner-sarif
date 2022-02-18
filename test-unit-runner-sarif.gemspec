# encoding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require './lib/test/unit/runner/sarif'

Gem::Specification.new do |s|
  s.name = 'test-unit-runner-sarif'
  s.version = Test::Unit::Runner::Sarif::VERSION

  s.required_rubygems_version = Gem::Specification.new('>=0') if s.respond_to? :required_rubygems_version=
  s.authors = ['srilumpa']
  s.date = Time.new.strftime('%Y-%m-%d')
  s.email = 'marcandre.doll@gmail.com'
  s.license = 'Apache-2.0'
  s.homepage = 'https://github.com/srilumpa/test-unit-runner-sarif'
  s.summary = ''

  s.extra_rdoc_files = [
    'README.md'
  ]
  s.files = [
    'AUTHORS',
    'VERSION',
    'lib/test/unit/runner/sarif.rb',
    'lib/test/unit/ui/sarif/testrunner.rb'
  ]
  s.test_files = [
  ]
  s.require_paths = ['lib']

  if s.respond_to? :specification_version
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0')
      s.add_runtime_dependency('test-unit', '~> 3')
    else
      s.add_dependency('test-unit', '~> 3')
    end
  else
    s.add_dependency('test-unit', '~> 3')
  end
  s.add_development_dependency 'bundler', '~> 2'
  s.add_development_dependency 'rake', '~> 13'
end
