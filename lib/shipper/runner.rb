module Shipper
  class Runner
    def initialize(application)
      @application = application
    end

    def run
      steps.each { |s| perform_step s }
    end

    private

    def build(path)
      puts "Building #{path}"
      DockerAdapter.build path, &parser_proc
    end

    def containers
      @application.containers
    end

    def depends_on_containers(container, containers)
      (containers.map(&:name) & container.dependencies).any?
    end

    def destroy_existing(containers)
      containers.each do |container|
        begin
          DockerAdapter.remove_container container[:name]
        rescue Shipper::ContainerNotFoundError
        end
      end
    end

    def docker_opts(step)
      step.map do |container|
        docker_opts_for(container).merge image_id: image_id(container)
      end
    end

    def docker_opts_for(container)
      { env: container.env,
        name: container.name,
        ports: container.ports,
        volumes_from: container.volumes_from }
    end

    def image_id(container)
      if container.path
        build container.path
      else
        begin
          DockerAdapter.image_id_by_tag container.tag, &parser_proc
        rescue ImageNotFoundError
          DockerAdapter.pull container.tag, &parser_proc
        end
      end
    end

    def ordered_containers
      DependencyGraph.new(containers).resolve
    end

    def parser_proc
      proc { |chunk| print OutputParser.new.parse chunk }
    end

    def perform_step(step)
      containers = docker_opts step
      destroy_existing containers

      threads = containers.map do |container|
        Thread.new do
          puts "Starting #{container[:name]}"
          puts DockerAdapter.run(container)
        end
      end

      threads.each(&:join)
    end

    def steps
      current_step = []
      steps = [current_step]
      ordered_containers.each do |container|
        if depends_on_containers(container, current_step)
          current_step = []
          steps << current_step
        end
        current_step << container
      end
      steps
    end
  end
end
