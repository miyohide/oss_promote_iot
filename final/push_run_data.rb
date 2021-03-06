DEVICE_NAME = ENV["DEVICE_NAME"]
SHARED_ACCESS_KEY = ENV["SHARED_ACCESS_KEY"]
HOST_NAME = ENV["HOST_NAME"]
REQUEST_PATH = "devices/#{DEVICE_NAME}/messages/events?api-version=2015-08-15-preview"

def temp
  `./temper`.chomp
end

def cpu_volt
  `/opt/vc/bin/vcgencmd measure_volts core`.split("=").last.to_f
end

def use_memory_size
  `ps -o rss= -p #{Process.pid}`.to_i
end

def cpu_temp
  `cat /sys/class/thermal/thermal_zone0/temp`.chomp!
end

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

sp = SerialPort.new("/dev/ttyUSB0", 4800, 8, 1, 0)
sp.read_timeout = 1000
gps_data = ""
loop do
  gps_data = sp.readline
  if gps_data =~ /^\$GPGGA/
    break
  end
end
sp.close

gps_columns = gps_data.split(",")

http = HttpRequest.new

payload = JSON::stringify(
  {DateAndTime: Time.now("%Y/%m/%d %H:%M:%S"),
    Temp: temp,
    Volt: cpu_volt,
    Mem: use_memory_size,
    CpuTemp: cpu_temp,
    ido: gps_columns[2],
    keido: gps_columns[4],
    Platform: "mruby"})
puts payload
response = http.post(uri_with_port, payload, {
    "Content-Type" => "application/json",
    "Content-Length" => payload.length.to_s,
    "Authorization" => sas_header
})

puts "送信エラー #{response.code}" unless response.code == 204
