module Shipper
  class DestroyAction
    def initialize(file)
      @application = Application.read file
    end

    def perform
      @application.containers.each do |container|
        if DockerAdapter.running? container.name
          puts "Killing container #{container.name}"
          DockerAdapter.kill container.name
        end

        if DockerAdapter.container_exists? container.name
          puts "Removing container #{container.name}"
          DockerAdapter.remove_container container.name
        end
      end
    end
  end
end
