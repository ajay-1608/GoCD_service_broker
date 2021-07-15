require 'net/http'
require 'uri'
require 'json'

def create_agent(addr,id)
    uri = URI.parse("http://#{addr}/go/api/elastic/profiles")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Accept"] = "application/vnd.go.cd.v2+json"
    request.body = JSON.parse(%({
        "id": "#{id}",
        "cluster_profile_id": "k8-cluster-profile",
        "properties": [
            {
                "key": "PodSpecType",
                "value": "yaml"
            },
            {
                "key": "Privileged",
                "value": "true"
            },
            {
                "key": "Image",
                "value": "gocd/gocd-agent-docker-dind:v20.4.0"
            },
            {
                "key": "PodConfiguration",
                "value": "apiVersion: v1\nkind: Pod\nmetadata:\n  name: gocd-agent-{{ POD_POSTFIX }}\n  labels:\n    app: web\nspec:\n  serviceAccountName: default\n  containers:\n    - name: gocd-agent-container-{{ CONTAINER_POSTFIX }}\n      image: gocd/gocd-agent-docker-dind:v20.4.0\n      securityContext:\n        privileged: true"
            }
        ]
    }).to_json)
    

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
    end
    case response
    when Net::HTTPOK
        #OK
        #JSON.parse(response.body)
        true
    else
        #"ERROR occured STATUS : #{response.code} \n\n #{respose.value}"
        false
    end
end

def delete_agent(addr,id)
    uri = URI.parse("http://#{addr}/go/api/elastic/profiles/#{id}")
    request = Net::HTTP::Delete.new(uri.path)    
    request["Accept"] = "application/vnd.go.cd.v2+json"      

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
    end
    case response
    when Net::HTTPOK
        #OK
        #JSON.parse(response.body)
        true
    else
        #"ERROR occured STATUS : #{response.code} \n\n #{respose.value}"
        false
    end
end