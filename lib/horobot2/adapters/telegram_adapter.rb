require 'telegram/bot'
require 'concurrent'

##
# TelegramAdapter is the Adapter for communicating with Telegram groups using Telegram's bot API.

class HoroBot2::Adapters::TelegramAdapter < HoroBot2::Adapter

  attr_reader :bot_api, :token, :username

  CONFIG_SECTION = :telegram


  def initialize(bot, adapter_config)
    super(bot, adapter_config)

    @token = adapter_config[:token] || raise(ArgumentError, 'TelegramAdapter requires a token.')
    @username = adapter_config[:username] || raise(ArgumentError, 'TelegramAdapter requires a username.')

    @bot.threads << Thread.new do
      Telegram::Bot::Client.run(@token) do |bot|
        @bot_api = bot.api

        loop do
          begin
            bot.listen do |telegram_message|
              Concurrent::Future.execute do
                begin
                  receive(telegram_message)
                rescue => e
                  @bot.logger.error('TelegramAdapter') { "#{e} #{e.backtrace_locations[0]}" }
                end
              end
            end
          rescue Telegram::Bot::Exceptions::ResponseError => e
            @bot.logger.error('TelegramAdapter') { "#{e}" }
          rescue Faraday::ConnectionFailed => e
            @bot.logger.error('TelegramAdapter') { "#{e}" }
            sleep 1
          end
        end
      end
      puts 'The code here should never be executed. (Inside TelegramAdapter)'
    end
  end


  def receive(telegram_message)

    # Drop the message if it's from long time ago.
    message_time = Time.at(telegram_message.date)
    if Time.now - message_time > 120
      @bot.logger.debug('TelegramConnection') { "Dropped message from long time ago: #{telegram_message}" }
      return
    end

    # Find the group the message belongs to.
    target_group = nil
    @bot.groups.each do |group|
      next unless connection = group.connections[HoroBot2::Connections::TelegramConnection::CONFIG_SECTION]
      next unless connection.group_id == telegram_message.chat.id
      target_group = group
      break
    end

    if target_group
      if command? telegram_message
        command = HoroBot2::Command.new(
          name: /^\/(\w+)/.match(telegram_message.text)[1],
          arg: /^\/\w+(?:@\w+)? ?(.*)$/.match(telegram_message.text)[1],
          sender: telegram_message.from.username || telegram_message.from.first_name
        )
        Concurrent::Future.execute do
          begin
            target_group.command(command)
          rescue => e
            @bot.logger.error("Group #{target_group}") { "#{e} #{e.backtrace_locations[0]}" }
          end
        end
      else
        message = HoroBot2::IncomingMessage.new(
          time: message_time,
          author: telegram_message.from.username || telegram_message.from.first_name,
          text: telegram_message.text || telegram_message.caption,
          image: telegram_message.sticker || (telegram_message.photo.any? ? true : false),
          reply_to_me: reply_to_me?(telegram_message),
          group: target_group
        )
        begin
          target_group.receive(message)
        rescue => e
          @bot.logger.error("Group '#{target_group}'") { "#{e} #{e.backtrace_locations[0]}" }
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
    return false unless telegram_message.text =~ %r[^(?:/\w+@#{@username}|/\w+(?!@))(?: |$)]
    return true
  end

  private :command?


  def reply_to_me?(telegram_message)
    return false unless telegram_message.reply_to_message
    telegram_message.reply_to_message.from.username == @username
  end

  private :reply_to_me?


  def to_hash
    {
      token: @token,
      username: @username
    }
  end

  alias_method :to_h, :to_hash

end
