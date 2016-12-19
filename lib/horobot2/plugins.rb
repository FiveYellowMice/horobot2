# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'

##
# The Plugins class provides an interface to add plugins to HoroBot2.
#
# It serves both as a plugin manager and a namespace for all plugin classes.
# Plugins are put under the 'plugins' directory under the data directory,
# written as Ruby classes under the namespace HoroBot2::Plugins. All classes
# directly under this namespace gets initialized and loaded as plugins during
# the bootstrap of HoroBot2, except Base, which provides a base for all plugins.
#
# All plugins need to inherit the HoroBot2::Plugins::Base class, it will set the
# 'bot' propery of the plugin to the instance of HoroBot2.
#
# Currently, the only functionality a plugin can provide is a custom behavior
# when the bot received a message. To do this, the plugin needs to have a method
# 'receive', it will get invoked with one argument of an instance of
# HoroBot2::IncomingMessage. If the plugin class has a constant
# RECEIVE_ONLY_WHEN_MATCH, it will be =~'ed before the 'receive' method gets
# invoked.

class HoroBot2::Plugins


  attr_reader :bot


  def initialize(bot)
    @bot = bot
    reload_plugins
  end


  ##
  # Reload all plugins.

  def reload_plugins
    @reloading = true

    @list = {}

    HoroBot2::Plugins.constants.each do |name|
      unless name == :Base
        HoroBot2::Plugins.send(:remove_const, name)
      end
    end

    plugins_dir = File.expand_path('plugins', @bot.data_dir)
    if File.directory? plugins_dir
      Dir.entries(plugins_dir).each do |filename|
        filepath = File.realpath(filename, plugins_dir)
        if File.file?(filepath) && filepath.end_with?('.rb')
          load filepath
        end
      end
    end

    HoroBot2::Plugins.constants.each do |name|
      unless name == :Base
        plugin_class = HoroBot2::Plugins.const_get(name)
        raise("Plugin #{name} does not inherit from #{Base}.") unless plugin_class < Base
        @list[name.to_s.underscore.to_sym] = plugin_class.new(@bot)
        @bot.logger.debug('Plugins') { "Loaded plugin #{name}." }
      end
    end

    @reloading = false
  end


  ##
  # Get instance of plugin by its underscored name.

  def [](name)
    return nil if @reloading
    @list[name] || @list[name.to_s.underscore.to_sym]
  end


  ##
  # Loop through each plugin.

  def each(&block)
    return nil if @reloading
    @list.each_value(&block)
  end


  class Base


    attr_reader :bot


    def initialize(bot)
      @bot = bot
    end


  end


end
