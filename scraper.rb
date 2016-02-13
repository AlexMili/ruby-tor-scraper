# encoding: UTF-8
require 'nokogiri'
require 'typhoeus'
# For file/dir manipulation
require 'fileutils'
# Config file
require 'yaml'
# Utils
require_relative 'utils'

if ARGV.length == 1
	$config = YAML::load_file(ARGV[0])

	if $config['scraper']['use_log']
		File.open($config['scraper']['log_file'], 'a') { |file| file.write("--------- New session on "+Time.new.inspect+" ---------\n") }
	end

	FileUtils::mkdir_p $config['scraper']['saving_dir']

	if $config['general']['parallel_mode']
		hydra = Typhoeus::Hydra.new(max_concurrency: $config['general']['max_concurrency'])
	else
		hydra = Typhoeus::Hydra.new(max_concurrency: 1)
	end

	nb_problems = 0

	if File.exist?($config['scraper']['new_entries_file'])
		File.readlines($config['scraper']['new_entries_file']).each do |line|
			url = line.gsub("\n", '')
			
			itemRequest = build_request(url)

			itemRequest.on_complete do |response|
				if response.success?
					puts "\n"+url
					puts "------------------------------------------------"
					
					filename = $config['scraper']['saving_dir']+url.gsub($config['general']['site'],'').gsub('/','-').gsub('.','_')+'.html'
					File.open(filename, 'w') { |file| file.write(response.response_body) }
				elsif response.timed_out?
					if $config['scraper']['use_log']
						File.open($config['scraper']['log_file'], 'a') { |file| file.write("Timed out ("+url+")\n") }
					end

					nb_problems = nb_problems + 1

					if $config['general']['use_tor'] and nb_problems > $config['tor']['errors_before_change_ip']
						change_tor_ip()
						nb_problems = 0
					end

					if $config['general']['retry_on_error']
						hydra.queue itemRequest
					end

				elsif response.code == 404
					if $config['scraper']['use_log']
						File.open($config['scraper']['log_file'], 'a') { |file| file.write("404 Page not found ("+url+")\n") }
					end
					puts "404 Page not found ("+$config['general']['site']+")"
				elsif response.code == 301 or response.code == 302
					if $config['scraper']['use_log']
						File.open($config['scraper']['log_file'], 'a') { |file| file.write("301/302 Redirection not followed ("+url+")\n") }
					end
				elsif response.code == 0
					# Could not get an http response, something's wrong.
					if $config['scraper']['use_log']
						File.open($config['scraper']['log_file'], 'a') { |file| file.write("Could not get an http response, something's wrong ("+url+") : "+response.return_message+"\n") }
					end

					nb_problems = nb_problems + 1

					if $config['general']['use_tor'] and nb_problems > $config['tor']['errors_before_change_ip']
						change_tor_ip()
						nb_problems = 0
					end

					if $config['general']['retry_on_error']
						hydra.queue itemRequest
					end

				else
					# Received a non-successful http response.
					if $config['scraper']['use_log']
						File.open($config['scraper']['log_file'], 'a') { |file| file.write("Received a non-successful http response ("+url+") : "+response.code.to_s+"\n") }
					end

					nb_problems = nb_problems + 1

					if $config['general']['use_tor'] and nb_problems > $config['tor']['errors_before_change_ip']
						change_tor_ip()
						nb_problems = 0
					end

					if $config['general']['retry_on_error']
						hydra.queue itemRequest
					end

				end
			end

			hydra.queue itemRequest
		end

		puts "Running... (With IP "+get_ip()+")"
		hydra.run
	else
		puts 'The new entries file doesn\'t exist !'

		if $config['scraper']['use_log']
			File.open($config['scraper']['log_file'], 'a') { |file| file.write("New entires file doesn't exist \n") }
		end
	end
else
	puts "Usage :\n\truby scraper.rb my/yaml/config/file.cfg"
end

