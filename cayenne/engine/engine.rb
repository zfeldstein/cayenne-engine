require "rubygems"
require "bunny"
require 'json'
class Cayenne
  class Engine < Cayenne
#===========================================
# Work flow class
#===========================================
    class WorkFlow < Engine
      attr_accessor :workflow_props, :workflow_id, :update_at, :created_at, :job_ids, :name
     
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
  
#========================================================
# Job class
#========================================================
    class Job < WorkFlow
      attr_accessor :job_id, :pre_run, :post_run, :tasks,
      :job_status, :job_time, :job_props
      
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