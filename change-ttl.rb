#!/usr/bin/env ruby

#
# Original Author: Hideki Okamoto (hokamoto@akamai.com)
#
# For more information visit https://developer.akamai.com
#
# == License
#
#   Copyright (C) 2014 Hideki Okamoto
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'bundler'
Bundler.require

require 'net/http'
require 'uri'
require 'pp'
require 'optparse'

Version = '1.0'
SUPPORTED_RECORD_TYPE = %w|A AAAA AFSDB CNAME LOC MX NS PTR SOA SPF SRV TXT|

# Parse options
params = {}
opt = OptionParser.new
opt.on('-z ZONE', 'Zone name to change TTL (ex. example.com)') { |v| params[:zone] = v }
opt.on('-t TTL', 'TTL to be set') { |v|
  abort 'TTL should be an integer' if v != v.to_i.to_s || v.to_i < 0
  params[:ttl] = v.to_i
}
opt.on('-r RECORD_TYPE', 'Comma separated record types (Do not include space around commas)') { |v| params[:record_type] = v }
opt.on('-d CONSUMER_DOMAIN', 'Base URL will be https://[CONSUMER_DOMAIN].luna.akamaiapis.net') { |v| params[:consumer_domain] = v }
opt.on('-c CLIENT_TOKEN', 'Client Token') { |v| params[:client_token] = v }
opt.on('-s CLIENT_SECRET', 'Client Secret') { |v| params[:client_secret] = v }
opt.on('-a ACCESS_TOKEN', 'Access Token') { |v| params[:access_token] = v }
opt.on('-g', 'Change the records actually') { params[:go] = true }

begin
  opt.parse!(ARGV)
rescue OptionParser::InvalidOption => e
  puts "#{e.args.join(',')} is not a valid option."
  exit
end

# Check if mandatory arguments are set
if [params[:zone], params[:ttl], params[:consumer_domain], params[:client_token], params[:client_secret], params[:access_token], params[:record_type]].any? { |v| v.nil? }
  puts opt.help
  exit
end
affected_record_type = params[:record_type].split(',').map { |v| v.upcase }.uniq

# Initialize Edgegrid object
baseuri = URI("https://#{params[:consumer_domain]}.luna.akamaiapis.net/")

http = Akamai::Edgegrid::HTTP.new(
    address = baseuri.host,
    post = baseuri.port
)

http.setup_edgegrid(
    :client_token => params[:client_token],
    :client_secret => params[:client_secret],
    :access_token => params[:access_token],
    :max_body => 1024 * 128 # Max body size is 128k
)

request = Net::HTTP::Get.new URI.join(baseuri.to_s, "/config-dns/v1/zones/#{params[:zone]}").to_s
response = http.request(request)

zone_info = Oj.load(response.body)

if response.code.to_i != 200
  case response.code.to_i
    when 401
      abort 'Token or secret is incorrect.'
    when 403
      abort "You cannot manage the zone #{params[:zone]}."
    else
      pp Oj.load(response.body)
  end
end

# Increment serial of SOA record
zone_info['zone'].each do |key, value|
  if key.upcase == 'SOA'
    puts "Serial of SOA: \e[31m#{value['serial']}\e[0m => \e[32m#{value['serial'] + 1}\e[0m"
    puts '=' * 80
    value['serial'] += 1
  end
end

# Show differences
change_count = 0
zone_info['zone'].each do |key, value|
  value = [value] unless value.class == Array

  if affected_record_type.include?(key.upcase) && value.length > 0
    value.each do |records|
      if key.upcase == 'SOA'
        puts "#{key.upcase}\t#{records['originserver']}\t#{params[:zone]}\t\e[31m#{records['ttl']}\e[0m\t\e[32m#{params[:ttl]}\e[0m"
      else
        separator = records['name'] != nil && records['name'].length < 8 ? "\t\t" : "\t"
        puts "#{key.upcase}\t#{records['name']}#{separator}#{records['target']}\t\t\e[31m#{records['ttl']}\e[0m\t\e[32m#{params[:ttl]}\e[0m"
      end

      records['ttl'] = params[:ttl] if params[:go]
      change_count += 1
    end
  end
end
puts '=' * 80

# Update TTL
if params[:go]
  request = Net::HTTP::Post.new URI.join(baseuri.to_s, "/config-dns/v1/zones/#{params[:zone]}").to_s
  request.content_type = 'application/json'
  request.body = Oj.dump(zone_info, :mode => :compat)

  response = http.request(request)

  if response.code.to_i == 204
    puts "#{change_count} records have been updated."
  else
    pp Oj.load(response.body)
    abort 'failed'
  end
else
  puts "#{change_count} records will be affected, but these TTL have not been updated yet. Please set -g option to change the TTL actually."
end

# Show unsupported record type
affected_record_type.each do |i|
  unless SUPPORTED_RECORD_TYPE.include?(i.upcase)
    puts "Record type #{i.upcase} is not supported."
  end
end