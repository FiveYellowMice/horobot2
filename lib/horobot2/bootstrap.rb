require 'optparse'
require 'yaml'
require 'logger'
require 'thwait'

##
# The Bootstrap module provides essential methods for bootstrapping HoroBot2.

module HoroBot2::Bootstrap

  def initialize(cli_options)
    @threads = []
    @groups = []
    @adapters = {}
    @logger = Logger.new(STDOUT)
    @logger.debug "Command line parameters are: #{cli_options}"

    @options = {
      config_file: 'config.yaml'
    }
    OptionParser.new do |opts|
      opts.banner = 'Usage: horobot [options]'

      opts.on('-c', '--config=FILE', 'Use a config file other than config.yaml.') do |arg|
        @options[:config_file] = arg.to_s
      end

      opts.on('-h', '--help', 'Show this help message.') do
        puts opts
        exit
      end
    end.parse!
  end


  def start
    @logger.info 'Starting HoroBot2...'

    config = YAML.load File.read @options[:config_file]
    @options = nil

    # Start all adapters
    HoroBot2::Adapters.constants.each do |adapter_name|
      adapter = HoroBot2::Adapters.const_get(adapter_name)
      @adapters[adapter::CONFIG_SECTION] = adapter.new(self, config[:adapters][adapter::CONFIG_SECTION])
      @logger.debug "Loaded adapter #{adapter_name}."
    end

    # Prepare all groups
    config[:groups].each do |group_config|
      @groups << HoroBot2::Group.new(self, group_config)
      @logger.debug "Loaded group '#{group_config[:name]}'."
    end

    @threads.each do |t| t.abort_on_exception = true end
    ThreadsWait.all_waits(*@threads)
    puts 'The code here should not be executed. (Inside Bootstrap)'
  end

end
