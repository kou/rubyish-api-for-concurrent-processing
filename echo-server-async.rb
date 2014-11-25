#!/usr/bin/env ruby

require "coolio"

n_processes = 0

loop = Coolio::Loop.default

throughput_reporter = Coolio::TimerWatcher.new(1, true)
throughput_reporter.on_timer do
  puts("#{n_processes}/s")
  n_processes = 0
end
throughput_reporter.attach(loop)

server = Coolio::TCPServer.new("127.0.0.1", 2929) do |client|
  client.on_read do |data|
    client.write(data)
  end
  client.on_write_complete do
    n_processes += 1
  end
end
server.attach(loop)

loop.run
