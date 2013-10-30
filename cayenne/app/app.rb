require "rubygems"
require "bunny"
require 'json'
require 'sinatra'
require 'logger'
require 'dm-timestamps'
require 'data_mapper'
require 'dm-mysql-adapter'
require 'sinatra/reloader'
require_relative '../engine/engine'


DataMapper.setup(:default, "mysql://#{ENV['DB_USER']}:#{ENV['DB_PASS']}@localhost/cayenne_server")

#==============================
# Models
#==============================
class WorkFlow
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :workflow_props, String
  property :job_ids, String
  property :created_at, DateTime
  property :updated_at, DateTime
end

class Job
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :pre_run, String
  property :post_run, String
  property :task_ids, String
  property :workflow_id, Integer
  property :start_time, DateTime
  property :created_at, DateTime
  property :updated_at, DateTime  
end

class Task 
  include DataMapper::Resource
  property :id, Serial
  property :job_id, Integer
  property :name, String
  property :interpreter, String
  property :cmd, String
end

DataMapper.finalize
DataMapper.auto_upgrade!
=begin
 Before filter
=end
before do
  request.body.rewind
end
=begin
 Web App
=end


=begin
 List all workflows (ACL's to come)
=end
get "/workflows" do
  @workflows = WorkFlow.all
  @workflows.to_json
end
=begin
 Create a new work flow, required attribute is workflow name
=end
post "/workflows" do
  workflow_request = JSON.parse(request.body.read)
  engine = Cayenne::Engine::WorkFlow.new
  workflow_request = engine.validate_request(workflow_request)
  error_json = {"error" => nil, "code" => workflow_request[0]}
  status workflow_request[0]
  
=begin
validate method returns 2 element array, 0th element will be return code
1st element will be error message or valid workflow object (hash)
=end

  if workflow_request[0] == 202
    workflow_request = workflow_request[1]['workflow']
    workflow = WorkFlow.create(
      :workflow_props => workflow_request['workflow_props'],
      :name => workflow_request['name'],
      :job_ids => workflow_request['job_ids']
    )
  else
    error_json['error'] = workflow_request[1]
    body error_json.to_json
  end

end
  