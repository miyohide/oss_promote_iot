require 'rubygems'
require 'serialport'

SerialPort.open('/dev/ttyUSB0', 4800, 8, 1, SerialPort::NONE) { |sp|
  loop do
    begin
      line = sp.readline
      if line =~ /^\$GPGGA/
        columns = line.split(",")
        puts "time = #{columns[1]}, ido = #{columns[2]}, keido = #{columns[4]}"
        break
      end
    rescue ArgumentError
      # 連続して起動するとArgumentErrorが起きるのでとりあえず再処理させる
    end
  end
}

