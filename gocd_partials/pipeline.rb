require 'net/http'
require 'uri'
require 'json'

def create_pipe(addr,id,gr,mat,ag)
    uri = URI.parse("http://#{addr}/go/api/admin/pipelines")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Accept"] = "application/vnd.go.cd.v10+json"
    request["X-pause-pipeline"]=''
    req = %({ "group": "#{gr}",
                      "pipeline": {
                      "label_template": "${COUNT}",
                      "lock_behavior": "none",
                      "name": "#{id}",
                      "template": null,
                      "materials": [
                        {
                          "type": "git",
                          "attributes": {
                            "url": "#{mat}",
                            "filter": null,
                            "invert_filter": false,
                            "name": null,
                            "auto_update": true,
                            "branch": "master",
                            "submodule_folder": null,
                            "shallow_clone": true
                          }
                        }
                      ],
                      "stages": [
                        {
                          "name": "defaultStage",
                          "fetch_materials": true,
                          "clean_working_directory": false,
                          "never_cleanup_artifacts": false,
                          "approval": {
                            "type": "success",
                            "authorization": {
                              "roles": [],
                              "users": []
                            }
                          },
                          "environment_variables": [],
                          "jobs": [
                            {
                              "name": "defaultJob",
                              "run_instance_count": null,
                              "timeout": null,                              
                              "elastic_profile_id" : "#{ag}",
                              "environment_variables": [],
                              "resources": [],
                              "tasks": [
                                {
                                  "type": "exec",
                                  "attributes": {
                                    "run_if": [
                                      "passed"
                                    ],
                                    "command": "/bin/sh",
                                    "arguments" : [ "build.sh" ]
                                  }
                                }
                              ],
                              "artifacts": [ ]
                            }
                          ]
                        }
                      ],
                      "tracking_tool" : null,
                      "timer" : null
                  }
                })
    
    request.body=JSON.parse(req.to_json)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
    end
    case response
    when Net::HTTPOK
        #OK
        # puts 'allright'
        # puts response.body.to_s
        true
    else
        #"ERROR occured STATUS : #{response.code} \n\n #{respose.value}"
        # JSON.parse(response.body)
        false
    end
end

def delete_pipe(addr,id)
    uri = URI.parse("http://#{addr}/go/api/admin/pipelines/#{id}")
    request = Net::HTTP::Delete.new(uri.path)    
    request["Accept"] = "application/vnd.go.cd.v10+json"      

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
    end
    case response
    when Net::HTTPOK
        #OK
        # puts 'deleted'
        # puts response.body.to_s
        true
    else
        #"ERROR occured STATUS : #{response.code} \n\n #{respose.value}"
        # response.body.to_s
        false
    end
end

def delete_pipe_g(addr,id)
    uri = URI.parse("http://#{addr}/go/api/admin/pipeline_groups/#{id}")
    request = Net::HTTP::Get.new(uri.path)    
    request["Accept"] = "application/vnd.go.cd.v1+json"      

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
    end
    case response
    when Net::HTTPOK
        #OK
        # puts response.body.to_s
        if response.body.to_s.include? '"pipelines" : [ ]'
            request = Net::HTTP::Delete.new(uri.path)    
            request["Accept"] = "application/vnd.go.cd.v1+json"
            response = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(request)
            end
            case response
            when Net::HTTPOK
                #OK
                # puts 'deleted'
                # puts response.body.to_s
                true
            else
                #"ERROR occured STATUS : #{response.code} \n\n #{respose.value}"
                # response.body.to_s
                false
            end
        else
            # puts 'not empty'
            false
        end   
    else
        #"ERROR occured STATUS : #{response.code} \n\n #{respose.value}"
        # 'not empty'
        false
    end
end


# s='35.244.192.159'
# i='test-ruby-pipe'
# g='test-ruby-group'
# m=git url
# e='tester'


# puts "press any-key to create pipeline"
# gets
# puts create_pipe(s,i,g,m,e)

# puts "press anykey to delete the pipe"
# gets
# puts delete_pipe(s,i)

# puts "press anykey to delete the pipe"
# gets
# puts delete_pipe_g(s,g)

