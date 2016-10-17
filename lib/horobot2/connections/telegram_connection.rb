##
# TelegramConnection is the connection for TelegramAdapter.

class HoroBot2::Connections::TelegramConnection < HoroBot2::Connection

  attr_reader :group_id

  CONFIG_SECTION = :telegram


  def initialize(group, connection_config)
    @group = group

    @group_id = connection_config[:group_id] || raise(ArgumentError, 'No group ID is given to the Telegram Connection.')
  end


  ##
  # Send a message.

  def send_message(message)
    @group.bot.logger.debug("TelegramConnection '#{@group}'") { "Sending: #{message}" }

    adapter = @group.bot.adapters[HoroBot2::Adapters::TelegramAdapter::CONFIG_SECTION]
    adapter.bot_api.send_message(chat_id: @group_id, text: message.text)
  end


  def to_hash
    {
      group_id: @group_id
    }
  end
end
