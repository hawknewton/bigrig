require 'vcr'
require 'webmock'
require 'docker'

VCR.configure do |c|
  docker_host = URI.parse(Docker.url).host
  c.allow_http_connections_when_no_cassette = false
  c.filter_sensitive_data('<USERNAME>') { ENV['DOCKER_API_USER'] }
  c.filter_sensitive_data('<PASSWORD>') { ENV['DOCKER_API_PASS'] }
  c.filter_sensitive_data('<EMAIL>') { ENV['DOCKER_API_EMAIL'] }

  c.define_cassette_placeholder('<ENCODED_REPO_URL>') { "#{docker_host}%3A5000" }
  c.define_cassette_placeholder('<REPO_URL>') { "#{docker_host}:5000" }
  c.define_cassette_placeholder('<TEST_URL>') { "http://#{docker_host}:4568" }
  c.define_cassette_placeholder('<DOCKER_HOST>') { Docker.url.sub(/tcp\:/, 'https:') }
  c.define_cassette_placeholder('<DOCKER_HTTP>') { "http:#{Docker.url.split(':')[1]}:4567" }
  c.hook_into :excon, :webmock
  c.cassette_library_dir = File.join(File.dirname(__FILE__), '..', 'vcr')
  defined?(RSpec) && c.configure_rspec_metadata!
end
