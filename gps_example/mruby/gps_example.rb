sp = SerialPort.new("/dev/ttyUSB0", 4800, 8, 1, 0)
sp.read_timeout = 1000

loop do
  line = sp.readline
  if line =~ /^\$GPGGA/
    puts line
  end
end

sp.close
