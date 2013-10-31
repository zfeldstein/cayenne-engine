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
  workflow_request = request.body.read
  engine = Cayenne::Engine::WorkFlow.new
  workflow_request = engine.validate_request(workflow_request)
  response_json = {"response" => nil, "code" => workflow_request[0]}
  status workflow_request[0]
  
=begin
validate method returns 2 element array, 0th element will be return code
1st element will be error message or valid workflow object (hash)
=end

  if workflow_request[0] == 202
    workflow_request = workflow_request[1]['workflow']
    @workflow = WorkFlow.create(
      :workflow_props => workflow_request['workflow_props'],
      :name => workflow_request['name'],
      :job_ids => workflow_request['job_ids']
    )
  else
    response_json['response'] = workflow_request[1]
    body response_json.to_json
  end

end

=begin
Delete a workflow
=end
delete "/workflows/:id" do
  response_json = {'response' => nil, 'code' => nil}
  begin
    @workflow = WorkFlow.get(params[:id])
    @workflow.destroy
    status 204
    response_json['response'] = "Workflow deleted"
    response_json['code'] = 204
    body response_json.to_json
  rescue
    status 404
    response_json['response'] = "workflow does not exist"
    response_json['code'] = 404
    body response_json.to_json
  end
end

=begin
 Update a workflow
=end

put "/workflows/:id" do
  response_json = {}
  engine = Cayenne::Engine::WorkFlow.new
  workflow_request = request.body.read
  workflow_request = engine.validate_request(workflow_request)
  response_json['code'] = workflow_request[0]
  if workflow_request[0] == 202
    begin
      @workflow = WorkFlow.get(params[:id])
      @workflow.update(workflow_request[1]['workflow'])
    rescue
      status 404
      response_json['response'] = workflow_request[1]
      response_json['code'] = 404
      body response_json.to_json
    end
  end
end
  