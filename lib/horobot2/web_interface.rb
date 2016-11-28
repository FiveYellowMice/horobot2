require 'thin'
require 'json'
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
    @password = web_interface_config[:password] || raise(ArgumentError, 'No port specified for WebInterface.')

    # Prepare ERB templates.
    unless @bot.dev_mode
      @templates = {}
      %w( status_all status_group control_page ).each do |t_name|
        @templates[t_name] = ERB.new(File.read(File.expand_path("../web_interface/#{t_name}.html.erb", __FILE__)))
      end
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

      case request_path
      when '', '/'
        raise MethodNotAllowed unless ['GET', 'HEAD'].include? request_method
        [302, { 'Location': "#{@baseurl}/status" }, []]
      when '/status', '/status/'
        status_all(rack_env)
      when /^\/status\/.+/
        status_group(rack_env)
      when '/control'
        case request_method
        when 'GET'
          control_page(rack_env)
        when 'POST'
          exec_control(rack_env)
        else
          raise MethodNotAllowed
        end
      else
        [404, { 'Content-Type': 'text/plain; charset=utf-8' }, ["Not found.\n"]]
      end
    rescue MethodNotAllowed => e
      [405, { 'Content-Type': 'text/plain; charset=utf-8' }, ["Method #{request_method} is not allowed for this resource.\n"]]
    rescue => e
      @bot.logger.error('WebInterface') { "#{e} #{e.backtrace_locations[0]}" }
      [500, { 'Content-Type': 'text/plain; charset=utf-8' }, ["Error:\n#{e}\n"]]
    end
  end


  ##
  # Render a ERB template.

  def render_template(name, data = {})
    b = binding
    data.each do |k, v|
      b.local_variable_set k, v
    end

    template = unless @bot.dev_mode
      @templates[name]
    else
      ERB.new(File.read(File.expand_path("../web_interface/#{name}.html.erb", __FILE__)))
    end

    template.result(b)
  end

  private :render_template


  def to_hash
    {
      address: @address,
      port: @port,
      baseurl: @baseurl,
      password: @password
    }
  end

  alias_method :to_h, :to_hash


  class MethodNotAllowed < StandardError
  end


  class AuthenticationFailed < StandardError
  end


  module Operations

    private


    def status_all(rack_env)
      raise MethodNotAllowed unless ['GET', 'HEAD'].include? rack_env['REQUEST_METHOD']
      [200, { 'Content-Type': 'text/html; charset=utf-8' }, [render_template('status_all', groups: @bot.groups)]]
    end


    def status_group(rack_env)
      raise MethodNotAllowed unless ['GET', 'HEAD'].include? rack_env['REQUEST_METHOD']

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

      [200, { 'Content-Type': 'text/html; charset=utf-8' }, [render_template('status_group', group: group)]]
    end


    def control_page(rack_env)
      [200, { 'Content-Type': 'text/html; charset=utf-8' }, [render_template('control_page', groups: @bot.groups)]]
    end


    def exec_control(rack_env)
      begin
        instruction = JSON.parse(rack_env['rack.input'].read)
        raise AuthenticationFailed unless instruction['password'] == @password
        case instruction['method']
        when 'send_message'
          target_group = @bot.groups.find{|g| g.name == instruction['group_name'] }
          raise "Group '#{instruction['group_name']}' is not found." unless target_group && instruction['text']
          target_group.send_text instruction['text']
          [200, { 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-cache' }, [JSON.generate(ok: true)]]
        when 'set_horo_speak_on_reply'
          target_group = @bot.groups.find{|g| g.name == instruction['group_name'] }
          raise "Group '#{instruction['group_name']}' is not found." unless target_group
          if instruction['toggle'] == true
            target_group.horo_speak_on_reply = true
            @bot.save_changes
          elsif instruction['toggle'] == false
            target_group.horo_speak_on_reply = false
            @bot.save_changes
          end
          [200, { 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-cache' }, [JSON.generate(
            ok: true,
            horo_speak_on_reply: target_group.horo_speak_on_reply
          )]]
        else
          raise "Unknown method '#{instruction['method']}'."
        end
      rescue JSON::ParserError
        [400, { 'Content-Type': 'text/plain; charset=utf-8' }, ["Error parsing JSON.\n"]]
      rescue AuthenticationFailed
        [403, { 'Content-Type': 'application/json; charset=utf-8' }, [JSON.generate(
          ok: false,
          message: 'Authentication failed.'
        )]]
      rescue => e
        [400, { 'Content-Type': 'application/json; charset=utf-8' }, [JSON.generate(
          ok: false,
          err_class: e.class.to_s,
          message: e.message
        )]]
      end
    end


  end


  include Operations
  include ERB::Util


end
