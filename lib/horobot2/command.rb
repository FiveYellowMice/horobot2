##
# A Command represents a command sent by a user.

class HoroBot2::Command

  attr_accessor :name, :arg, :sender


  def initialize(options = {})
    @name = options[:name] || raise(ArgumentError, 'Command must have a name.')
    @arg = options[:arg] || ''
    @sender = options[:sender]
  end


  def to_s
    if !@arg.empty?
      "/#{@name} #{@arg}"
    else
      "/#{@name}"
    end
  end

end
