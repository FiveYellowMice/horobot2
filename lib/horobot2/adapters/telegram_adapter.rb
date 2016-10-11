require 'telegram/bot'

##
# TelegramAdapter is the Adapter for communicating with Telegram groups using Telegram's bot API.

class HoroBot2::Adapters::TelegramAdapter < HoroBot2::Adapter

  CONFIG_SECTION = 'telegram'


  def initialize(bot, adapter_config)
    super(bot, adapter_config)

    @bot.threads << Thread.new do
      Telegram::Bot::Client.run(adapter_config['token']) do |bot|
        @bot_api = bot.api

        bot.listen do |telegram_message|
          receive(telegram_message)
        end
      end
    end
  end


  def receive(telegram_message)
    @bot.logger.debug('TelegramAdapter') { "Message: #{telegram_message}" }
  end

  private :receive

end
