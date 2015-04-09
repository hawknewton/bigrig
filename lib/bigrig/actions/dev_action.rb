require 'filewatcher'

module Bigrig
  class DevAction
    def initialize(active_containers)
      @active_containers = active_containers
      @application = Application.from_json active_containers
      @restarting = 0
    end

    def perform
      Thread.new { watch_for_changes }

      RunAction.new(@active_containers).perform
      [:SIGTERM, :SIGINT].each { |s| Signal.trap(s) { destroy } }

      follow_logs
      wait_for_containers
    end

    private

    def destroy
      DestroyAction.new(@active_containers).perform
    end

    def follow_logs
      @tailers = @application.containers.map do |container|
        LogTailer.create container.name
      end
    end

    def kill_containers(containers)
      containers.reverse.each do |c|
        puts "Killing #{c.name} for restart".light_white
        DockerAdapter.kill c.name
      end
    end

    def restart(container)
      @restarting += 1
      containers = DependencyGraph.new(@application.containers).resolve_subtree container
      kill_containers containers
      Runner.new(containers).run
      containers.each { |c| @tailers << LogTailer.create(c.name) }
    ensure
      @restarting -= 1
    end

    def tailers
      @tailers ||= []
    end

    def watch_for_changes
      @application.containers.select(&:scan).each do |container|
        FileWatcher.new([container.scan]).watch do
          begin
            restart container
          rescue => e
            puts "Error restarting container: #{e}\n#{e.backtrace.join}".red
          end
        end
      end
    end

    def wait_for_containers
      while @tailers.any? || @restarting != 0
        @tailers.each(&:join)
        @tailers.keep_if(&:alive?)
        sleep 0.1
      end
    end
  end
end
