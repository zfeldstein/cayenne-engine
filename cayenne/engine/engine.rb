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
              if ! workflow_request['workflow']['workflow_props'].is_a? Hash
                return [400, "workflow properties must be supplied as a hash"]
              end
            end
            #Check if job_ids specifeid and is a list
            if workflow_request['workflow'].has_key?('job_ids')
              if  workflow_request['workflow']['job_ids'].is_a? Array
                workflow_request['workflow']['job_ids'].map! {|jobs| jobs.values }
                #Store array of job"ids in db as comma delimted string
                workflow_request['workflow']['job_ids'] = workflow_request['workflow']['job_ids'].join(",")
              else
                return [400, "job ids must be supplied as a list"]
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