task :get_config do
  require 'io/console'

  print 'Password: '
  password = STDIN.noecho(&:gets).chomp
  puts

  puts 'Reading config file from server...'
  cmd = IO.popen "echo '#{password}' | ssh potato1 sudo -S -u labrat cat /var/lib/labrat/horobot2/config.yaml 2>/dev/null"
  server_config = cmd.read

  puts 'Saving file...'
  `mv config.yaml config.yaml.bak`
  File.write 'config.yaml', server_config
end
