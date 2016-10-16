##
# A Group represents a group on social networks. It can connect to multiple social networks simultaniously using different Connections.

class HoroBot2::Group

  attr_reader :bot, :temperature
  attr_accessor :name, :connections, :emojis


  ##
  # Initialize the group, create connecions.

  def initialize(bot, group_config)
    @bot = bot
    @temperature = 0

    @name = group_config[:name] || raise(ArgumentError, 'Group must have a name.')

    @connections = {}
    group_config[:connections].each do |connection_config_name, connection_config|
      connection_class = nil
      HoroBot2::Connections.constants.each do |connection_name|
        if connection_config_name == HoroBot2::Connections.const_get(connection_name)::CONFIG_SECTION
          connection_class = HoroBot2::Connections.const_get(connection_name)
        end
      end

      if connection_class
        @connections[connection_class::CONFIG_SECTION] = connection_class.new(self, connection_config)
      else
        raise "Unknown connection config key '#{connection_config_name}'."
      end
    end
  end


  ##
  # Process an IncomingMessage.

  def receive(message)
    @bot.logger.debug("Group '#{self}'") { message.to_s(:detail) }

    # Increase temperature base on the message.
    heat = 0
    if message.text
      heat += [(message.text.length / 2.0).ceil, 20].min
    end
    if message.image
      heat += 5
    end

    add_temperature(heat)
    @bot.logger.info("Group '#{self}'") { "Temperature added #{heat}, current: #{self.temperature}." }
  end


  ##
  # Increase temperature by 'number'.

  def add_temperature(number)
    @temperature += number
  end


  def to_s
    @name
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
