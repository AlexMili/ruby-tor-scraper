# encoding: UTF-8

# For Http requests
require 'typhoeus'
require 'useragents'
# For Tor
require 'net/telnet'

def build_request(url)
	Typhoeus::Config.user_agent = UserAgents.rand()

	if $config['general']['use_tor']
		return Typhoeus::Request.new(url, timeout: $config['general']['timeout'], proxy: $config['tor']['host']+":"+$config['tor']['port'].to_s, :proxytype => "socks4")
	else
		return Typhoeus::Request.new(url, timeout: $config['general']['timeout'])
	end
end

def change_tor_ip()
	puts "Requesting new IP..."
	localhost = Net::Telnet::new("Host" => $config['tor']['host'], "Port" => $config['tor']['telnet_port'].to_s, "Timeout" => $config['general']['timeout'], "Prompt" => /250 OK\n/)
	localhost.cmd('AUTHENTICATE "'+$config['tor']['telnet_pwd']+'"') { |c| print c; throw "Cannot authenticate to Tor" if c != "250 OK\n" }
	localhost.cmd('signal NEWNYM') { |c| print c; throw "Cannot switch Tor to new route" if c != "250 OK\n" }
	localhost.close
end

def get_ip()
	response = build_request("http://checkip.amazonaws.com/").run

	return response.response_body.gsub("\n", '').strip
end

def ip_changed(original_ip)
	response = build_request("http://checkip.amazonaws.com/").run

	if response.response_body != original_ip
		return true
	else
		return false
	end
end


