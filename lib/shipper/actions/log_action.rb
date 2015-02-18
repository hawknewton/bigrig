require 'colorize'

module Shipper
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
          DockerAdapter.logs(container.name) do |s, c|
            puts "#{container.name.send color}: #{s == :stderr ? c.light_red : c}"
            $stdout.flush
          end
        end
      end

      threads.each(&:join)
    end

    def next_color
      @color ||= 0
      @color += 1
      COLORS[(@color - 1) % 5]
    end
  end
end
