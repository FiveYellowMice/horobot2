require 'telegram/bot'

##
# TelegramAdapter is the Adapter for communicating with Telegram groups using Telegram's bot API.

class HoroBot2::Adapters::TelegramAdapter < HoroBot2::Adapter

  def initialize(bot, config)
    super(bot, config)

    @bot.threads << Thread.new do
      Telegram::Bot::Client.run(config['telegram']['token']) do |bot|
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
