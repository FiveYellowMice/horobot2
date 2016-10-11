##
# An IncomingMessage represents a generic message received by HoroBot2.

class HoroBot2::IncomingMessage
  attr_accessor :time, :author, :text, :image, :group
end
