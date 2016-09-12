module RunInfo
  DEVICE_NAME = ENV["DEVICE_NAME"]
  SHARED_ACCESS_KEY = ENV["SHARED_ACCESS_KEY"]
  HOST_NAME = ENV["HOST_NAME"]
  RUN_COUNT = ENV["RUN_COUNT"]
  REQUEST_PATH = "devices/#{DEVICE_NAME}/messages/events?api-version=2015-08-15-preview"

  URI_WITH_PORT = "https://#{HOST_NAME}:443/#{REQUEST_PATH}"

  class EventSender
    def temp
      `/opt/temper`.chomp
    end

    def cpu_volt
      `/opt/vc/bin/vcgencmd measure_volts core`.split("=").last.to_f
    end

    def use_memory_size
      `ps -o rss= -p #{Process.pid}`.to_i
    end

    def gps_data
      sp = SerialPort.new("/dev/ttyUSB0", 4800, 8, 1, 0)
      sp.read_timeout = 1000
      gps_line = ""
      loop do
        gps_line = sp.readline
        if gps_line =~ /^\$GPGGA/
          break
        end
      end
      sp.close

      gps_line.split(",")
    end

    def cpu_temp
      `cat /sys/class/thermal/thermal_zone0/temp`.chomp!
    end

    def generate_sas_token
      expiry = Time.now.to_i  + 60 * 60
      s = "#{HOST_NAME}/devices/#{DEVICE_NAME}"
      raw = Digest::HMAC.digest("#{s}\n#{expiry}",
                                Base64.decode(SHARED_ACCESS_KEY),
                                Digest::SHA256)
      signature = HTTP::URL::encode(Base64.encode(raw).strip)
      format("SharedAccessSignature sig=%s&se=%s&sr=%s",
              signature, expiry, "#{HOST_NAME}/devices/#{DEVICE_NAME}")
    end

    def create_message
      gps_columns = gps_data
      JSON::stringify(
        {DateAndTime: Time.now("%Y/%m/%d %H:%M:%S"),
          Temp: temp,
          Volt: cpu_volt,
          Mem: use_memory_size,
          CpuTemp: cpu_temp,
          ido: gps_columns[2],
          keido: gps_columns[4],
          run_count: RUN_COUNT
        }
      )
    end

    def send_message
      http = HttpRequest.new
      message = create_message
      File.open("/tmp/#{RUN_COUNT}.txt", "a") { |f| f.puts(message) }
      puts message
      http.post(URI_WITH_PORT, message,
        {
          "Content-Type" => "application/json",
          "Content-Length" => message.length.to_s,
          "Authorization" => generate_sas_token
        }
      )
    end
  end
end
