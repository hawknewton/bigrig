require 'erb'

module Bigrig
  class Renderer
    attr_reader :profiles

    def initialize(profiles)
      @profiles = profiles
    end

    def render
      ERB.new(File.read 'docker-compose.yml.erb').result binding
    end

    def method_missing(name, *args)
      match = /(.+)_profile_active\?$/.match(name)
      if match
        (profiles & [match[1]]).any?
      else
        super
      end
    end
  end
end
