require 'colorize'

module Bigrig
  class LogAction
    COLORS = [:green,
              :yellow,
              :light_blue,
              :magenta,
              :light_white]

    def initialize(file)
      @application = Application.read file
    end

    def perform
      threads = @application.containers.map do |container|
        color = next_color
        Thread.new do
          DockerAdapter.logs container.name, &print_block(container.name.send color)
        end
      end

      threads.each(&:join)
    end

    private

    def print_block(name)
      proc do |stream, chunk|
        if stream == :stderr
          print "#{name}: #{chunk.light_red}"
        else
          puts "#{name}: #{chunk}"
        end
        $stdout.flush
      end
    end

    def next_color
      @color ||= 0
      @color += 1
      COLORS[(@color - 1) % 5]
    end
  end
end
