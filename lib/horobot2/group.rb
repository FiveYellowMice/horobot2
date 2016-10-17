require 'concurrent'

##
# A Group represents a group on social networks. It can connect to multiple social networks simultaniously using different Connections.

class HoroBot2::Group

  attr_reader :bot, :temperature, :name, :connections, :emojis, :threshold, :cooling_speed


  ##
  # Initialize the group, create connecions.

  def initialize(bot, group_config)
    @bot = bot
    @temperature = 0

    @name = group_config[:name] || raise(ArgumentError, 'Group must have a name.')
    @emojis = (group_config[:emojis] || ["\u{1f602}", "\u{1f60b}"]).map {|x| HoroBot2::Emoji.new(x) }
    @threshold = group_config[:threshold] || 100
    @cooling_speed = group_config[:cooling_speed] || 10

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
  # Respond to a Command.

  def command(command)
    @bot.logger.debug("Group '#{self}'") { "Received command '#{command}'." }

    case command.name
    when 'status'
      send_text <<~END
        Status of #{self.name}:
        Temperature: #{self.temperature}/#{self.threshold}
        Emojis: #{emojis.join(' ')}
      END
    when 'temperature'
      send_text self.temperature.to_s
    when 'force_send'
      send_emoji
    else
      @bot.logger.debug("Group '#{self}'") { "Unknown command '#{command.name}'." }
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

    if heat > 0
      add_temperature(heat)
      @bot.logger.info("Group '#{self}'") { "Temperature added #{heat}, current: #{@temperature}." }
    end

    # Select and send Emoji.
    if @temperature >= @threshold
      @temperature = 0
      Concurrent::ScheduledTask.execute(3) do
        begin
          send_emoji
        rescue => e
          @bot.logger.error("Group '#{self}'") { "#{e} #{e.backtrace_locations[0]}" }
        end
      end
    end
  end


  ##
  # Send an Emoji.

  def send_emoji
    result = @emojis.sample * rand(1..5)
    send_text(result)
    @bot.logger.info("Group '#{self}'") { "Sent: '#{result}'." }
  end


  ##
  # Increase temperature by 'number'.

  def add_temperature(number)
    @temperature += number
  end


  ##
  # Decrease temperature by Group's cooling_speed.

  def cool_down
    if @temperature > 0
      @temperature = [0, @temperature - @cooling_speed].max
      @bot.logger.info("Group '#{self}'") { "Cooled down to #{@temperature}." }
    end
  end


  ##
  # Helper method for sending a simple text message.

  def send_text(text)
    send_message HoroBot2::OutgoingMessage.new(
      text: text,
      group: self
    )
  end


  ##
  # Send an OutgoingMessage.

  def send_message(message)
    @connections.each_value do |connection|
      connection.send_message(message)
    end
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
