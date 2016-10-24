require 'yaml'
require 'concurrent'

##
# The SaveChanges module provides methods for saving runtime changes to disk.

module HoroBot2::SaveChanges

  ##
  # Lazily save changes.
  # The actual saving actions are done after the delay of 10 seconds, in the mean time, further calls will be ignored.

  def save_changes
    if !@change_save_scheduled
      @change_save_scheduled = true
      @logger.debug("Runtime change saving is scheduled.")
      Concurrent::ScheduledTask.execute(10) do
        begin
          save_changes!
          @logger.debug("Runtime change saved.")
          @change_save_scheduled = false
        rescue => e
          @logger.error("Error saving runtime changes: #{e} #{e.backtrace_locations[0]}")
        end
      end
    end
  end


  ##
  # Save runtime changes immediately.
  # Should not be called casually.

  def save_changes!
    new_config = YAML.dump self.to_hash
    File.write @config_file_name, new_config
  end


  ##
  # Convert the bot itself into a hash containing all the configurations.

  def to_hash
    {
      adapters: @adapters.map {|key, value| [key, value.to_h] }.to_h,
      web_interface: @web_interface.to_h,
      groups: @groups.map(&:to_h)
    }
  end

  alias_method :to_h, :to_hash

end
