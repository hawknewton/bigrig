module Bigrig
  class DevAction
    def initialize(active_containers)
      @active_containers = active_containers
    end

    def perform
      RunAction.new(@active_containers).perform
      [:SIGTERM, :SIGINT].each { |s| Signal.trap(s) { destroy } }
      LogAction.new(@active_containers).perform
    end

    private

    def destroy
      DestroyAction.new(@active_containers).perform
    end
  end
end
