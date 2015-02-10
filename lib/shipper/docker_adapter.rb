require 'docker'

Excon.defaults[:ssl_verify_peer] = false

class ContainerNotFoundError < StandardError; end
class ImageNotFoundError < StandardError; end
class RepoNotFoundError < StandardError; end
class ContainerRunningError < StandardError; end

class DockerAdapter
  class << self
    def build(path, &block)
      Docker::Image.build_from_dir(path, &block).id
    end

    def container_exists?(name)
      !Docker::Container.get(name).nil?
    rescue Docker::Error::NotFoundError
      false
    end

    def image_id_by_tag(tag)
      Docker::Image.get(tag).id
    rescue Docker::Error::NotFoundError
      raise ImageNotFoundError
    end

    def kill(name)
      Docker::Container.get(name).kill
    rescue Docker::Error::NotFoundError
      raise ContainerNotFoundError
    end

    def logs(name, &block)
      container = Docker::Container.get name
      container.streaming_logs follow: true, stdout: true, stderr: true, &block
    end

    def pull(tag, &block)
      Docker::Image.get(Docker::Image.create('fromImage' => tag, &block).id).id
    rescue Docker::Error::ArgumentError => e
      e.to_s =~ /"id"=>nil/ && raise(RepoNotFoundError)
      raise
    end

    def remove_container(name)
      Docker::Container.get(name).delete
      true
    rescue Docker::Error::NotFoundError
      raise ContainerNotFoundError
    rescue Docker::Error::ServerError => e
      e.to_s =~ /You cannot remove a running container/ && raise(ContainerRunningError)
      raise
    end

    def run(args)
      container = create_container args
      container.start(
        'PortBindings' => port_bindings(args[:ports]),
        'VolumesFrom' => args[:volumes_from]
      )
      container.id
    end

    def running?(name)
      Docker::Container.get(name).info['State']['Running']
    rescue Docker::Error::NotFoundError
      false
    end

    private

    def create_container(args)
      Docker::Container.create(
        'Env' => (args[:env] || {}).map { |n, v| "#{n}=#{v}" },
        'Image' => args[:image_id],
        'name' => args[:name],
        'ExposedPorts' => exposed_ports(args[:ports])
      )
    end

    def exposed_ports(ports)
      container_ports = (ports || []).map do |port|
        port.include?(':') && port.split(':')[1] || port
      end
      Hash[*container_ports.map { |p| ["#{p}/tcp", {}] }.flatten]
    end

    def port_bindings(ports)
      (ports || []).each_with_object({}) do |port, hash|
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
