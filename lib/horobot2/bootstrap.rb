require 'optparse'
require 'yaml'
require 'logger'
require 'thwait'

##
# The Bootstrap module provides essential methods for bootstrapping HoroBot2.

module HoroBot2::Bootstrap

  def initialize(cli_options)
    @threads = []
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

    HoroBot2::Adapters.constants.each do |adapter_name|
      adapter = HoroBot2::Adapters.const_get(adapter_name)
      adapter.new(self, config)
      @logger.debug "Loaded adapter #{adapter_name}."
    end

    ThreadsWait.all_waits(*@threads)
  end

end
