require 'sinatra'
require 'json'
require 'yaml'
require 'erb'
require_relative 'github_service_helper'
require_relative 'post.rb'
require_relative 'gocd_partials/elastic_agent.rb'
require_relative 'gocd_partials/pipeline.rb'

class ServiceBrokerApp < Sinatra::Base
  set :bind, '0.0.0.0'
  set :port, '3000'
  #configure the Sinatra app
  use Rack::Auth::Basic do |username, password|
    credentials = self.app_settings.fetch("basic_auth")
    username == credentials.fetch("username") and password == credentials.fetch("password")
  end
  
  #declare the routes used by the app
  #  https://8f08a292984c.ngrok.io   #!/bin/bash

  #DOCK PAGE
  get "/" do
    @posts=Post.all()
    erb :index
  end

  get '/favicon.ico' do
    "200"
  end

  # CATALOG
  get "/v2/catalog" do
    content_type :json

    self.class.app_settings.fetch("catalog").to_json
  end

  # PROVISION
  put "/v2/service_instances/:id" do |id|
    content_type :json
    gocd= self.class.app_settings.fetch("gocd")
    gocd_server=gocd.fetch("server")
    repo_name = repository_name(id)
    begin
      repo_url = github_service.create_github_repo(repo_name)
      if create_agent(gocd_server,"elastic-#{id}")===true
        if create_pipe(gocd_server,"pipeline-#{id}","group-#{id}",repo_url,"elastic-#{id}") === true
          s=JSON.parse(request.body.string)
          s[:instance_id]=id
          s[:go_server]="http://#{gocd_server}/go"
          @post=Post.new(id,s) 
          status 201
        end
      else
        status 501
        {"description" => "The server does not support the functionality required to fulfill the request.The server does not recognize the request method and is not capable of supporting it for any resource."}.to_json
      end
      {"dashboard_url" => repo_url}.to_json
    rescue GithubServiceHelper::RepoAlreadyExistsError
      status 501
      {"description" => "The repo #{repo_name} already exists in the GitHub account"}.to_json
    rescue GithubServiceHelper::GithubUnreachableError
      status 504
      {"description" => "GitHub is not reachable"}.to_json
    rescue GithubServiceHelper::GithubError => e
      status 502
      {"description" => e.message}.to_json
    end
  end

  # BIND
  put '/v2/service_instances/:instance_id/service_bindings/:id' do |instance_id, binding_id|
    content_type :json

    begin
      credentials = github_service.create_github_deploy_key(repo_name: repository_name(instance_id), deploy_key_title: binding_id)
      s=JSON.parse(request.body.string)
      if Post.bind(instance_id,binding_id,s)===true
        status 201
      else
        status 404
        return {"description" => "GitHub resource not found"}.to_json 
      end

      {"credentials" => credentials}.to_json
    rescue GithubServiceHelper::GithubResourceNotFoundError
      status 404
      {"description" => "GitHub resource not found"}.to_json
    rescue GithubServiceHelper::BindingAlreadyExistsError
      status 409
      {"description" => "The binding #{binding_id} already exists"}.to_json
    rescue GithubServiceHelper::GithubUnreachableError
      status 504
      {"description" => "GitHub is not reachable"}.to_json
    rescue GithubServiceHelper::GithubError => e
      status 502
      {"description" => e.message}.to_json
    end
  end

  # UNBIND
  delete '/v2/service_instances/:instance_id/service_bindings/:id' do |instance_id, binding_id|
    content_type :json

    begin
      if github_service.remove_github_deploy_key(repo_name: repository_name(instance_id), deploy_key_title: binding_id)
        if Post.unbind(instance_id,binding_id)===true
          status 200
        else
          status 410
        end
      else
        status 410
      end
      {}.to_json
    rescue GithubServiceHelper::GithubResourceNotFoundError
      status 410
      {}.to_json
    rescue GithubServiceHelper::GithubUnreachableError
      status 504
      {"description" => "GitHub is not reachable"}.to_json
    rescue GithubServiceHelper::GithubError => e
      status 502
      {"description" => e.message}.to_json
    end
  end

  # UNPROVISION
  delete '/v2/service_instances/:instance_id' do |instance_id|
    content_type :json
    gocd= self.class.app_settings.fetch("gocd")
    gocd_server=gocd.fetch("server")
    begin
      if github_service.delete_github_repo(repository_name(instance_id)) 
        if delete_pipe(gocd_server,"pipeline-#{instance_id}")===true 
          if delete_pipe_g(gocd_server,"group-#{instance_id}") ===true 
            if delete_agent(gocd_server,"elastic-#{instance_id}")===true
              if Post.deinitialize(instance_id)===true
                status 200
              end
            end
          end
        end
      else
        status 410
      end
    {}.to_json
    rescue GithubServiceHelper::GithubUnreachableError
      status 504
      {"description" => "GitHub is not reachable"}.to_json
    rescue GithubServiceHelper::GithubError => e
      status 502
      {"description" => e.message}.to_json
    end
  end

  #helper methods
  private

  def repository_name(id)
    "github-service-#{id}"
  end

  def self.app_settings
    settings_filename = defined?(SETTINGS_FILENAME) ? SETTINGS_FILENAME : 'config/settings.yml'
    @app_settings ||= YAML.load_file(settings_filename)
  end

  def github_service
    github_credentials = self.class.app_settings.fetch("github")
    GithubServiceHelper.new(github_credentials.fetch("username"), github_credentials.fetch("access_token"))
  end


  run!
end