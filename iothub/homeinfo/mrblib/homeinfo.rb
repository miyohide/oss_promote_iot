def __main__(argv)
  if argv[1] == "version"
    puts "v#{Homeinfo::VERSION}"
  else
    Homeinfo::SendEvent.new.send_messages(1_000)
  end
end
