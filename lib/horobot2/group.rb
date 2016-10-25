require 'concurrent'

##
# A Group represents a group on social networks. It can connect to multiple social networks simultaniously using different Connections.

class HoroBot2::Group

  attr_reader :bot, :temperature, :name, :connections, :emojis, :chatlog_emojis, :threshold, :cooling_speed


  ##
  # Initialize the group, create connecions.

  def initialize(bot, group_config)
    @bot = bot
    @temperature = 0
    @chatlog_emojis = []

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

    begin
      case command.name
      when 'help'
        send_text <<~END
          HoroBot2, made with \u{1f4a6} by FiveYellowMice.
          https://github.com/FiveYellowMice/horobot2

          For help related to commands, see https://horobot.ml/commands.php .
        END
      when 'status'
        send_text <<~END
          Status of #{self.name}:
          Temperature: #{self.temperature}/#{self.threshold}
          Cooling speed: #{self.cooling_speed}
          Emojis: #{emojis.join(' ')}
          More: #{@bot.web_interface.baseurl}/status
        END
      when 'temperature'
        send_text self.temperature.to_s
      when 'force_send'
        send_emoji
      when 'set_threshold'
        set_threshold command.arg.to_i
      when 'set_cooling_speed'
        set_cooling_speed command.arg.to_i
      when 'add_emoji'
        add_emoji command.arg
      when 'rem_emoji'
        rem_emoji command.arg
      else
        @bot.logger.debug("Group '#{self}'") { "Unknown command '#{command.name}'." }
      end
    rescue HoroBot2::HoroError => e
      send_text e.message
    end
  end


  ##
  # Process an IncomingMessage.

  def receive(message)
    @bot.logger.debug("Group '#{self}'") { message.to_s(:detail) }

    # Get Emojis from message text.
    if message.text
      matches = message.text.scan(HoroBot2::Emoji::EmojiRegex::SEQUENCES)
      if matches.any?
        @bot.logger.debug("Group '#{self}'") { "Matched #{matches.length} Emojis in the message." }

        matches.each do |new_emoji|
          new_emoji = HoroBot2::Emoji.new(new_emoji)
          if new_emoji.sequence_of_same?
            new_emoji = new_emoji.to_single_emoji
          end
          @chatlog_emojis << new_emoji
        end

        while @chatlog_emojis.length > 200
          @chatlog_emojis.shift
        end
      end
    end

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
    selected = nil

    if @chatlog_emojis.any? && (rand(2) == 1)
      selected = @chatlog_emojis.sample
    else
      selected = @emojis.sample
    end

    result = if selected.single?
      selected * rand(1..5)
    else
      selected
    end

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
    if @cooling_speed > 0 && @temperature > 0
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


  ##
  # Set the threshold.

  def set_threshold(value)
    raise(HoroBot2::HoroError, '阈值必须得是大于 0 的整数呐，不然汝想让每条消息都被咱照顾？') unless value > 0
    @threshold = value
    send_text "说好了，以后阈值就是 #{value} 了。"
    @bot.logger.info("Group '#{self}'") { "Threshold has set to #{value}." }
    @bot.save_changes
  end


  ##
  # Set the cooling speed.

  def set_cooling_speed(value)
    raise(HoroBot2::HoroError, '明明是要冷却，可却设定了负值，是要加热还是冷却呢？') if value < 0
    @cooling_speed = value
    send_text "说好了，以后冷却速度就是 #{value} 了。"
    @bot.logger.info("Group '#{self}'") { "Cooling speed has set to #{value}." }
    @bot.save_changes
  end


  ##
  # Add an Emoji to the Emoji list.

  def add_emoji(new_emoji)
    new_emoji = HoroBot2::Emoji.new(new_emoji)
    if new_emoji.sequence_of_same?
      new_emoji = new_emoji.to_single_emoji
    end

    raise(HoroBot2::HoroError, "看来人类还不知道 '#{new_emoji}' 已经在咱的列表中了。") if @emojis.include? new_emoji

    @emojis << new_emoji

    send_text "汝的 '#{new_emoji}' 借咱用一用。"
    @bot.logger.info("Group '#{self}'") { "Emoji '#{new_emoji}' is added." }
    @bot.save_changes
  end


  ##
  # Remove an Emoji from the Emoji list.

  def rem_emoji(target_emoji)
    raise(HoroBot2::HoroError, "汝认为 '#{target_emoji}' 会在咱的列表里吗？") unless @emojis.include?(target_emoji)
    raise(HoroBot2::HoroError, "这是咱的最后一个 Emoji 了，不能够放弃。") if @emojis.length <= 1

    @emojis.delete(target_emoji)
    send_text "'#{target_emoji}' 果然不好吃。"
    @bot.logger.info("Group '#{self}'") { "Emoji '#{target_emoji}' is removed." }
    @bot.save_changes
  end


  def to_s
    @name
  end


  def to_hash
    {
      name: @name,
      threshold: @threshold,
      cooling_speed: @cooling_speed,
      emojis: @emojis.map(&:to_s),
      connections: @connections.map {|key, value| [key, value.to_h]}.to_h
    }
  end

  alias_method :to_h, :to_hash

end
