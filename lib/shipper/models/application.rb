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
      containers = json['containers'].map do |container|
        Container.from_json container
      end

      containers.each do |container|
        matches = containers.select { |c| c.name == container.name }
        fail "Two containers may not have the same name: #{container.name}" if matches.size > 1
      end

      Application.new containers: containers
    end
  end
end
