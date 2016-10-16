##
# A Group represents a group on social networks. It can connect to multiple social networks simultaniously using different Connections.

class HoroBot2::Group

  attr_reader :bot, :temperature
  attr_accessor :name, :connections, :emojis, :threshold


  ##
  # Initialize the group, create connecions.

  def initialize(bot, group_config)
    @bot = bot
    @temperature = 0

    @name = group_config[:name] || raise(ArgumentError, 'Group must have a name.')
    @emojis = group_config[:emojis] || ["\u{1f602}", "\u{1f60b}"] # :joy:, :yum:
    @threshold = group_config[:threshold] || 100

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
    @bot.logger.info("Group '#{self}'") { "Temperature added #{heat}, current: #{@temperature}." }

    # Select and send Emoji.
    if @temperature >= @threshold
      @temperature = 0
      send_emoji
    end
  end


  ##
  # Send an Emoji.

  def send_emoji
    outgoing_message = HoroBot2::OutgoingMessage.new({
      text: @emojis[rand(@emojis.length)] * rand(1..5),
      group: self
    })

    send_message(outgoing_message)
  end


  ##
  # Increase temperature by 'number'.

  def add_temperature(number)
    @temperature += number
  end


  ##
  # Send an OutgoingMessage.

  def send_message(message)
    @connections.each_value do |connection|
      connection.send_message(message)
    end
    @bot.logger.info("Group '#{self}'") { "Sent: '#{message}'." }
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
