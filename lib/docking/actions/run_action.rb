class RunAction
  attr_accessor :application

  def initialize(file)
    @application = Application.read file
  end

  def perform
    steps.each { |s| perform_step s }
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

  def containers
    application.containers
  end

  private

  def depends_on_containers(container, containers)
    (containers.map(&:name) & container.dependencies).any?
  end

  def docker_opts(container)
    { name: container.name, tag: container.tag, volumes_from: container.volumes_from }
  end

  def ordered_containers
    DependencyGraph.new(containers).resolve
  end

  def perform_step(step)
    threads = step.map do |container|
      Thread.new { DockerAdapter.run docker_opts container }
    end

    threads.each(&:join)
  end
end
