def __main__(argv)
  if argv[1] == "version"
    puts "v#{RunInfo::VERSION}"
  else
    RunInfo::EventSender.new.send_message
  end
end
