task :stop_remote do
  sh 'ssh -t potato1 sudo systemctl stop horobot'
end

namespace :config do

  task :get do
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

  task :push do
    raise('config.yaml does not exist.') unless File.exist?('config.yaml')

    temp_id = ('a'..'z').to_a.shuffle[0,8].join

    sh "scp config.yaml potato1:/tmp/config.yaml.#{temp_id}"
    sh "ssh -t potato1 sudo -u labrat cp /tmp/config.yaml.#{temp_id} /var/lib/labrat/horobot2/config.yaml"
    sh "ssh potato1 rm /tmp/config.yaml.#{temp_id}"
  end

end

namespace :chatlog_emojis do

  task :get, [:baseurl] do |t, args|
    require 'json'
    require 'erb'
    require 'open-uri'
    require 'nokogiri'

    baseurl = args[:baseurl] || 'https://horobot.ml'

    groups = Nokogiri::HTML(open("#{baseurl}/status")).css('.group-list-item').map {|s| s.css('a').text }

    data = {}
    groups.each do |group|
      doc = Nokogiri::HTML(open("#{baseurl}/status/#{ERB::Util.u group}"))
      emojis = doc.css('.chatlog-emoji-list-item').map {|s| s.text }

      puts "#{group}: #{emojis.length}"

      data[group] = emojis
    end

    File.write('var/chatlog_emojis.json', JSON.dump(data))
  end
  
  task :push do
    raise('chatlog_emojis.json does not exist.') unless File.exist?('var/chatlog_emojis.json')
    
    temp_id = ('a'..'z').to_a.shuffle[0,8].join
    
    sh "scp var/chatlog_emojis.json potato1:/tmp/chatlog_emojis.json.#{temp_id}"
    sh "ssh -t potato1 sudo -u labrat cp /tmp/chatlog_emojis.json.#{temp_id} /var/lib/labrat/horobot2/var/chatlog_emojis.json"
    sh "ssh potato1 rm /tmp/chatlog_emojis.json.#{temp_id}"
  end

end
