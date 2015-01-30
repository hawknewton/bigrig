require 'json'

class Application < BaseModel
  attr_accessor :name, :containers

  def initialize(args = {})
    @containers = []
    super
  end

  class << self
    def read(file)
      from_json JSON.load File.read file
    end

    def from_json(json)
      containers = json['containers'].map do |name, value|
        Container.from_json name, value
      end

      Application.new containers: containers
    end
  end
end
