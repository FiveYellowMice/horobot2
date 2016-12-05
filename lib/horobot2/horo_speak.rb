# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

##
# HoroSpeak generates random sentences from segments of sentences from a library.
# The library should be a concatenated file of all subtitles of Spice and Wolf.

class HoroBot2::HoroSpeak


  attr_reader :bot


  def initialize(bot, horo_speak_config = {})
    @bot = bot
    @library_filename = horo_speak_config[:library_filename] || raise(ArgumentError, 'No library is given to HoroSpeak.')

    library_actual_path = File.expand_path(@library_filename, File.expand_path('../../..', __FILE__))

    @sentences = File.readlines(library_actual_path).reduce([]) do |memo, line|
      stripped = line.strip
      if stripped.empty?
        memo
      else
        memo << stripped
      end
    end
  end


  def generate_sentence(request)
    answer_buffer = String.new
    if request.blank?
      request = @fallback_request || ''
    end
    get_answer(request) do |segment|
      answer_buffer << segment
    end
    @fallback_request = answer_buffer
    return answer_buffer
  end


  def to_hash
    {
      library_filename: @library_filename
    }
  end

  alias_method :to_h, :to_hash


  private


  def get_answer(request, avoided_index = nil, last_segment = '', recursion_level = 0)
    selected_sentence_index = nil

    ([5, 6, 7, 8].sample(2) + [2, 3, 4].shuffle + [1, 0]).find do |last_char_count|
      [0, 1, 2].find do |skip_char_count|
        last_chars = request[
          [request.length - last_char_count - skip_char_count, 0].max...
          [request.length                   - skip_char_count, 0].max
        ]

        if last_chars.length == last_char_count
          random_indices.find do |sentence_index|
            sentence = @sentences[sentence_index]
            if sentence_index + 1 != avoided_index && (sentence[-10..-1] || sentence).include?(last_chars)
              selected_sentence_index = sentence_index
            end
          end
        end
      end
    end

    return unless selected_sentence_index

    answer = last_segment
    answer_slice_index = 0
    times_looped = 0

    while answer.length < 32 && times_looped < 20
      @bot.logger.debug('HoroSpeak') { "Start while loop for #{times_looped} time, answer: #{answer}" }
      selected_sentence = @sentences[selected_sentence_index]
      last_chars = ''

      new_sentence_found =
      ([3, 4, 5].shuffle + [2]).find do |last_char_count|
        last_chars = selected_sentence[answer_slice_index, last_char_count]
        next if last_chars.empty?
        if
          answer.empty? ||
          last_chars.length == last_char_count ||
          selected_sentence[0...answer_slice_index].end_with?(answer + last_chars)
        then
          random_indices.find do |sentence_index|
            if
              sentence_index != selected_sentence_index ||
              selected_sentence.length < answer_slice_index + last_chars.length + 3
            then
              sentence = @sentences[sentence_index]
              sentence_last_chars_index = sentence.index(last_chars)
              if sentence_last_chars_index
                answer += last_chars
                selected_sentence_index = sentence_index
                selected_sentence = @sentences[selected_sentence_index]
                answer_slice_index = sentence_last_chars_index + last_chars.length
                yield last_chars
                true
              end
            end
          end
        end
      end

      if !new_sentence_found
        if answer.empty?
          selected_sentence_index = (selected_sentence_index + 1) % @sentences.length
          selected_sentence = @sentences[selected_sentence_index]
          answer_slice_index = 0
        elsif
          recursion_level < 20 && (
            @sentences.include?(answer + last_chars) ||
            selected_sentence[0...answer_slice_index].end_with?(answer)
          )
        then
          answer += last_chars
          yield last_chars
          if ['。', '，', '！', '？', '…', '—', '：', '；', ',', '.', '?', '!', '-', ':', ';'].include?(answer[-1])
            last_segment = answer + ' '
            yield ' '
          else
            last_segment = answer
          end
          @bot.logger.debug('HoroSpeak') { "Enter recursion level #{recursion_level + 1}, answer: #{answer}" }
          get_answer(last_chars, selected_sentence_index, last_segment, recursion_level + 1) do |segment|
            yield segment
          end
          @bot.logger.debug('HoroSpeak') { "Exit recursion level #{recursion_level + 1}, answer: #{answer}" }
          return
        else
          yield last_chars
          return
        end
      end

      times_looped += 1
    end
  end


  def random_indices(max_number = 200)
    sentence_indices = (0...@sentences.length).to_a
    if max_number == 0
      sentence_indices.shuffle
    else
      sentence_indices.sample(max_number)
    end
  end


end
