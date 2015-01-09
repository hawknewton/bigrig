require 'docker'

Excon.defaults[:ssl_verify_peer] = false

class DockerAdapter
  class << self
    def build(path)
      Docker::Image.build_from_dir(path).id
    end

    def image_id_by_tag(tag)
      Docker::Image.get(tag).id
    rescue Docker::Error::NotFoundError
      puts "An image with the tag #{tag} doesn't exist, I'm going to try to pull it"
      Docker::Image.create('fromImage' => tag).id
    end

    def run(args)
      container = Docker::Container.create('Image' => args[:image_id], 'name' => args[:name])
      puts "Starting #{args[:name]}"
      container.start
      puts container.id
    end
  end
end
