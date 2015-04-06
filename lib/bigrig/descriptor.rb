require 'json'

module Bigrig
  class Descriptor
    attr_reader :as_json

    def initialize(container_map, profiles)
      profiles.each do |_name, containers|
        containers.each do |container, overrides|
          apply_overrides container_map, container, overrides
        end
      end
      @as_json = container_map
    end

    def self.read(file, active_profiles = [])
      json = JSON.parse File.read file
      Descriptor.new json['containers'], profiles_for(json, active_profiles)
    end

    private

    def apply_overrides(container_map, name, overrides)
      overrides.each do |key, value|
        container = container_map[name] ||= {}
        if value.is_a? Hash
          (container[key] ||= {}).merge! value
        elsif %w(volumes volumes_from).include? key
          container[key] = (([container[key]] || []) + [value]).flatten
        else
          container[key] = value
        end
      end
    end

    def self.profiles_for(json, active_profiles)
      if json['profiles']
        active_profiles = json['profiles'].keys.select { |x| active_profiles.include? x }
        profiles = active_profiles.map do |profile|
          [profile, json['profiles'][profile]]
        end
      end
      Hash[*(profiles || []).flatten].select { |_n, v| !v.nil? }
    end
  end
end
