require 'optparse'
require 'yaml'
require 'json'
require 'logger'
require 'thwait'
require 'concurrent'

##
# The Bootstrap module provides essential methods for bootstrapping HoroBot2.

module HoroBot2::Bootstrap

  def initialize(cli_options)
    @threads = []
    @groups = []
    @adapters = {}

    STDOUT.sync = true
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::Severity::INFO

    @options = {
      config_file: 'config.yaml',
      data_dir: 'var',
      dev_mode: false
    }
    OptionParser.new do |opts|
      opts.banner = 'Usage: horobot [options]'

      opts.on('-c', '--config FILE', 'Use a config file other than config.yaml.') do |arg|
        @options[:config_file] = arg.to_s
      end

      opts.on('-d', '--dir DIRECTORY', 'Use a data directory other than var.') do |arg|
        @options[:data_dir] = arg.to_s
      end

      opts.on('-D', '--dev [LEVEL]', 'Turn on development mode, and set log level.') do |arg|
        @options[:dev_mode] = true
        level = arg ? arg.upcase.to_sym : :DEBUG
        @logger.level = Logger::Severity.const_get(level)
      end

      opts.on('-h', '--help', 'Show this help message.') do
        puts opts
        exit
      end
    end.parse!

    @logger.debug "Command line parameters are: #{cli_options}"
  end


  def start
    @logger.info 'Starting HoroBot2...'

    # Read config file.
    @config_file_name = @options[:config_file]
    config = YAML.load File.read @config_file_name

    # Ensure data directory exists.
    @data_dir = @options[:data_dir]
    if File.exists? @data_dir
      unless File.directory?(@data_dir) && File.writable?(@data_dir)
        raise 'Can not write to data directory.'
      end
    else
      @logger.debug 'Data directory not exist, trying to create.'
      Dir.mkdir(@data_dir)
    end

    @dev_mode = @options[:dev_mode]

    @options = nil

    # Load persistent chatlog Emoji.
    persistent_emojis = if File.exists? File.expand_path 'chatlog_emojis.json', @data_dir
      JSON.load File.read File.expand_path 'chatlog_emojis.json', @data_dir
    else
      {}
    end

    # Start all adapters.
    HoroBot2::Adapters.constants.each do |adapter_name|
      adapter = HoroBot2::Adapters.const_get(adapter_name)
      @adapters[adapter::CONFIG_SECTION] = adapter.new(self, config[:adapters][adapter::CONFIG_SECTION])
      @logger.debug "Loaded adapter #{adapter_name}."
    end

    # Prepare all groups.
    config[:groups].each do |group_config|
      @groups << HoroBot2::Group.new(self, group_config, { chatlog_emojis: persistent_emojis[group_config[:name]] })
      @logger.debug "Loaded group '#{group_config[:name]}'."
    end

    # Prepare persistent chatlog Emoji.
    at_exit do
      persistent_emojis = @groups.map do |group|
        [group.name, group.chatlog_emojis]
      end.to_h
      File.write(File.expand_path('chatlog_emojis.json', @data_dir), JSON.dump(persistent_emojis))
    end

    # Cool down groups per minute.
    Concurrent::TimerTask.execute(execution_interval: 60) do
      @groups.each do |group|
        begin
          group.cool_down
        rescue => e
          @logger.error("Group '#{group}'") { "#{e} #{e.backtrace_locations[0]}" }
        end
      end
    end

    # Initialize WebInterface.
    @web_interface = HoroBot2::WebInterface.new(self, config[:web_interface])
    @web_interface.start

    #@threads.each do |t| t.abort_on_exception = true end
    Thread.abort_on_exception = true
    ThreadsWait.all_waits(*@threads)
    puts 'The code here should not be executed. (Inside Bootstrap)'
  end

end
