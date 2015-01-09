require 'docker'

Excon.defaults[:ssl_verify_peer] = false

class DockerAdapter
  class << self
    def build(path)
      puts "Building #{path}"
      Docker::Image.build_from_dir(path).id
    end

    def container_exists?(name)
      !Docker::Container.get(name).nil?
    end

    def image_id_by_tag(tag)
      Docker::Image.get(tag).id
    rescue Docker::Error::NotFoundError
      puts "An image with the tag #{tag} doesn't exist, I'm going to try to pull it"
      Docker::Image.create('fromImage' => tag).id
    end

    def kill(name)
      Docker::Container.get(name).kill
    end

    def remove_container(name)
      Docker::Container.get(name).delete
      true
    rescue Docker::Error::NotFoundError
      false
    end

    def run(args)
      container = create_container args
      puts "Starting #{args[:name]}"
      container.start(
        'PortBindings' => port_bindings(args[:ports]),
        'VolumesFrom' => args[:volumes_from]
      )
      puts container.id
    end

    def running?(name)
      Docker::Container.get(name).info['State']['Running']
    rescue Docker::Error::NotFoundError
      false
    end

    private

    def create_container(args)
      Docker::Container.create(
        'Env' => args[:env].map { |n, v| "#{n}=#{v}" },
        'Image' => args[:image_id],
        'name' => args[:name],
        'ExposedPorts' => exposed_ports(args[:ports])
      )
    end

    def exposed_ports(ports)
      container_ports = ports.map do |port|
        port.include?(':') && port.split(':')[1] || port
      end
      Hash[*container_ports.map { |p| ["#{p}/tcp", {}] }.flatten]
    end

    def port_bindings(ports)
      ports.each_with_object({}) do |port, hash|
        if port.include? ':'
          host_port, container_port = port.split ':'
        else
          container_port = port
        end
        hash["#{container_port}/tcp"] = [host_port && { 'HostPort' => host_port } || {}]
      end
    end
  end
end
