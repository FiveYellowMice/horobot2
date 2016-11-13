require 'concurrent'
require 'active_support'
require 'active_support/core_ext/object/blank'

##
# IRCConnection is the connection for IRCAdapter.

class HoroBot2::Connections::IRCConnection

  attr_reader :server, :channel_name, :ignored_users

  CONFIG_SECTION = :irc


  def initialize(group, connection_config)
    @group = group

    @server = connection_config[:server] || raise(ArgumentError, 'No server is given to IRCConnection.')
    @channel_name = connection_config[:channel_name] || raise(ArgumentError, 'No channel name is given to IRCConnection.')
    @ignored_users = connection_config[:ignored_users] || []

    adapter_server = @group.bot.adapters[HoroBot2::Adapters::IRCAdapter::CONFIG_SECTION].servers[@server]
    raise ArgumentError, "Server '#{@server}' does not exist." unless adapter_server

    # Join channel after the server has connected.
    # If it's already connected, join right now.
    # Otherwise add a proc that does the same thing to a list that will be called successively by IRCAdapter when the server is connected.
    Concurrent::Future.execute do
      if adapter_server.server_connected
        connect
      else
        adapter_server.server_connect_callbacks << proc do
          connect
        end
      end
    end
  end


  ##
  # Join the IRC channel. Should be called after the server has connected.
  def connect
    adapter_server = @group.bot.adapters[HoroBot2::Adapters::IRCAdapter::CONFIG_SECTION].servers[@server]
    @channel = adapter_server.framework.join(@channel_name)
  end


  ##
  # Respond to a command.

  def command(command)
    case command.name
    when 'irc_show_ignored_users'
      @group.send_text @ignored_users.any? ? "咱忽略了 #{@ignored_users.join(', ')} 。" : "咱没有忽略任何人呐。"
    when 'irc_add_ignored_user'
      raise(HoroBot2::HoroError, "汝要让咱忽略谁呢？") if command.arg.blank?
      raise(HoroBot2::HoroError, "咱已经不再理会 #{command.arg} 了呐。") if @ignored_users.include? command.arg
      @ignored_users << command.arg
      @group.send_text "咱不会再理会 #{command.arg} 了。"
      @group.bot.save_changes
    when 'irc_rem_ignored_user'
      raise(HoroBot2::HoroError, "咱还在意着 #{command.arg} 呐。") unless @ignored_users.include? command.arg
      @ignored_users.delete command.arg
      @group.send_text "咱会珍惜与 #{command.arg} 在一起的时光的。"
      @group.bot.save_changes
    else
      @group.bot.logger.debug("IRCConnection '#{@group}'") { "Unknown command '#{command.name}'." }
    end
  end


  ##
  # Send a message.

  def send_message(message)
    if @channel
      @group.bot.logger.debug("IRCConnection '#{@group}'") { "Sending: #{message}" }
      text = message.text ? message.text.gsub("\n", '  ') : ''
      if message.image
        text = message.image + ' ' + text
      end
      @channel.send(text)
    else
      @group.bot.logger.debug("IRCConnection '#{@group}'") { "Because channel not connected, message not sent: #{message}" }
    end
  end


  def to_hash
    {
      server: @server,
      channel_name: @channel_name,
      ignored_users: @ignored_users
    }
  end

  alias_method :to_h, :to_hash

end
