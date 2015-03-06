module Bigrig
  class ShipAction
    def initialize(file, version, clean, credentials)
      @file = file
      @version = version
      @clean = clean
      @credentials = credentials
    end

    def perform
      containers.each do |_name, container|
        container['path'] && build_and_push!(container)
      end

      File.write outfile, JSON.dump(json)
    end

    private

    def build_and_push!(container)
      path = container.delete 'path'
      repo_and_tag = "#{container['repo']}:#{@version}"
      container['tag'] = @version
      image = DockerAdapter.build path, &OutputParser.parser_proc
      DockerAdapter.tag image, repo_and_tag
      DockerAdapter.push repo_and_tag, credentials, &OutputParser.parser_proc
      @clean && DockerAdapter.remove_image(image)
    end

    def containers
      json['containers']
    end

    def credentials
      @credentials && {
        'username' => @credentials[:username],
        'password' => @credentials[:password],
        'email' => @credentials[:email],
        'serveraddress' => 'https://index.docker.io/v1'
      }
    end

    def json
      @json ||= JSON.parse File.read @file
    end

    def outfile
      "#{@file.split('.').first}-#{@version}.json"
    end
  end
end
