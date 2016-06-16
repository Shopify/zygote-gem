lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zygote/version'

Gem::Specification.new do |s|
  s.name        = 'zygote'
  s.version     = Zygote::VERSION
  s.date        = '2015-11-24'
  s.summary     = 'Differentiate servers with iPXE'
  s.description = 'Automate baremetal server actions with iPXE'
  s.authors     = ['Dale Hamel']
  s.email       = 'dale.hamel@srvthe.net'
  s.files       = Dir['lib/**/*', 'views/**/*']
  s.homepage    =
    'https://github.com/dalehamel/zygote-gem'
  s.license = 'MIT'
  s.add_runtime_dependency 'erubis', ['=2.7.0']
  s.add_runtime_dependency 'worsemodel', ['=0.2.0']
  s.add_runtime_dependency 'em-http-request', ['=1.1.2']
  s.add_runtime_dependency 'async_sinatra', ['=1.2.1']
  s.add_runtime_dependency 'em-synchrony', ['=1.0.4']
  s.add_runtime_dependency 'thin', ['>= 1.6.4']
  s.add_runtime_dependency 'rack-contrib', ['>= 1.4.0']
  s.add_development_dependency 'pry', ['=0.10.3']
  s.add_development_dependency 'pry-byebug', ['=3.3.0']
  s.add_development_dependency 'rake', ['=10.4.2']
  s.add_development_dependency 'simplecov', ['=0.10.0']
  s.add_development_dependency 'rspec', ['=3.2.0']
  s.add_development_dependency 'rubocop', ['~> 0.40.0']
end
