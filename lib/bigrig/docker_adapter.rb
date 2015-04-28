require 'docker'

Excon.defaults[:ssl_verify_peer] = false
Excon.defaults[:read_timeout] = 3600

module Bigrig
  class ContainerNotFoundError < StandardError; end
  class ImageNotFoundError < StandardError; end
  class RepoNotFoundError < StandardError; end
  class ContainerRunningError < StandardError; end

  class DockerAdapter
    class << self
      def build(path, &block)
        Docker::Image.build_from_tar(Tar.create_dir_tar(path), {}, connection, &block).id
      end

      def container_exists?(name)
        !Docker::Container.get(name).nil?
      rescue Docker::Error::NotFoundError
        false
      end

      def hosts(arr)
        (arr || []).map do |line|
          parts = line.split ':'
          "#{Resolv.getaddress parts.first}:#{parts[1]}"
        end
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
        container = Docker::Container.get name, {}, connection
        container.streaming_logs follow: true, stdout: true, stderr: true, &block
      end

      def pull(tag, &block)
        Docker::Image.get(Docker::Image.create('fromImage' => tag, &block).id).id
      rescue Docker::Error::ArgumentError => e
        e.to_s =~ /"id"=>nil/ && raise(RepoNotFoundError)
        raise
      end

      def push(tag, credentials = nil, &block)
        puts "Pushing #{tag}"
        Docker::Image.get(tag).push credentials, {}, &block
      end

      def tag(id, tag)
        i = tag.rindex ':'
        repo, version = [tag[0...i], tag[i + 1..-1]]
        Docker::Image.get(id).tag 'repo' => repo, 'tag' => version, 'force' => true
      end

      def remove_container(name)
        fail ContainerRunningError, 'You cannot remove a running container' if running?(name)
        Docker::Container.get(name).delete
        true
      rescue Docker::Error::NotFoundError
        raise ContainerNotFoundError
      end

      def remove_image(tag)
        Docker::Image.get(tag).remove 'force' => true
        true
      rescue Docker::Error::NotFoundError
        raise ImageNotFoundError
      end

      def run(args)
        container = create_container args
        container.start(
          'Links' => args[:links],
          'ExtraHosts' => hosts(args[:hosts]),
          'PortBindings' => port_bindings(args[:ports]),
          'VolumesFrom' => args[:volumes_from],
          'Binds' => args[:volumes]
        )
        container.id
      end

      def running?(name)
        Docker::Container.get(name).info['State']['Running']
      rescue Docker::Error::NotFoundError
        false
      end

      private

      def connection
        options = Docker.env_options.merge read_timeout: 31_536_000
        Docker::Connection.new Docker.url, options
      end

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
          host_port, container_port = port.include?(':') && port.split(':') || [nil, port]
          hash["#{container_port}/tcp"] = [host_port && { 'HostPort' => host_port } || {}]
        end
      end
    end
  end
end
