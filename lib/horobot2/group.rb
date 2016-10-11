##
# A Group represents a group on social networks. It can connect to multiple social networks simultaniously using different Connections.

class HoroBot2::Group

  attr_reader :bot
  attr_accessor :name, :connections, :emojis


  def initialize(bot, group_config)
    @bot = bot

    @name = group_config['name'] || raise(ArgumentError, 'Group must have a name.')

    @connections = {}
    group_config['connections'].each do |connection_config_name, connection_config|
      connection_class = nil
      HoroBot2::Connections.constants.each do |connection_name|
        connection_class = HoroBot2::Connections.const_get(connection_name)
        if connection_class::CONFIG_SECTION == connection_config_name
          break
        end
      end

      @connections[connection_class::CONFIG_SECTION] = connection_class.new(self, connection_config)
    end
  end


  def to_hash
    {
      name: @name,
      connections: @connections.map(&:to_hash),
      emojis: @emojis.map(&:to_hash)
    }
  end

  alias_method :to_h, :to_hash

end
