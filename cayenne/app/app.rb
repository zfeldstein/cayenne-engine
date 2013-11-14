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
  property :created_at, DateTime
  property :updated_at, DateTime
end

class Job
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  #property :pre_run, String
  #property :post_run, String
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
get "/workflows/:id" do
  @workflow = WorkFlow.get(params[:id])
  @workflow.to_json
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
    @workflow = WorkFlow.create(workflow_request)
  else
    response_json['response'] = workflow_request[1]
    response_json['response'] = workflow_request[0]
    body response_json.to_json
    status workflow_request[0]
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

=begin
 List jobs for a workflow
=end
get "/workflows/:id/jobs" do
  @jobs = Job.all(:workflow_id => params[:id])
  @jobs.to_json
end
=begin
Create jobs for a given workflow id
=end
post "/workflows/:id/jobs" do
  job_request = request.body.read
  engine = Cayenne::Engine::Job.new
  job_request = engine.validate_request(job_request, params[:id])
  response_json = {"response" => nil, "code" => job_request[0]}
  status job_request[0]
  
  if job_request[0] == 202
    job_request = job_request[1]['job']
    @job = Job.create(job_request)
  else
    response_json['response'] = job_request[1]
    response_json['code'] = job_request[0]
    body response_json.to_json
    status job_request[0]
  end
end

=begin
Delete a Job
=end
delete "/jobs/:id" do
  response_json = {'response' => nil, 'code' => nil}
  begin 
    @job = Job.get(params[:id])
    @job.destroy
  rescue
    response_json['response'] = 'Job id not found'
    response_json['code'] = 404
    status 404
    body response_json.to_json
  end
end
=begin
Show job details
=end
get "/jobs/:id" do
  @job = Job.get(params[:id])
  @job.to_json
end

post "/jobs/:id/tasks" do
  task_request = request.body.read
  engine = Cayenne::Engine::Task.new
  task_request = engine.validate_request(task_request, params[:id])
  response_json = {"response" => nil, "code" => task_request[0]}
  if task_request[0] == 202
    task_request = task_request[1]['task']
    @task = Task.create(task_request)
  else
    response_json['response'] = task_request[1]
    response_json['code'] = task_request[0]
    body response_json.to_json
    status task_request[0]
  end
end

get "/jobs/:id/tasks" do
  @tasks = Task.all(:job_id => params[:id])
  @tasks.to_json
end
