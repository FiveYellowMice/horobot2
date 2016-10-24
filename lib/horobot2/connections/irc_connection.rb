require 'concurrent'

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
  # Send a message.

  def send_message(message)
    @group.bot.logger.debug("IRCConnection '#{@group}'") { "Sending: #{message}" }

    @channel.send(message.text.gsub("\n", '  '))
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
