DEVICE_NAME = ENV["DEVICE_NAME"]
SHARED_ACCESS_KEY = ENV["SHARED_ACCESS_KEY"]
HOST_NAME = ENV["HOST_NAME"]
REQUEST_PATH = "devices/#{DEVICE_NAME}/messages/events?api-version=2015-08-15-preview"

uri_with_port = "https://#{HOST_NAME}:443/#{REQUEST_PATH}"

expiry = Time.now.to_i  + 60 * 60
s = "#{HOST_NAME}/devices/#{DEVICE_NAME}"
raw = Digest::HMAC.digest("#{s}\n#{expiry}",
                          Base64.decode(SHARED_ACCESS_KEY),
                          Digest::SHA256)
signature = HTTP::URL::encode(Base64.encode(raw).strip)
sas_header = format("SharedAccessSignature sig=%s&se=%s&sr=%s",
                    signature,
                    expiry,
                    "#{HOST_NAME}/devices/#{DEVICE_NAME}")

http = HttpRequest.new
temp = `./temper`
temp.chomp!
volt = `/opt/vc/bin/vcgencmd measure_volts core`
volt = volt.split("=").last.to_f
mem  = `ps -o rss= -p #{Process.pid}`.to_i
cpu_temp = `cat /sys/class/thermal/thermal_zone0/temp`
cpu_temp.chomp!

payload = JSON::stringify(
  {DateAndTime: Time.now.strftime("%Y/%m/%d %H:%M:%S.%L"),
    Temp: temp,
    Volt: volt,
    Mem: mem,
    CpuTemp: cpu_temp,
    Platform: "mruby"})
puts payload
response = http.post(uri_with_port, payload, {
    "Content-Type" => "application/json",
    "Content-Length" => payload.length.to_s,
    "Authorization" => sas_header
})

puts "送信エラー #{response.code}" unless response.code == 204
Sleep::sleep(1)
