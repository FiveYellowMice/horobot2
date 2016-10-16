require 'telegram/bot'

##
# TelegramAdapter is the Adapter for communicating with Telegram groups using Telegram's bot API.

class HoroBot2::Adapters::TelegramAdapter < HoroBot2::Adapter

  CONFIG_SECTION = :telegram


  def initialize(bot, adapter_config)
    super(bot, adapter_config)

    @bot.threads << Thread.new do
      Telegram::Bot::Client.run(adapter_config[:token]) do |bot|
        @bot_api = bot.api

        bot.listen do |telegram_message|
          begin
            receive(telegram_message)
          rescue => e
            @bot.logger.error('TelegramAdapter') { "#{e}" }
          end
        end
      end
    end
  end


  def receive(telegram_message)

    target_group = nil
    @bot.groups.each do |group|
      next unless connection = group.connections[HoroBot2::Connections::TelegramConnection::CONFIG_SECTION]
      next unless connection.group_id == telegram_message.chat.id
      target_group = group
    end

    if target_group
      message = HoroBot2::IncomingMessage.new(
        time: Time.at(telegram_message.date),
        author: telegram_message.from.username || telegram_message.from.first_name,
        text: telegram_message.text || telegram_message.caption,
        image: telegram_message.sticker || (telegram_message.photo.any? ? true : false),
        group: target_group
      )
      begin
        target_group.receive(message)
      rescue => e
        @bot.logger.error("Group #{target_group}") { "#{e}" }
      end
    else
      @bot.logger.debug('TelegramAdapter') { "Message: #{telegram_message}" }
    end
  end

  private :receive

end
