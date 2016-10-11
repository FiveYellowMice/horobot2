##
# A Group represents a group on social networks. It can connect to multiple social networks simultaniously using different Connections.

class HoroBot2::Group

  attr_accessor :name, :connections, :emojis


  def to_hash
    { name: @name,
      connections: @connections.map(&:to_hash),
      emojis: @emojis.map(&:to_hash) }
  end

  alias_method :to_h, :to_hash

end
