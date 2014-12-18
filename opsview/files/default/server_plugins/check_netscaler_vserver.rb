#!/opt/chef/embedded/bin/ruby
require 'json'
require 'optparse'
require 'rest_client'

# Parse command line options
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: check_netscaler_vserver.rb [options]"

  opts.on("-H", "--host HOSTNAME", "The hostname or IP address of the NetScaler appliance") do |h|
    options[:host] = h
  end

  opts.on("-v", "--vserver VALUE", "The name of the NetScaler virtual server") do |v|
    options[:vserver] = v
  end

  opts.on("-u", "--username VALUE", "The username to use for authentication") do |u|
    options[:username] = u
  end

  opts.on("-p", "--password VALUE", "The password to use for authentication") do |p|
    options[:password] = p
  end

  options[:warning] = 50
  opts.on("-w", "--warning VALUE", Integer, "Service availability to result in a warning state (default 50)") do |w|
    options[:warning] = w
  end

  options[:critical] = 0
  opts.on("-c", "--critical VALUE", Integer, "Service availability to result in a critical state (default 0)") do |c|
    options[:critical] = c
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end

begin
  optparse.parse!
  mandatory = [:host, :vserver, :username, :password]
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

# Get the vserver status
vserver_status = JSON.parse(RestClient.get "https://#{options[:host]}/nitro/v1/stat/lbvserver/#{options[:vserver]}", :content_type => 'application/vnd.com.citrix.netscaler.lbvserver+json', :accept => :json, :cookies => { "NITRO_AUTH_TOKEN" => login.cookies["NITRO_AUTH_TOKEN"] })

# Log out
RestClient.post "https://#{options[:host]}/nitro/v1/config/logout/", { "logout" => {} }.to_json, :content_type => 'application/vnd.com.citrix.netscaler.logout+json', :accept => :json, :cookies => { "NITRO_AUTH_TOKEN" => login.cookies["NITRO_AUTH_TOKEN"] }

# Return results
if vserver_status["lbvserver"][0]["vslbhealth"].to_i <= options[:critical]
	puts "CRITICAL: #{vserver_status["lbvserver"][0]["vslbhealth"]}% of service bindings are available"
	exit 2
elsif vserver_status["lbvserver"][0]["vslbhealth"].to_i <= options[:warning]
	puts "WARNING: #{vserver_status["lbvserver"][0]["vslbhealth"]}% of service bindings are available"
	exit 1
else
	puts "OK: #{vserver_status["lbvserver"][0]["vslbhealth"]}% of service bindings are available"
	exit 0
end