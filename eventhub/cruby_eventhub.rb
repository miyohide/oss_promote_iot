require "time"
require "uri"
require "openssl"
require "base64"
require "json"
require "net/http"

NameSpace  = ENV['EVENTHUB_NAME_SPACE']
HubName    = ENV['EVENTHUB_HUB_NAME']
DeviceName = ENV['EVENTHUB_DEVICE_NAME']

KeyName  = ENV['EVENTHUB_KEY_NAME']
KeyValue = ENV['EVENTHUB_KEY_VALUE']

uri = URI.parse("https://#{NameSpace}.servicebus.windows.net:443/#{HubName}/publishers/#{DeviceName}/messages")

def encodeURIComponent(str)
  URI.escape(str, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

def sas_token(uri, key_name, key_value)
  expiry = Time.now.to_i + 60*10
  string_to_sign = "#{encodeURIComponent(uri)}\n#{expiry}"
  hamac = OpenSSL::HMAC.new(key_value, "sha256")
  hamac.update(string_to_sign)
  signature = Base64.strict_encode64(hamac.digest)
  "SharedAccessSignature sr=#{encodeURIComponent(uri)}&sig=#{encodeURIComponent(signature)}&se=#{expiry}&skn=#{key_name}"
end

srand(Time.now.to_i)

authorization_value = sas_token(uri.to_s, KeyName, KeyValue)

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

1.times do |i|
  puts "#{i+1}回目" if i % 100 == 0
  now_time = Time.now.instance_eval { '%s.%03d' % [strftime('%Y/%m/%d %H:%M:%S'), (usec / 1000.0).round]}
  payload = {DateAndTime: now_time, Temp: Random.rand(30.0).round(2), Humidity: Random.rand(70.0).round(2)}.to_json

  request = Net::HTTP::Post.new(uri.request_uri,
    {"Content-Type" => "application/json",
    "Content-Length" => payload.length.to_s,
    "Authorization"  => authorization_value}
  )

  request.body = payload

  http.start do |h|
    response = h.request(request)
    puts response.inspect
  end
end
