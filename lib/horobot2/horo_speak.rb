# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

##
# HoroSpeak generates random sentences from segments of sentences from a library.
# The library should be a concatenated file of all subtitles of Spice and Wolf.

class HoroBot2::HoroSpeak


  attr_reader :bot


  SLICES_OF_SENTENCE_TOPIC = [
    0..1,
    0..2,
    1..2,
    1..3,
    2..3,
    2..4,
    3..4,
    3..5,
    -2..-1,
    -3..-1,
    -3..-2,
    -4..-2,
    -4..-3,
    -5..-3,
    -5..-4,
    -6..-4,
  ]


  def initialize(bot, horo_speak_config = {})
    @bot = bot
    @library_filename = horo_speak_config[:library_filename] || raise(ArgumentError, 'No library is given to HoroSpeak.')
    library_actual_path = File.expand_path(@library_filename, File.expand_path('../../..', __FILE__))
    @library_sample_size = horo_speak_config[:library_sample_size] || 512

    @library = File.readlines(library_actual_path).map do |line|
      line.strip.freeze
    end.select do |line|
      !line.blank?
    end.freeze
  end


  ##
  # Generate a sentence.

  def generate(input = '')
    input = input.strip

    result = []

    # First segment
    head_source = library[seek_reply]
    head_length = rand(2..6)
    result << head_source[0...head_length]
    debug_log { "Result add: #{result[-1]}" }
    return result.join if head_length >= head_source.length

    # Body segments
    segment_count_goal = rand(2..5)
    last_connected = ConnectedSentence.new('', result[-1])
    debug_log { "Segment count goal: #{segment_count_goal}" }
    while result.length + 1 < segment_count_goal
      connected_sentence = seek_connected(result[-1], last_segment_from_index: last_connected.source_index)
      last_connected = connected_sentence
      segment_length = rand(2..6)
      result << connected_sentence.value[0...segment_length]
      debug_log { "Result add: #{result[-1]}" }
      return result.join if segment_length >= connected_sentence.length
    end

    # Tail segment (if any)
    result << seek_connected(result[-1], last_segment_from_index: last_connected.source_index).value
    debug_log { "Result add: #{result[-1]}" }
    return result.join
  end

  alias_method :generate_sentence, :generate


  def to_hash
    {
      library_filename: @library_filename,
      library_sample_size: @library_sample_size
    }
  end

  alias_method :to_h, :to_hash


  private


  ##
  # @return [ConnectedSentence]

  def seek_connected(input = '', options = {})
    last_segment_from_index = options[:last_segment_from_index]

    input = input.strip

    if input.blank?
      return library[get_random_indices(1)[0]]
    end

    selected = get_random_indices.reduce([]) do |candidates, i|
      next(candidates) if i == last_segment_from_index

      trying_sentence = library[i][input.length..-1] || ''
      next(candidates) if trying_sentence.blank?

      max_matching =
      (1..trying_sentence.length).to_a.reverse.find do |matching_chars_count|
        input.end_with? trying_sentence[0...matching_chars_count]
      end || 0

      if max_matching > 0 && max_matching != trying_sentence.length
        new_candidate = ConnectedSentence.new(
          trying_sentence[0...max_matching],
          trying_sentence[max_matching..-1],
          i
        )
        candidates + [new_candidate]
      else
        candidates
      end
    end.max_by {|x| x.max_matching - x.length / 4.0 }

    if selected
      debug_log { "Found connected sentence: #{selected.match} | #{selected.value}" }
      return selected
    end

    fallback_selected_index = get_random_indices.find do |i|
      library[i].length > input.length
    end

    if fallback_selected_index
      fallback_sentence = library[fallback_selected_index][input.length, rand(4..10)]
      debug_log { "Fallback to: (#{fallback_selected_index}) #{fallback_sentence}" }
      ConnectedSentence.new('', ' ' + fallback_sentence, fallback_selected_index)
    else
      ConnectedSentence.new('', '')
    end
  end


  ##
  # @return [Integer]

  def seek_reply(input = '')
    input = input.strip

    # Returns the next 1 or 2 sentence.
    offset =
    if rand(3) < 2 # 2/3 prob
      0
    else
      rand(1..2)
    end

    (seek_related(input) + offset) % library.length
  end


  ##
  # @return [Integer]

  def seek_related(input = '')
    input = input.strip

    if !input.blank?

      # Extract possible topics from input.
      input_topic_candidates = SLICES_OF_SENTENCE_TOPIC.map do |slice|
        input[slice]
      end.select do |topic|
        !topic.nil? && !topic.blank?
      end.uniq

      debug_log { "Possible topic of input: #{input_topic_candidates}" }

      # Find the sentence with the most occurrences of possible topics.
      selected = get_random_indices.reduce([0, nil]) do |last_counted, i|

        # Sum of all occurrences of all possible topics.
        occurrences = input_topic_candidates.reduce(0) do |sum, topic|
          sum + library[i].split(topic, -1).length - 1
        end

        if occurrences > last_counted[0]
          debug_log { "Sentence has #{occurrences} of topics: (#{i}) #{library[i]}" }
          [occurrences, i]
        else
          last_counted
        end

      end[1] || get_random_indices(1)[0]

    else

      # Just get a random sentence if can't find one with above rules.
      selected = get_random_indices(1)[0]

    end

    debug_log { "Selected: (#{selected}) #{library[selected]}" }

    return selected
  end


  ##
  # @return [Integer]

  def get_random_indices(max = @library_sample_size)
    library_indices = (0...library.length).to_a

    if max < 0
      raise ArgumentError, 'Can not get negative number of sentences from library.'
    end

    if max < library.length && max > 0
      library_indices.sample(max)
    else
      library_indices.shuffle
    end
  end


  def library
    @library
  end


  def debug_log(&block)
    @bot.logger.debug('HoroSpeak', &block)
  end


  ConnectedSentence = Struct.new(:match, :value, :source_index)

  class ConnectedSentence

    def max_matching
      match.length
    end

    def length
      value.length
    end

  end


end
