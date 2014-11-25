#!/usr/bin/env ruby

require "coolio"
require "fiber"

class Fiber
  class << self
    def run(*arguments, &block)
      fiber = new(&block)
      fiber.resume(*arguments)
    end
  end
end

module Synchronizable
  class << self
    def extended(object)
      super
      object.init_sync
    end
  end

  def init_sync
    @buffer = []
    @read_fiber = nil
    @close_fiber = nil
  end

  def read
    if @buffer.empty?
      @read_fiber = Fiber.current
      Fiber.yield
    else
      @buffer.shift
    end
  end

  def on_read(data)
    @buffer << data
    if @read_fiber
      @read_fiber.resume(@buffer.shift)
    end
  end

  def close
    unless output_buffer_size.zero?
      @close_fiber = Fiber.current
      Fiber.yield
    end
    super
  end

  def on_write_complete
    @close_fiber.resume if @close_fiber
  end
end

n_processes = 0

loop = Coolio::Loop.default

throughput_reporter = Coolio::TimerWatcher.new(1, true)
throughput_reporter.on_timer do
  puts("#{n_processes}/s")
  n_processes = 0
end
throughput_reporter.attach(loop)

server = Coolio::TCPServer.new("127.0.0.1", 2929) do |client|
  Fiber.run do
    client.extend(Synchronizable)
    loop do
      data = client.read
      client.write(data)
      n_processes += 1
    end
  end
end
server.attach(loop)

loop.run
