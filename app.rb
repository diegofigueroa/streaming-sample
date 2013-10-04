require 'rubygems'

require 'thin'
require 'bundler/setup'
require 'faye/websocket'

require 'redis'
require 'redis/connection/synchrony'

require 'json'

Faye::WebSocket.load_adapter 'thin'

streams = []
subscriptions = {}

EM.next_tick do
   EM.synchrony do
    redis = Redis.new
      redis.subscribe(:channel) do |on|
        on.subscribe do |channel, subscriptions|
	  puts "subscribed to #{channel}: (#{subscriptions} subscriptions)"
        end
        
        on.message do |channel, message|
	  begin
	    data = JSON.parse message
	    
	    puts "##{channel}: #{message}"
	    if str = subscriptions[data['key']]
	      str.send data['msg']
	      str.close if data['msg'] == 'close'
	    end
	  rescue => e
	    p e
	  end
        end
        
        on.unsubscribe do |channel, subscriptions|
	  puts "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
        end
      end
   end
end

App = lambda do |env|
  if Faye::EventSource.eventsource? env
    key = 'some_key'
    
    streams << stream = Faye::EventSource.new(env,
      ping: 1, 	# ping every second to avoid closed connections
      retry: 5 	# seconds
    )
    
    subscriptions[key] = stream
    p [:open, stream.url, stream.ping, stream.last_event_id]
    
    stream.on :close do |event|
      p [:close, stream.url, stream.last_event_id]
      streams.delete stream 
      stream = nil
    end
    
    # Return async Rack response
    stream.rack_response
  else
    # Normal HTTP request
    [200, {'Content-Type' => 'text/plain'}, ['Hello there!']]
  end
end