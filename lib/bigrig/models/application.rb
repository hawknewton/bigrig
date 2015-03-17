require 'json'

module Bigrig
  class Application < BaseModel
    attr_accessor :name, :containers

    def initialize(args = {})
      @containers = []
      super
    end

    class << self
      def from_json(json)
        containers = json.map do |name, value|
          Container.from_json name, value
        end

        Application.new containers: containers
      end
    end
  end
end
