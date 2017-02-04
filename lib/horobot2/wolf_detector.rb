# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'

##
# WolfDetector detects if a user is a wolf.

class HoroBot2::WolfDetector


  attr_reader :bot


  DIVINE_CHARACTOR = "\u{1f60b}" # :yum:


  def initialize(bot, detector_config = {})
    @bot = bot
    @min_trait_appearances = detector_config[:min_trait_appearances] || 3

    @user_appearances_hash = {} # { String => WolfTraitAppearences }
  end


  ##
  # This method is called when received a message.

  def receive(message)
    if message.author && message.text && message.text.include?(DIVINE_CHARACTOR)
      tas = @user_appearances_hash[message.author] ||= WolfTraitAppearences.new(message.author)
      tas.add
      @bot.logger.debug('WolfDetector') { "'#{message.author}' now has #{tas.length} wolf trait appearances." }
    end
  end


  ##
  # Get if a user is wolf.

  def user_is_wolf?(user)
    if @user_appearances_hash[user]
      @user_appearances_hash[user].length >= @min_trait_appearances
    else
      false
    end
  end


  ##
  # Get a list of all wolves.

  def all_wolves
    @user_appearances_hash.keys.select do |user|
      user_is_wolf? user
    end
  end


  def to_hash
    {
      min_trait_appearances: @min_trait_appearances
    }
  end

  alias_method :to_h, :to_hash


  ##
  # WolfTraitAppearences represents number of wolf trait appeared
  # within certain time period on a single user.

  class WolfTraitAppearences


    attr_reader :user


    def initialize(user)
      @user = user || raise(ArgumentError, 'User not given for WolfTraitAppearences.')
      @appearances = []
    end


    def add
      @appearances << Appearance.new(Time.now)
    end


    def length
      @appearances.delete_if do |ap|
        Time.now - ap.time > 1.days.to_i
      end
      @appearances.length
    end


    Appearance = Struct.new(:time)


  end


end
