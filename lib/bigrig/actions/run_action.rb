module Bigrig
  class RunAction
    attr_accessor :application

    def initialize(active_containers)
      application = Application.from_json active_containers
      @runner = Runner.new application.containers
    end

    def perform
      @runner.run
    end
  end
end
