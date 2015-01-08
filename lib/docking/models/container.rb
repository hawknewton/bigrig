class Container < BaseModel
  attr_accessor :name, :tag
  attr_writer :volumes_from

  def self.from_json(json)
    Container.new name: json['name'], tag: json['tag'], volumes_from: json['volumes_from']
  end

  def dependencies
    volumes_from
  end

  def volumes_from
    [@volumes_from].flatten.compact
  end
end
