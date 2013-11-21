require "rubygems"
require "bunny"
require 'json'
require 'tempfile'
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
  # Create task Files to be executed and call the correct
  # interpreter class
  def initialize(task_data)
    file = Tempfile.new('task', "/opt/cayenne/jobs/#{task_data['job_id']}")
    begin
      file.write(task_data['cmd'])
      file.rewind
      # Call the actual interpreter class and run the scripts
      begin
        @exec = Kernel.const_get(task_data['interpreter'].capitalize).new(file.path)
      rescue
        puts "No interpreter found you specified #{task_data['interpreter']}"
      end
      # Process the task (i.e. run it)
      @exec.process
    ensure
      #file.close
      #file.unlink
    end
  end
end
#========================================================
# Job class
#========================================================
class Shell < Interpreter
  def initialize(file_path)
    @file_path = file_path
    @interpreter = 'bash'
  end
  
  def process
    run_script = `#{@interpreter} #{@file_path}`
  end
end
#========================================================
# Task class
#========================================================
class TaskRunner < CayenneJob
  def initialize(task_data)
    @task_data = task_data
  end
  def run
    exec = Interpreter.new(@task_data)
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
# Accept one task at a time, tasks will be split on the engine side
channel.queue("linux").bind(exchange, :routing_key => "linux").subscribe do |delivery_info, metadata, payload|
  payload = JSON.parse(payload)
  task = TaskRunner.new(payload)
  task.run
end
  
  


connection.close

