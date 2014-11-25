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

100.times do
  client = Coolio::TCPSocket.connect("127.0.0.1", 2929)
  client.on_connect do
    client.write("message\n")
  end
  client.on_connect_failed do
    p :failed
  end
  client.on_read do |data|
    n_processes += 1
    client.write("message\n")
  end
  client.attach(loop)
end
loop.run
