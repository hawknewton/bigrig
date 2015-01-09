require 'docker'

Excon.defaults[:ssl_verify_peer] = false

class DockerAdapter
  class << self
    def run(args)
      tag = args[:tag]
      unless Docker::Image.exist? tag
        puts "An image with the tag #{tag} doesn't exist, I'm going to try to pull it"
        Docker::Image.create 'fromImage' => tag
      end
      container = Docker::Container.create('Image' => tag, 'name' => args[:name])
      puts "Starting #{tag}"
      container.start
      puts container.id
    end
  end
end
