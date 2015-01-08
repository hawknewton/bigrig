# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__), 'lib', 'docking', 'version.rb'])
Gem::Specification.new do |s|
  s.name = 'docking'
  s.version = Docking::VERSION
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
  s.files = `git ls-files`.split('
')
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc', 'docking.rdoc']
  s.rdoc_options << '--title' << 'docking' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'docking'
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec')
  s.add_development_dependency('rubocop')

  s.add_runtime_dependency('gli', '2.12.2')
end
