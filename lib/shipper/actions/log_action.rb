class LogAction
  def initialize(file)
    @application = Application.read file
  end

  def perform
    threads = @application.containers.map do |container|
      Thread.new do
        DockerAdapter.logs(container.name) do |s, c|
          puts "#{s}: #{c}"
          $stdout.flush
        end
      end
    end

    threads.each(&:join)
  end
end
