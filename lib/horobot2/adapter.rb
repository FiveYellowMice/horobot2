##
# An Adapter provides a generic interface of a specific social network.

class HoroBot2::Adapter

  attr_reader :bot


  ##
  # Initialize the adapter, start listening.

  def initialize(bot, config)
    @bot = bot
  end

end
