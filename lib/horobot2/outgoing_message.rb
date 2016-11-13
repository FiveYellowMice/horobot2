##
# An OutgoingMessage represents a generic message going to be or already sent by HoroBot2.

class HoroBot2::OutgoingMessage
  attr_accessor :time, :text, :image, :group


  def initialize(options = {})
    @time = options[:time] || Time.now
    @text = options[:text]
    @image = options[:image]
    @group = options[:group]
  end


  def to_s
    (@image ? "<Image #{@image}>" : '') + (@text || '').gsub("\n", ' ')
  end
end
