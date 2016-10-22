##
# An Emoji represents an Emoji defined in Unicode tr51.

class HoroBot2::Emoji < String

  module EmojiRegex

    ranges = '(?:' + [
      "[\u{1f300}-\u{1f3fa}]",
      "[\u{1f400}-\u{1f64f}]",
      "[\u{1f680}-\u{1f6ff}]",
      "[\u{1f900}-\u{1f9ff}]"
    ].join('|') + ')'

    modifier = "[\u{1f3fb}-\u{1f3ff}]"

    flags = "(?:[\u{1f1e6}-\u{1f1ff}])"

    joiner = "\u200d"

    modifier_sequence = "#{ranges}(?:#{modifier})?"

    zwj_sequence = "(?:#{modifier_sequence}#{joiner})*#{modifier_sequence}"

    final = [
      flags,
      zwj_sequence
    ].join('|')

    ONE = Regexp.new("^(?:#{final})$")
    MANY = Regexp.new(final)
    SEQUENCE = Regexp.new("^(?:#{final})+$")
    SEQUENCES = Regexp.new("(?:#{final})+")
    SEQUENCE_OF_SAME = Regexp.new("^(#{final})\\1*$")

  end

  def initialize(*args)
    raise(HoroBot2::EmojiError, "汝不想被刷屏吧？") if args[0].length > 64
    raise(HoroBot2::EmojiError, "咱不觉得 '#{args[0]}' 是个 Emoji 。") unless args[0] =~ EmojiRegex::SEQUENCE
    super(*args)
  end

  def valid?
    self =~ EmojiRegex::SEQUENCE
  end

  def single?
    self =~ EmojiRegex::ONE
  end

  def sequence_of_same?
    self =~ EmojiRegex::SEQUENCE_OF_SAME
  end

  def to_single_emoji
    if single?
      self
    else
      EmojiRegex::MANY.match(self)[0]
    end
  end

end
