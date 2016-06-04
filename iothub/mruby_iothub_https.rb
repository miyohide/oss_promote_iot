DEVICE_NAME = ENV["DEVICE_NAME"]
SHARED_ACCESS_KEY = ENV["SHARED_ACCESS_KEY"]
HOST_NAME = ENV["HOST_NAME"]
REQUEST_PATH = "devices/#{DEVICE_NAME}/messages/events?api-version=2015-08-15-preview"

uri_with_port = "https://#{HOST_NAME}:443/#{REQUEST_PATH}"

expiry = Time.now.to_i  + 600
s = "#{HOST_NAME}/devices/#{DEVICE_NAME}"
raw = Digest::HMAC.digest("#{s}\n#{expiry}",
                          Base64.decode(SHARED_ACCESS_KEY),
                          Digest::SHA256)
signature = HTTP::URL::encode(Base64.encode(raw).strip)
sas_header = format("SharedAccessSignature sig=%s&se=%s&sr=%s",
                    signature,
                    expiry,
                    "#{HOST_NAME}/devices/#{DEVICE_NAME}")
srand(Time.now.to_i)

http = HttpRequest.new
payload = JSON::stringify(
            {DateAndTime: Time.now.strftime("%Y/%m/%d %H:%M:%S.%L"),
              Temp: Random::rand(30) + Random::rand,
              Humidity: Random::rand(70) + Random::rand})

response = http.post(uri_with_port, payload, {
  "Content-Type" => "application/json",
  "Content-Length" => payload.length.to_s,
  "Authorization" => sas_header
  })

puts response.inspect
