class HoroBot2

  autoload :Bootstrap, 'horobot2/bootstrap'
  autoload :SaveChanges, 'horobot2/save_changes'
  autoload :WebInterface, 'horobot2/web_interface'
  autoload :HoroSpeak, 'horobot2/horo_speak'
  autoload :WolfDetector, 'horobot2/wolf_detector'
  autoload :Plugins, 'horobot2/plugins'
  autoload :Group, 'horobot2/group'
  autoload :Adapter, 'horobot2/adapter'
  autoload :Adapters, 'horobot2/adapters'
  autoload :Connection, 'horobot2/connection'
  autoload :Connections, 'horobot2/connections'
  autoload :IncomingMessage, 'horobot2/incoming_message'
  autoload :OutgoingMessage, 'horobot2/outgoing_message'
  autoload :Command, 'horobot2/command'
  autoload :Emoji, 'horobot2/emoji'
  autoload :HoroError, 'horobot2/horo_error'
  autoload :EmojiError, 'horobot2/emoji_error'


  attr_reader :data_dir, :adapters, :logger, :dev_mode, :web_interface, :horo_speak, :wolf_detector, :plugins
  attr_accessor :groups, :threads

  include HoroBot2::Bootstrap
  include HoroBot2::SaveChanges

end
