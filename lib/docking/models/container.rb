class Container < BaseModel
  attr_accessor :name, :path, :tag

  def self.from_json(json)
    opts = [:env, :name, :path, :tag, :volumes_from].each_with_object({}) do |e, o|
      o[e] = json.send :[], e.to_s
    end

    Container.new opts
  end

  def dependencies
    volumes_from
  end

  def env=(list)
    if list.nil?
      @env = nil
    else
      pairs = list.map { |i| parse_env i }
      @env = Hash[*pairs.flatten]
    end
  end

  def env
    @env || {}
  end

  def volumes_from=(list)
    @volumes_from = [list].flatten.compact
  end

  def volumes_from
    @volumes_from || []
  end

  private

  def parse_env(var)
    if var.include? '='
      var.split('=', 2).flatten
    else
      [var, ENV[var]]
    end
  end
end
