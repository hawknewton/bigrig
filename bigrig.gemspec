# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__), 'lib', 'bigrig', 'version.rb'])
Gem::Specification.new do |s|
  s.name = 'bigrig'
  s.version = Bigrig::VERSION
  s.author = 'Hawk Newton'
  s.email = 'hnewton@constantcontact.com'
  s.homepage = 'http://constantcontact.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Bigrig knows how to ship your composite docker applications'
  s.files = `git ls-files`.split('
')
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.bindir = 'bin'
  s.executables << 'bigrig'
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec')
  s.add_development_dependency('rspec-its')
  s.add_development_dependency('rubocop', '~> 0.27.1')
  s.add_development_dependency('vcr', '~> 2.9.3')
  s.add_development_dependency('webmock', '~> 1.20.4')
  s.add_development_dependency('popen4')
  s.add_development_dependency('rspec-eventually')

  s.add_runtime_dependency('gli', '2.12.2')
  s.add_runtime_dependency('colorize', '0.7.5')
  s.add_runtime_dependency('docker-api', '1.21.4')
  s.add_runtime_dependency('filewatcher', '0.4.0')
end
