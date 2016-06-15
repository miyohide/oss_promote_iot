module Homeinfo
  DEVICE_NAME = ENV["DEVICE_NAME"]
  SHARED_ACCESS_KEY = ENV["SHARED_ACCESS_KEY"]
  HOST_NAME = ENV["HOST_NAME"]
  REQUEST_PATH = "devices/#{DEVICE_NAME}/messages/events?api-version=2015-08-15-preview"

  URI_WITH_PORT = "https://#{HOST_NAME}:443/#{REQUEST_PATH}"

  class SendEvent
    def sas_token
      expiry = Time.now.to_i  + 60 * 60
      s = "#{HOST_NAME}/devices/#{DEVICE_NAME}"
      raw = Digest::HMAC.digest("#{s}\n#{expiry}",
                                Base64.decode(SHARED_ACCESS_KEY),
                                Digest::SHA256)
      signature = HTTP::URL::encode(Base64.encode(raw).strip)
      format("SharedAccessSignature sig=%s&se=%s&sr=%s",
              signature, expiry, "#{HOST_NAME}/devices/#{DEVICE_NAME}")
    end

    def message
      temp = `./temper`
      temp.chomp!
      volt = `/opt/vc/bin/vcgencmd measure_volts core`
      volt = volt.split("=").last.to_f.to_s
      mem  = `ps -o rss= -p #{Process.pid}`.to_i.to_s
      cpu_temp = `cat /sys/class/thermal/thermal_zone0/temp`
      cpu_temp.chomp!

      JSON::stringify(
        {DateAndTime: Time.now.strftime("%Y/%m/%d %H:%M:%S.%L"),
          Temp: temp, Volt: volt, Mem: mem, CpuTemp: cpu_temp})
    end

    def send_message(http)
      payload = message
      response = http.post(URI_WITH_PORT, payload,
        {
          "Content-Type" => "application/json",
          "Content-Length" => payload.length.to_s,
          "Authorization" => sas_token
        }
      )
      puts response
    end

    def send_messages(number)
      http = HttpRequest.new
      number.times do
        send_message(http)
      end
    end
  end
end
