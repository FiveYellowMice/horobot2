##
# An IncomingMessage represents a generic message received by HoroBot2.

class HoroBot2::IncomingMessage
  attr_accessor :time, :author, :text, :image, :group


  def initialize(options = {})
    @time = options[:time] || Time.now
    @author = options[:author]
    @text = options[:text]
    @image = options[:image]
    @group = options[:group]
  end


  def to_s(level = :simple)
    if level == :detail
      "[#{@author}] #{@image ? '<Image> ' : ''}#{@text && @text.gsub("\n", ' ')}"
    else
      @text || ''
    end
  end
end
