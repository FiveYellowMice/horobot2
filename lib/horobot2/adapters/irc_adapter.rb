require 'cinch'
require 'concurrent'

##
# IRCAdapter is the Adapter for communicating with IRC channels.

class HoroBot2::Adapters::IRCAdapter < HoroBot2::Adapter

  attr_reader :servers

  CONFIG_SECTION = :irc


  def initialize(bot, adapter_config)
    super(bot, adapter_config)

    @servers = {}
    adapter_config[:servers].each do |server_name, server_config|
      @servers[server_name] = IRCServer.new(bot, server_config)
    end
  end


  def to_hash
    {
      servers: @servers.map {|key, value| [key, value.to_h]}.to_h
    }
  end

  alias_method :to_h, :to_hash


  ##
  # IRCServer represents an IRC server.

  class IRCServer

    attr_reader :address, :port, :nick, :framework, :server_connected
    attr_accessor :server_connect_callbacks


    def initialize(bot, server_config)
      @bot = bot

      @address = server_config[:address] || raise(ArgumentError, 'IRCServer must have an address.')
      @port = server_config[:port] || raise(ArgumentError, 'IRCServer must have a port.')
      @nick = server_config[:nick] || raise(ArgumentError, 'IRCServer must have a nick.')
      @password = server_config[:password] || raise(ArgumentError, 'IRCServer must have a password.')

      @framework = Cinch::Bot.new do
        configure do |c|
          c.server = server_config[:address]
          c.port = server_config[:port]
          c.ssl = Cinch::Configuration::SSL.new(use: true)
          c.nick = server_config[:nick]
          c.password = server_config[:password]
          c.sasl = Cinch::Configuration::SASL.new(
            username: server_config[:nick],
            password: server_config[:password]
          )
          c.channels = []
        end
      end

      # Replace the logger of Cinch with a self-created one.
      # Which logs everything Cinch produces to HoroBot2's logger.
      logger_rep = LoggerListReplacement.new
      logger_rep.real_logger = @bot.logger
      @framework.loggers = logger_rep

      # A workaround for scoping issue about yielding
      # that does not allow calling methods in the scope the block locates instead of where yield locates.
      channel_message_handler = proc do |irc_message|
        begin
          receive irc_message
        rescue => e
          bot.logger.error('IRCAdapter') { "#{e} #{e.backtrace_locations[0]}" }
        end
      end
      @framework.on :channel do |irc_message|
        channel_message_handler.call irc_message
      end

      # Indicate whether the server is connected or not.
      # When it's connected, call every procs given by IRCConnection s.
      @server_connected = false
      @server_connect_callbacks = []
      connect_event_handler = proc do
        @server_connected = true
        @server_connect_callbacks.shift.call while @server_connect_callbacks.any?
      end
      @framework.on :connect do
        connect_event_handler.call
      end

      @bot.threads << Thread.new do
        @framework.start
      end

      at_exit do
        begin
          @framework.quit
        rescue
        end
      end
    end


    def receive(irc_message)

      # Find the group the message belongs to.
      target_group = nil
      @bot.groups.each do |group|
        next unless connection = group.connections[HoroBot2::Connections::IRCConnection::CONFIG_SECTION]
        next unless connection.channel_name == irc_message.channel.name
        target_group = group
        break
      end

      if target_group
        if target_group.connections[HoroBot2::Connections::IRCConnection::CONFIG_SECTION].ignored_users.include? irc_message.user.nick
          @bot.logger.debug("IRCConnection '#{target_group}'") { "Ignored message from #{irc_message.user.nick}" }
        else
          if command? irc_message
            command = HoroBot2::Command.new(
              name: %r[^(?:horo|#{@nick}: ?)/(\w+)]i.match(irc_message.message)[1],
              arg: %r[^(?:horo|#{@nick}: ?)/\w+(?: (.*)$)?]i.match(irc_message.message)[1],
              sender: irc_message.user.nick
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
              time: irc_message.time,
              author: irc_message.user.nick,
              text: irc_message.message,
              reply_to_me: reply_to_me?(irc_message),
              group: target_group
            )
            begin
              target_group.receive(message)
            rescue => e
              @bot.logger.error("Group '#{target_group}'") { "#{e} #{e.backtrace_locations[0]}" }
            end
          end
        end
      else
        @bot.logger.debug('IRCAdapter') { "Message: #{irc_message}" }
        @bot.logger.warn('IRCAdapter') { "Message from unknown group: #{irc_message.channel}" }
      end
    end

    private :receive


    def command?(irc_message)
      return false unless irc_message.message
      return false unless irc_message.message =~ %r[^(?:horo|#{@nick}: ?)/\w+]i
      return true
    end

    private :command?


    def reply_to_me?(irc_message)
      irc_message.message =~ /(?:^\[\w+\] ?)?#{@nick}:/
    end

    private :reply_to_me?


    def to_hash
      {
        address: @address,
        port: @port,
        nick: @nick,
        password: @password
      }
    end

    alias_method :to_h, :to_hash

  end


  class LoggerListReplacement < Cinch::LoggerList

    attr_accessor :real_logger

    def debug(message)
    end

    def error(message)
      @real_logger.warn('IRCAdapter') { message.to_s }
    end

    def exception(e)
      @real_logger.warn('IRCAdapter') { e.to_s }
    end

    def fatal(message)
      @real_logger.fatal('IRCAdapter') { message.to_s }
    end

    def info(message)
      @real_logger.debug('IRCAdapter') { message.to_s }
    end

    alias_method :incoming, :info
    alias_method :log, :info
    alias_method :outgoing, :info
    alias_method :warn, :info

  end

end
