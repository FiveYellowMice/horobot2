class HoroBot2

  autoload :Bootstrap, 'horobot2/bootstrap'
  autoload :Group, 'horobot2/group'
  autoload :Adapter, 'horobot2/adapter'
  autoload :Connection, 'horobot2/connection'
  autoload :IncomingMessage, 'horobot2/incoming_message'
  autoload :OutgoingMessage, 'horobot2/outgoing_message'


  attr_reader :adapters, :logger
  attr_accessor :groups

  include HoroBot2::Bootstrap

end
