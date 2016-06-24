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

https = Net::HTTP.new(@host_name, 443)
https.use_ssl = true
https.verify_mode = OpenSSL::SSL::VERIFY_PEER

response = nil

1_000.times do |i|
  temp = `./temper`
  temp.chomp!
  volt = `/opt/vc/bin/vcgencmd measure_volts core`
  volt = volt.split("=").last.to_f
  mem  = `ps -o rss= -p #{Process.pid}`.to_i
  cpu_temp = `cat /sys/class/thermal/thermal_zone0/temp`
  cpu_temp.chomp!
  payload = {Count: i, Temp: temp, Volt: volt, Mem: mem, CpuTemp: cpu_temp, Platform: "CRuby"}.to_json
  puts payload

  request.body = payload.to_json

  https.start {
    response = https.request(request)
  }

  puts "送信エラー #{response.inspect}" unless response.is_a?(Net::HTTPSuccess)

  sleep(1)
end
