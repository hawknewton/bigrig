class Container < BaseModel
  attr_accessor :name, :path, :tag
  attr_writer :volumes_from

  def self.from_json(json)
    opts = [:name, :path, :tag, :volumes_from].each_with_object({}) do |e, o|
      o[e] = json.send :[], e.to_s
    end

    Container.new opts
  end

  def dependencies
    volumes_from
  end

  def volumes_from
    [@volumes_from].flatten.compact
  end
end
