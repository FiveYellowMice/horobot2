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

    server = @group.bot.adapters[HoroBot2::Adapters::IRCAdapter::CONFIG_SECTION].servers[@server]
    raise ArgumentError, "Server '#{@server}' does not exist." unless server

    # Wait for IRCServer to connect before join.
    Concurrent::Future.execute do
      until server.framework_started do sleep 0.5 end
      @channel = server.framework.join(@channel_name)
    end
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
