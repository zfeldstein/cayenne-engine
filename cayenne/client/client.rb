require "rubygems"
require "bunny"
require 'json'
require 'tempfile'
require 'net/https'

#========================================================
# Cayenne class
#========================================================
class Cayenne
  def web_call(httpVerb,uri,headers=nil, request_content=nil)
    verbs =
            {"get" => "Net::HTTP::Get.new(uri.request_uri, headers)",
            "head" => "Net::HTTP::Head.new(uri.request_uri, headers)",
            "put" => "Net::HTTP::Put.new(uri.request_uri, headers)",
            "delete" => "Net::HTTP::Delete.new(uri.request_uri, headers)",
            "post" => "Net::HTTP::Post.new(uri.request_uri, headers)"
            }
    ssl_true = false
    if uri =~ /https/
                ssl_true = true
    end
    uri = URI.parse(uri)
    
    http = Net::HTTP.new(uri.host, uri.port)
    if ssl_true
                http.use_ssl = true
    end
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = eval verbs[httpVerb]
    if httpVerb == 'post' or httpVerb == 'put'
           request.body = request_content
    end
    response = http.request(request)
  end
  
  
end


#========================================================
# Workflow class
#========================================================
class WorkFlow < Cayenne
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
    run_task = system("#{@interpreter} #{@file_path}")
    #task_status = $?.success?
    #puts task_status
    puts run_task
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

