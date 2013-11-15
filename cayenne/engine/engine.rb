require "rubygems"
require "bunny"
require 'json'
class Cayenne
  class Engine < Cayenne
=begin
 Work flow class
=end
    class WorkFlow < Engine
      attr_accessor :workflow_props, :workflow_id, :update_at, :created_at, :job_ids, :name, :id
      
      def job_path()
        @job_path = '/opt/cayenne/jobs'
      end
     
      def validate_request(workflow_request)
        begin
        workflow_request = JSON.parse(workflow_request)
          if  workflow_request.has_key?('workflow')
            #if no name attr specfied 
            if ! workflow_request['workflow'].has_key?('name')
              return [400, "No name specified for workflow"]
            end
            # Check if workflow_props exist and specfied as hash
            if workflow_request['workflow'].has_key?('workflow_props')
              if workflow_request['workflow']['workflow_props'].is_a? Array
                 workflow_request['workflow']['workflow_props'] = workflow_request['workflow']['workflow_props'].to_json
              else
                return [400, "workflow properties must be supplied as a list of key value pairs"]
              end
            end
          else
            #If no work flow key specified
            return [400, 'No workflow key specified']
          end
          return [202, workflow_request]
        end
      rescue
        return [500, "An error has occurred"]
      end
      
    
    end
  
=begin
 Job class
=end 
    class Job < WorkFlow
      attr_accessor :job_id, :pre_run, :post_run, :tasks,
      :job_status, :job_time, :job_props, :id
      
      def validate_request(job_request,wflow_id)
        begin
          job_request = JSON.parse(job_request)
          if !wflow_id
            return [400, "missing workflow id"]
          else
            job_request['job']['workflow_id'] = wflow_id
          end
          
          if job_request.has_key?('job')
            #Make sure job is named
            if ! job_request['job']['name']
              return [400, "job name must be specified"]
            end
            #all good
            return [202, job_request]
          else
            return [400, "no Job key specified"]  
          end
        rescue
          return [500, "An error has occurred"]
        end
      end
      
      def run(tasks)
        connection = Bunny.new
        connection.start
        channel  = connection.create_channel
        tasks = JSON.parse(tasks)
        # topic exchange name can be any string
        exchange = channel.topic("cayenne.jobs")
        tasks.each {|task|
          exchange.publish(task.to_json, :routing_key => 'linux', :reply_to => 'job_accepted')
        }
        connection.close

      end
    end
    
=begin
 Task Class
=end
    class Task < Job
      attr_accessor :job_id, :interpreter, :cmd, :name, :id
      
      def validate_request(task_request,job_id)
        begin
          task_request = JSON.parse(task_request)
          if task_request.has_key?('task')
            if ! task_request['task'].has_key?('name')
              return [400, "task name must be specified"]
            end
           if !task_request['task'].has_key?('interpreter')
              return [400, "no interpreter specified"]
            end
           if !task_request['task'].has_key?('cmd')
            return [400, "no script/command specfied"]
           end
           task_request['task']['job_id'] = job_id
           return[202, task_request]
          else
            return [400, "no task key specified"]  
          end
          
        rescue
          return [500, "An error has occurred"]
        end
        
      end
=begin
Create task file on server and return path
=end
    def create_task_file(task_data)
      file_name = Random.rand(10...180000000) + 9123812
      file_path = "#{job_path}/#{@job_id}/#{file_name}"
      job_dir = "#{job_path}/#{@job_id}"
      unless File.directory?(job_dir) 
        FileUtils.mkdir_p(job_dir)
      end
      File.open(file_path, "w"){|f| f.write(task_data)}
      return file_path
    end
      
    end
  end
end