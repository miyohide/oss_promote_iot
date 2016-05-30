require 'openssl'
require 'cgi'
require 'base64'
require 'time'
require 'net/https'
require 'json'

CONNECTION_STRING = ENV['CONNECTION_STRING']

CONNECTION_STRING.split(";").each do |elm|
  key = elm[0, elm.index("=")].gsub(/([A-Z])/, "_\\1").gsub(/^_/, '').downcase
  self.instance_variable_set("@#{key}".to_sym, elm[(elm.index('=') + 1), elm.length])
end

expiry = Time.now.to_i + 60 * 10

raw = OpenSSL::HMAC.digest(
  "sha256",
  Base64.strict_decode64(@shared_access_key), "#{@host_name}/devices/#{@device_id}\n#{expiry}".encode(Encoding::UTF_8)
)

signature = CGI.escape(Base64.encode64(raw).strip)

sas_header = format(
  "SharedAccessSignature sig=%s&se=%s&sr=%s",
  signature,
  expiry,
  "#{@host_name}/devices/#{@device_id}"
)

request = Net::HTTP::Post.new(
  "https://#{@host_name}/devices/#{@device_id}/messages/events?api-version=2015-08-15-preview",
  {
    "Content-Type" => "application/json",
    "Authorization" => sas_header
  }
)

srand(Time.now.to_i)

1.times do
  now_time = Time.now.instance_eval { '%s.%03d' % [strftime('%Y/%m/%d %H:%M:%S'), (usec / 1000.0).round]}
  payload = {DateAndTime: now_time, Temp: Random.rand(30.0).round(2), Humidity: Random.rand(70.0).round(2)}.to_json

  request.body = payload.to_json

  response = nil
  https = Net::HTTP.new(@host_name, 443)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_PEER

  https.start {
    response = https.request(request)
  }

  p response
end
