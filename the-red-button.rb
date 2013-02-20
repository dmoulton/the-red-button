# encoding: UTF-8
class HTTPError < StandardError; end
class MalformedTargetsError < StandardError; end
class SSHError < StandardError; end

require 'net/http'
require "curses"
include Curses

class RedButton
  attr_reader :targets

  def initialize(targets)
    @targets = targets

    raise MalformedTargetsError, "You have not configured any targets" if targets.size == 0
    raise MalformedTargetsError, "One or more of your targets is malformed (missing host, shared location, or URI)" unless targets_are_valid
  end

  def turn_on
    if confirmed?
      targets.each do |target|
        touch_maintenance_file(target[:host], target[:directory])
        check_uri(target[:uri])
      end
    else
      puts "Aborting..."
    end
  end

  def turn_off
    if confirmed?
      targets.each do |target|
        rm_maintenance_file(target[:host], target[:directory])
        check_uri_up(target[:uri])
      end
    else
      puts "Aborting..."
    end
  end

  private

  def check_uri(uri)
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.code == "503"
      puts "  #{ uri } is in maintenance mode."
    else
      raise HTTPError, "#{ uri } is not returning a 503 response code. Check the URI in your target list, and make sure that the maintenance Nginx configuration is installed correctly."
    end
  end

  def check_uri_up(uri)
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.code == "200"
      puts "  #{ uri } is up and running."
    else
      raise HTTPError, "#{ uri } is not returning a 200 response code. Check the URI in your target list, and make sure that the maintenance Nginx configuration is installed correctly."
    end
  end

  def targets_are_valid
    targets.all? do |target|
      target[:host] && target[:directory] && target[:uri]
    end
  end

  def confirmed?
    puts "Type 'yes' to continue and put the site in maintenance mode. Anything else will abort.\n"
    print "> "
    confirmation = STDIN.gets.chomp
    puts "\n"

    return true if confirmation == 'yes'

    false
  end

  def touch_maintenance_file(host, directory)
    puts "* Site on #{ host } in #{ directory } going into maintenance mode"
    successful = system "ssh #{ host } \'touch #{ directory }/maintenance-on\'"

    raise SSHError, "Error executing command on #{ host }. Please check the hostname and directory for any typos" unless successful
  end

  def rm_maintenance_file(host, directory)
    puts "* Site on #{ host } in #{ directory } coming back up"
    successful = system "ssh #{ host } \'rm #{ directory }/maintenance-on\'"

    raise SSHError, "Error executing command on #{ host }. Please check the hostname and directory for any typos" unless successful
  end

end
