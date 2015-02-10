class Runner
  def initialize(application)
    @application = application
  end

  def run
    steps.each { |s| perform_step s }
  end

  private

  def containers
    @application.containers
  end

  def depends_on_containers(container, containers)
    (containers.map(&:name) & container.dependencies).any?
  end

  def docker_opts(container)
    { env: container.env,
      name: container.name,
      ports: container.ports,
      volumes_from: container.volumes_from }
  end

  def image_id(container)
    parser = OutputParser.new
    parser_proc = proc { |chunk| print parser.parse chunk }
    if container.path
      puts "Building #{container.path}"
      DockerAdapter.build container.path, &parser_proc
    else
      DockerAdapter.image_id_by_tag container.tag, &parser_proc
    end
  end

  def ordered_containers
    DependencyGraph.new(containers).resolve
  end

  def perform_step(step)
    containers = step.map do |container|
      docker_opts(container).merge image_id: image_id(container)
    end

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
