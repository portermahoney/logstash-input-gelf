require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/gelf"
require "gelf"

describe "inputs/gelf" do

  it "reads chunked gelf messages " do
    port = 12209
    host = "127.0.0.1"
    chunksize = 1420
    gelfclient = GELF::Notifier.new(host, port, chunksize)

    conf = <<-CONFIG
      input {
        gelf {
          port => "#{port}"
          host => "#{host}"
        }
      }
    CONFIG

    large_random = 2000.times.map{32 + rand(126 - 32)}.join("")

    messages = [
      "hello",
      "world",
      large_random,
      "we survived gelf!"
    ]

    events = input(conf) do |pipeline, queue|
      # send a first message until plugin is up and receives it
      while queue.size <= 0
        gelfclient.notify!("short_message" => "prime")
        sleep(0.1)
      end
      gelfclient.notify!("short_message" => "start")

      e = queue.pop
      while (e["message"] != "start")
        e = queue.pop
      end

      messages.each do |m|
  	    gelfclient.notify!("short_message" => m)
      end

      messages.map{queue.pop}
    end

    events.each_with_index do |e, i|
      insist { e["message"] } == messages[i]
    end
  end
end
