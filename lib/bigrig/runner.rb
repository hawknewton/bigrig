module Bigrig
  class Runner
    def initialize(containers)
      @containers = containers
    end

    def run
      steps.each { |s| perform_step s }
    end

    private

    attr_accessor :containers

    def build(path)
      puts "Building #{path}"
      DockerAdapter.build path, &OutputParser.parser_proc
    end

    def depends_on_containers(container, containers)
      (containers.map(&:name) & container.dependencies).any?
    end

    def destroy_existing(containers)
      containers.each do |container|
        begin
          DockerAdapter.remove_container container[:name]
        rescue Bigrig::ContainerNotFoundError # rubocop:disable Lint/HandleExceptions
        end
      end
    end

    def docker_opts(step)
      step.map { |c| docker_opts_for c }
    end

    def docker_opts_for(container)
      { env: container.env,
        name: container.name,
        ports: container.ports,
        volumes_from: container.volumes_from,
        volumes: container.volumes,
        links: container.links,
        hosts: container.hosts,
        image_id: image_id(container) }
    end

    def image_id(container)
      if container.path
        build container.path
      else
        tag = "#{container.repo}:#{container.tag}"
        begin
          DockerAdapter.image_id_by_tag tag, &OutputParser.parser_proc
        rescue ImageNotFoundError
          DockerAdapter.pull tag, &OutputParser.parser_proc
        end
      end
    end

    def ordered_containers
      DependencyGraph.new(containers).resolve
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
