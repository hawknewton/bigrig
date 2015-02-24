module Bigrig
  class ShipAction
    def initialize(file, version)
      @file = file
      @version = version
    end

    def perform
      json = JSON.parse File.read @file
      json['containers'].each do |name, container|
        container['path'] && build_and_push!(name, container)
      end

      File.write outfile, JSON.dump(json)
    end

    private

    def build_and_push!(name, container)
      path = container.delete 'path'
      tag = "#{name}:#{@version}"
      container['tag'] = tag
      image = DockerAdapter.build path
      DockerAdapter.tag image, tag
      DockerAdapter.push tag
    end

    def outfile
      "#{@file.split('.').first}-#{@version}.json"
    end
  end
end
