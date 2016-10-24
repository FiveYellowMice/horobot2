require 'thin'
require 'cgi'
require 'erb'

##
# A WebInterface provides an interface accessible via HTTP.

class HoroBot2::WebInterface

  attr_reader :bot, :server, :address, :port, :baseurl


  def initialize(bot, web_interface_config)
    @bot = bot

    @address = web_interface_config[:address] || raise(ArgumentError, 'No address specified for WebInterface.')
    @port = web_interface_config[:port] || raise(ArgumentError, 'No port specified for WebInterface.')
    @baseurl = web_interface_config[:baseurl] || 'https://horobot.ml'

    # Prepare ERB templates.
    @templates = {}
    %w( status_all status_group ).each do |t_name|
      @templates[t_name] = ERB.new(File.read(File.expand_path("../web_interface/#{t_name}.html.erb", __FILE__)))
    end
  end


  ##
  # Start Rack server.

  def start
    @bot.threads << Thread.new do
      Thin::Logging.silent = true
      @server = Thin::Server.new(@address, @port, self, signals: false)
      at_exit do
        @server.stop!
      end
      @server.start
    end
  end


  ##
  # Everything starts with an HTTP request.

  def call(rack_env)
    begin
      request_method = rack_env['REQUEST_METHOD']
      request_path = rack_env['PATH_INFO']
      @bot.logger.debug('WebInterface') { "#{request_method} #{request_path}" }

      unless ['GET', 'HEAD'].include? request_method
        return [405, { 'Content-Type': 'text/plain; charset=utf-8' }, ["Method #{request_method} is not allowed for this resource.\n"]]
      end

      case request_path
      when '', '/'
        [302, { 'Location': "#{@baseurl}/status" }, []]
      when '/status', '/status/'
        status_all(rack_env)
      when /^\/status\/.+/
        status_group(rack_env)
      else
        [404, { 'Content-Type': 'text/plain; charset=utf-8' }, ["Not found.\n"]]
      end
    rescue => e
      @bot.logger.error('WebInterface') { "#{e} #{e.backtrace_locations[0]}" }
      [500, { 'Content-Type': 'text/plain; charset=utf-8' }, ["Error:\n#{e}\n"]]
    end
  end


  def to_hash
    {
      address: @address,
      port: @port,
      baseurl: @baseurl
    }
  end

  alias_method :to_h, :to_hash


  module Operations

    private


    def status_all(rack_env)
      b = binding
      b.local_variable_set :data, { groups: @bot.groups }
      [200, { 'Content-Type': 'text/html; charset=utf-8' }, [@templates['status_all'].result(b)]]
    end


    def status_group(rack_env)
      group_name = CGI.unescape(/^\/status\/(.+?)(?:\/|$)/.match(rack_env['PATH_INFO'])[1])
      group = nil
      @bot.groups.each do |g|
        if g.name == group_name
          group = g
          break
        end
      end
      unless group
        return [404, { 'Content-Type': 'text/plain; charset="utf-8"' }, ["Not found.\n"]]
      end

      b = binding
      b.local_variable_set :data, { group: group }
      [200, { 'Content-Type': 'text/html; charset=utf-8' }, [@templates['status_group'].result(b)]]
    end


  end

  include Operations
  include ERB::Util


end
