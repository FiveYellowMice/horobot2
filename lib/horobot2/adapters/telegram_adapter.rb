require 'telegram/bot'
require 'concurrent'

##
# TelegramAdapter is the Adapter for communicating with Telegram groups using Telegram's bot API.

class HoroBot2::Adapters::TelegramAdapter < HoroBot2::Adapter

  attr_reader :bot_api, :token, :username

  CONFIG_SECTION = :telegram


  def initialize(bot, adapter_config)
    super(bot, adapter_config)

    @token = adapter_config[:token]

    @bot.threads << Thread.new do
      Telegram::Bot::Client.run(@token) do |bot|
        @bot_api = bot.api

        bot.listen do |telegram_message|
          Concurrent::Future.execute do
            begin
              receive(telegram_message)
            rescue => e
              @bot.logger.error('TelegramAdapter') { "#{e} #{e.backtrace_locations[0]}" }
            end
          end
        end
      end
      puts 'The code here should never be executed. (Inside TelegramAdapter)'
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
      if command? telegram_message
        command = HoroBot2::Command.new(
          name: /^\/(\w+)/.match(telegram_message.text)[1],
          arg: /^\/\w+(?:@\w+)? ?(.*)$/.match(telegram_message.text)[1],
          sender: telegram_message.from.username || telegram_message.from.first_name
        )
        begin
          target_group.command(command)
        rescue => e
          @bot.logger.error("Group #{target_group}") { "#{e} #{e.backtrace_locations[0]}" }
        end
      else
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
          @bot.logger.error("Group #{target_group}") { "#{e} #{e.backtrace_locations[0]}" }
        end
      end
    else
      @bot.logger.debug('TelegramAdapter') { "Message: #{telegram_message}" }
      @bot.logger.warn('TelegramAdapter') { "Message from unknown group: #{telegram_message.chat.to_compact_hash}" }
    end
  end

  private :receive


  def command?(telegram_message)
    return false unless telegram_message.text
    return false unless telegram_message.text[0] == '/'
    return false unless telegram_message.text =~ %r(^(?:/\w+@#{@username}(?: |$)|/\w+(?!@)))
    return true
  end

  private :command?

end
