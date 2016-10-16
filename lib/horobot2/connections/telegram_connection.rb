##
# TelegramConnection is the connection for TelegramAdapter.

class HoroBot2::Connections::TelegramConnection < HoroBot2::Connection

  attr_reader :group_id

  CONFIG_SECTION = 'telegram'


  def initialize(group, connection_config)
    @group = group

    @group_id = connection_config['group_id']
  end


  ##
  # Send a message.

  def send_message
  end


  def to_hash
    {
      group_id: @group_id
    }
  end
end
