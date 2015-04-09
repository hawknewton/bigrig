require 'colorize'
require 'forwardable'

module Bigrig
  class LogTailer
    extend Forwardable

    COLORS = [:green,
              :yellow,
              :light_blue,
              :magenta,
              :light_white]

    def_delegators :@thread, :alive?, :join, :kill

    class << self
      def create(name)
        new name, color_for(name)
      end

      def color_for(name)
        @colors ||= {}
        @colors[name] ||= next_color
      end

      def next_color
        @color ||= 0
        @color += 1
        COLORS[(@color - 1) % 5]
      end
    end

    private

    def initialize(name, color)
      @thread = Thread.new do
        begin
          DockerAdapter.logs name, &print_block(name.send color)
        rescue => e
          puts "Error starting log tailer: #{e}\n#{e.backtrace.join "\n"}"
        end
      end
    end

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
  end
end
