require 'pp'
require 'yaml'
require 'logger'

##
# The Bootstrap module provides essential methods for bootstrapping HoroBot2.

module HoroBot2::Bootstrap

  def initialize(cli_options)
    @logger = Logger.new(STDOUT)
    @logger.debug "Command line parameters are: #{cli_options}"
    @logger.info 'Starting HoroBot2...'
  end

end
