module Bigrig
  class Waiter
    def initialize(name)
      @name = name
    end

    def wait_if_needed
      script_present? || return
      puts "Waiting for `/bigrig-wait.sh` to compelte on #{@name}"
      result = DockerAdapter.exec @name, '/bigrig-wait.sh'
      result[2] != 0 && fail("Error waiting for container: #{result.first.first}")
    end

    def script_present?
      DockerAdapter.exec(@name, ['ls', '/bigrig-wait.sh'])[2] == 0
    rescue Docker::Error::NotFoundError => e
      puts "Unable to determine if wait script is available: #{e}"
    end
  end
end
