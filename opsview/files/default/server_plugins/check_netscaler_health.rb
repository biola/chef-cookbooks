#!/opt/chef/embedded/bin/ruby
require 'json'
require 'optparse'
require 'rest_client'

# Parse command line options
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: check_netscaler_health.rb [options]"

  opts.on("-H", "--host HOSTNAME", "The hostname or IP address of the NetScaler appliance") do |h|
    options[:host] = h
  end

  opts.on("-m", "--mode VALUE", "The mode of the plugin", "Available options: cpuusage, memusage, hastate") do |m|
    options[:mode] = m
  end

  opts.on("-u", "--username VALUE", "The username to use for authentication") do |u|
    options[:username] = u
  end

  opts.on("-p", "--password VALUE", "The password to use for authentication") do |p|
    options[:password] = p
  end

  options[:warning] = 75
  opts.on("-w", "--warning VALUE", Integer, "Warning threshold for CPU or memory usage (default 75)") do |w|
    options[:warning] = w
  end

  options[:critical] = 90
  opts.on("-c", "--critical VALUE", Integer, "Critical threshold for CPU or memory usage (default 90)") do |c|
    options[:critical] = c
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end

begin
  optparse.parse!
  mandatory = [:host, :mode, :username, :password]
  missing = mandatory.select{ |param| options[param].nil? }
  if not missing.empty?
    puts "Missing options: #{missing.join(', ')}"
    puts optparse
    exit
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end

login_payload = {
  "login" => {
    "username" => options[:username],
    "password" => options[:password]
  }
}

# Log in and get an authentication token
login = RestClient.post "https://#{options[:host]}/nitro/v1/config/login/", login_payload.to_json, :content_type => 'application/vnd.com.citrix.netscaler.login+json', :accept => :json

# Check health against thresholds
is_critical = false
is_warning = false
output = String.new

case options[:mode]
when "cpuusage"
  system_health = JSON.parse(RestClient.get "https://#{options[:host]}/nitro/v1/stat/systemcpu", :accept => :json, :cookies => { "NITRO_AUTH_TOKEN" => login.cookies["NITRO_AUTH_TOKEN"] })
  system_health["systemcpu"].each do |cpu|
    if cpu["percpuuse"].to_i > options[:critical]
      is_critical = true
    elsif cpu["percpuuse"].to_i > options[:warning]
      is_warning = true
    end
    output << "CPU#{cpu["id"]} usage: #{cpu["percpuuse"]}% "
  end
when "memusage"
  system_health = JSON.parse(RestClient.get "https://#{options[:host]}/nitro/v1/stat/systemmemory", :accept => :json, :cookies => { "NITRO_AUTH_TOKEN" => login.cookies["NITRO_AUTH_TOKEN"] })
  if system_health["systemmemory"]["memusagepcnt"].to_i > options[:critical]
    is_critical = true
  elsif system_health["systemmemory"]["memusagepcnt"].to_i > options[:warning]
    is_warning = true
  end
  output = "memory usage is #{system_health["systemmemory"]["memusagepcnt"].to_i}%"
when "hastate"
  system_health = JSON.parse(RestClient.get "https://#{options[:host]}/nitro/v1/stat/hanode", :accept => :json, :cookies => { "NITRO_AUTH_TOKEN" => login.cookies["NITRO_AUTH_TOKEN"] })
  if system_health["hanode"]["hacurstatus"] == "YES"
    if system_health["hanode"]["hacurstate"] != "UP"
      is_critical = true
    end
    output = "state is #{system_health["hanode"]["hacurmasterstate"]}; last transition was #{system_health["hanode"]["transtime"]}"
  else
    puts "High availability not configured on this node."
    exit
  end
else
  puts "Invalid mode selected."
  puts optparse
  exit
end

# Log out
RestClient.post "https://#{options[:host]}/nitro/v1/config/logout/", { "logout" => {} }.to_json, :content_type => 'application/vnd.com.citrix.netscaler.logout+json', :accept => :json, :cookies => { "NITRO_AUTH_TOKEN" => login.cookies["NITRO_AUTH_TOKEN"] }

# Return results
if is_critical
	puts "CRITICAL: #{output}"
	exit 2
elsif is_warning
  puts "WARNING: #{output}"
	exit 1
else
  puts "OK: #{output}"
	exit 0
end