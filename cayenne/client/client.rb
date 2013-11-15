require "rubygems"
require "bunny"
require 'json'
#========================================================
# Workflow class
#========================================================
class WorkFlow 
  attr_accessor :workflow_props, :worflow_id
  def initialize(args)
    #code
  end
end
#========================================================
# Job class
#========================================================
class CayenneJob < WorkFlow
  attr_accessor :job_id, :job_props
  def initialize
    #code
  end
end
#========================================================
# Interpreter class
#========================================================
class Interpreter < CayenneJob
  
end
#========================================================
# Job class
#========================================================
class Shell < Interpreter
  def initialize(cmd)
    @cmd = cmd
  end
  
  def process
    shell_cmd = `#{@cmd}`
    puts @cmd
    puts shell_cmd
  end
end
#========================================================
# Task class
#========================================================
class TaskRunner < CayenneJob
  def initialize(task_data)
    @interpreter = task_data['interpreter']
    @cmd = task_data['cmd']
  end
  def run
    begin
      exec = Kernel.const_get(@interpreter.capitalize).new(@cmd)
    rescue
      puts "No interpreter found you specified #{@interpreter}"
    end
    job_properties = exec.process
    if job_properties
      #Set the props and push them out to the db via RPC call
    end
    
  end  
end
#Shell interpreter
connection = Bunny.new
connection.start
channel  = connection.create_channel
exchange = channel.topic("cayenne.jobs")

# Subscribers.
channel.queue("linux").bind(exchange, :routing_key => "linux").subscribe do |delivery_info, metadata, payload|
  payload = JSON.parse(payload)
  payload.each {|task|
    task = TaskRunner.new(payload)
    task.run
  }
    
    
  end
  
  


connection.close

