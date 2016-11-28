##
# An IncomingMessage represents a generic message received by HoroBot2.

class HoroBot2::IncomingMessage
  attr_accessor :time, :author, :text, :image, :reply_to_me, :group


  def initialize(options = {})
    @time = options[:time] || Time.now
    @author = options[:author]
    @text = options[:text]
    @image = options[:image]
    @reply_to_me = options[:reply_to_me]
    @group = options[:group]
  end


  def to_s(level = :simple)
    if level == :detail
      "[#{@author}] #{@image ? '<Image> ' : ''}#{@text}"
    else
      @text || ''
    end.gsub("\n", ' ')
  end
end
