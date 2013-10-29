require "rubygems"
require "bunny"
require 'json'
class Cayenne
  class Engine < Cayenne
#===========================================
# Work flow class
#===========================================
    class WorkFlow < Engine
      attr_accessor :workflow_props, :workflow_id, :start_time, :finish_time
    
      def initialize
        @workflow_props = nil
        @workflow_id = Random.rand(10..900000000) + 1024
        @start_time = nil
        @finish_time = nil
      end
    
    end
  
#========================================================
# Job class
#========================================================
    class JobRunner < WorkFlow
      attr_accessor :job_id, :pre_run, :post_run, :tasks,
      :job_status, :job_time, :job_props
      
      def initialize(job_data)
        @job_id = job_data['id']
        @pre_run = job_data['pre_run']
        @post_run = job_data['post_run']
        @tasks = job_data['tasks']
        @job_status = nil
        @job_time = nil
      end
      
      def start
        connection = Bunny.new
        connection.start
        channel  = connection.create_channel
        # topic exchange name can be any string
        exchange = channel.topic("cayenne.jobs")
        @tasks.each {|task|
          exchange.publish(task.to_json, :routing_key => 'linux')
        }
        connection.close

      end
    end
  end
end