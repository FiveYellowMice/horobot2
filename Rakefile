task :stop_remote do
  sh 'ssh -t potato1 sudo systemctl stop horobot'
end

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

task :push_config do
  raise('config.yaml does not exist.') unless File.exist?('config.yaml')

  temp_id = ('a'..'z').to_a.shuffle[0,8].join

  sh "scp config.yaml potato1:/tmp/config.yaml.#{temp_id}"
  sh "ssh -t potato1 sudo -u labrat cp /tmp/config.yaml.#{temp_id} /var/lib/labrat/horobot2/config.yaml"
  sh "ssh potato1 rm /tmp/config.yaml.#{temp_id}"
end
