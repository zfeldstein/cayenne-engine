require "rubygems"
require "bunny"
require 'json'
require_relative 'engine'
#connection = Bunny.new
#connection.start
#
#channel  = connection.create_channel
## topic exchange name can be any string
#exchange = channel.topic("workflows")
#
#job_info = {"job" => {
#      "post_run" => nil,
#      "pre_run" => nil,
#      "id" => Random.rand(10..10000000),
#      "tasks" => [{"interpreter" => "Shell", "task" => "touch /tmp/worldnews.txt"}],
#    }
#  }.to_json
#exchange.publish(job_info, :routing_key => 'linux')
#
#connection.close
class Cayenne
job_info = {"job" => {
      "post_run" => nil,
      "pre_run" => nil,
      "id" => Random.rand(10..10000000),
      "tasks" => [{"interpreter" => "Shell", "task" => "touch /tmp/worldnews.txt"}],
    }
  }
  engine = Engine.new
  workflow = Engine::WorkFlow.new
  job = Engine::JobRunner.new(job_info['job'])
  job.start
  
  
end


