# Ruby tor scraper
This Ruby script use tor to scrap over the web.

See [Scraptory](https://github.com/AlexMili/Scraptory) for a more advance version.

## Requirements
- nokogiri
- typhoeus
- [useragents](https://github.com/debbbbie/useragents-rb)

You must have installed and configured Tor to use it in the script. Telnet must be enabled, the ports and telnet password can be changed in `settings.cfg`.

## Usage

```ruby
ruby scraper.rb my/yaml/config/file.cfg
```

## How does it works
This script reads a file containing all new urls to fetch. The file has the following format :
```
----------- File's header -----------
http://www.example.com/page1
http://www.example.com/page2
http://www.example.com/page3
http://www.example.com/page4
http://www.example.com/page5
```

It handles :
- Parallel requests
- Retries after failure
- Timeout, 404 http error and 301/302 http errors

Every requests are made through Tor. When 10 requests fails non-continuously (can be changed), a message is sent to Tor via Telnet asking it to renew its IP. During that time, failing requests will be automatically re-added to the queue.
