#!/usr/bin/env ruby

require_relative 'the-red-button'


servers = {
    #staging: [
    #   {host: "server1", directory: "/var/www/site/shared", uri: "http://example.com"},
    #   {host: "server2", directory: "/var/www/site/shared", uri: "http://example.com"} 
    # ],
    #production: [
    #  {host: "server1", directory: "/var/www/site/shared", uri: "http://example.com"},
    # {host: "server2", directory: "/var/www/site/shared", uri: "http://example.com"} 
    #]
}

if ARGV.size < 2 || !servers.keys.include?(ARGV.first.to_sym) || !["up", "down"].include?(ARGV.last.downcase)
  puts "USAGE: maintenance.rb <#{servers.keys.join " | "}> <up | down> \n"
  puts "'down' puts the server in maintenance mode, 'up' puts it in normal mode.\n"
else
  button = RedButton.new(servers[ARGV.first.to_sym])
  button.turn_on if ARGV.last.downcase == 'down'
  button.turn_off if ARGV.last.downcase == 'up'
end
