module Bigrig
  class DependencyGraph
    def initialize(containers)
      @containers = containers
      @map = containers.each_with_object({}) { |e, o| o[e.name] = e }
    end

    def resolve
      resolved = []
      @containers.each { |c| resolve_deps(c, resolved) unless resolved.include? c.name }
      resolved.map { |n| @map[n] }
    end

    def resolve_deps(container, resolved)
      container.dependencies.each do |dep_name|
        resolve_deps @map[dep_name], resolved unless resolved.include? dep_name
      end
      resolved << container.name
    end
  end
end
