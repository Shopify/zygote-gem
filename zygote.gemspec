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
    'http://rubygems.org/gems/zygote'
  s.license       = 'MIT'
  s.add_runtime_dependency 'chef-provisioner', ['=0.0.8']
  s.add_runtime_dependency 'genesisreactor', ['=0.0.5']
  s.add_runtime_dependency 'supermodel', ['=0.1.6']
  s.add_runtime_dependency 'em-http-request', ['=1.1.2']
  s.add_development_dependency 'pry', ['=0.10.3']
  s.add_development_dependency 'pry-byebug', ['=3.3.0']
  s.add_development_dependency 'rake', ['=10.4.2']
  s.add_development_dependency 'simplecov', ['=0.10.0']
  s.add_development_dependency 'rspec', ['=3.2.0']
end
