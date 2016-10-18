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

  end

  def initialize(*args)
    raise(HoroBot2::EmojiError, "咱不觉得 '#{args[0]}' 是个 Emoji 。") unless args[0] =~ EmojiRegex::ONE
    super(*args)
  end

end
