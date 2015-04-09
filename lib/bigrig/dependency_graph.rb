module Bigrig
  class DependencyGraph
    def initialize(containers)
      @containers = containers
      @map = containers.each_with_object({}) { |e, o| o[e.name] = e }
    end

    def resolve
      startup_order @containers
    end

    def resolve_subtree(container)
      startup_order @containers.select { |c| resolve_deps(c, []).include? container.name }
    end

    private

    def containers_for(names)
      names.map { |n| @map[n] }
    end

    def startup_order(containers)
      resolved = []
      containers.each { |c| resolve_deps(c, resolved) unless resolved.include? c.name }
      containers_for resolved
    end

    def resolve_deps(container, resolved)
      container.dependencies.each do |dep_name|
        resolve_deps @map[dep_name], resolved unless resolved.include? dep_name
      end
      resolved << container.name
    end
  end
end
