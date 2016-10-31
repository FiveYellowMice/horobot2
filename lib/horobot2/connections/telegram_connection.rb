##
# TelegramConnection is the connection for TelegramAdapter.

class HoroBot2::Connections::TelegramConnection < HoroBot2::Connection

  attr_reader :group_id, :quiet

  CONFIG_SECTION = :telegram


  def initialize(group, connection_config)
    @group = group

    @group_id = connection_config[:group_id] || raise(ArgumentError, 'No group ID is given to TelegramConnection.')
    @quiet = connection_config[:quiet] || false
  end


  ##
  # Respond to a command.

  def command(command)
    case command.name
    when 'telegram_set_quiet'
      if %w[yes true on].include? command.arg.strip.downcase
        @quiet = true
        @group.send_text "咱会在 Telegram 里保持安静的。"
        @group.bot.save_changes
      elsif %w[no false off].include? command.arg.strip.downcase
        @quiet = false
        @group.send_text "不能让咱一直不在 Telegram 说话，是不是？"
        @group.bot.save_changes
      else
        @group.send_text "汝可以用 yes, true, on, no, false, off 来作为这条命令的参数呐。"
      end
    when 'telegram_is_quiet'
      @group.send_text @quiet ? "咱可是贤狼呐，保持安静可是小菜一碟。" : "汝没有说的事情，咱怎么会知道呢？"
    else
      @group.bot.logger.debug("TelegramConnection '#{@group}'") { "Unknown command '#{command.name}'." }
    end
  end


  ##
  # Send a message.

  def send_message(message)
    return if @quiet

    @group.bot.logger.debug("TelegramConnection '#{@group}'") { "Sending: #{message}" }

    adapter = @group.bot.adapters[HoroBot2::Adapters::TelegramAdapter::CONFIG_SECTION]
    adapter.bot_api.send_message(chat_id: @group_id, text: message.text)
  end


  def to_hash
    {
      group_id: @group_id,
      quiet: @quiet
    }
  end

  alias_method :to_h, :to_hash

end
