##
# An OutgoingMessage represents a generic message going to be or already sent by HoroBot2.

class HoroBot2::OutgoingMessage
  attr_accessor :time, :text, :image, :group
end
