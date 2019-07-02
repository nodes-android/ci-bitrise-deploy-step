require 'json'
require_relative 'slack'
require_relative 'git'
require 'net/http'
require 'uri'
require 'json'

def generate_next_build_number(build)

  url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/releases"
  curl = 'curl -sS \
			           -H "X-API-Token: ' + $app_center_token + '" ' + url
  result = `#{curl}`

  puts "Result data:" + result

  unless validJson?(result)
    nil
  end

  data = JSON.parse(result)

  puts "Json data generate_next_build_number #{data}"

  if data.empty? #verify if array is empty
    release_id = 0
  else
    release_id = data[0]['id'].to_i
  end

  unless release_id.is_a? Integer
    nil
  end

  puts "Current build id #{release_id}"
  puts "Next Build id #{release_id + 1}"

  build['nextReleaseNumber'] = release_id + 1

end

def get_upload_url(build)

  url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/release_uploads"
  curl = 'curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "X-API-Token: ' + $app_center_token + '" ' + url
  result = `#{curl}`

  unless validJson?(result)
    nil
  end

  data = JSON.parse(result)

  puts "Json data get_upload_url #{data}"

  build['upload_url'] = data['upload_url']
  build['upload_id'] = data['upload_id']

end

def upload_to_appcenter(build)
  url = build['upload_url']

  curl = 'curl -sS \
			           -F "ipa=@' + build['build'] + '" \
			           -H "X-API-Token: ' + $app_center_token + '" \
			           -o /dev/null -w "%{http_code}" ' + url

  puts "Uploading #{build['appName']}: #{build['build']}"

  `#{curl}`

  puts "Upload complete #{build['appName']}: #{build['build']}"

end

def commit_upload(build)

  url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/release_uploads/" + build['upload_id']

  curl = 'curl -X PATCH --header "Content-Type: application/json" \
              --header "Accept: application/json" \
              --header "X-API-Token: ' + $app_center_token + '" \
              -d \'{ "status": "committed"  }\' \
              ' + url

  result = `#{curl}`

  unless validJson?(result)
    nil
  end

  data = JSON.parse(result)

  puts "Json data commit_upload #{data}"

end

def distribute(build)

  destination_group = "All-Users-of-" + build['appName']
  puts "Destination group: " + destination_group

  url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/releases/#{build['nextReleaseNumber']}"
  puts "Url: " + url

  uri = URI.parse(url)
  request = Net::HTTP::Patch.new(uri)
  request.content_type = "application/json"
  request["Accept"] = "application/json"
  request["X-Api-Token"] = $app_center_token
  request.body = JSON.dump({
                               :destination_name => destination_group,
                               :release_notes => getCommitComment
                           })

  req_options = {
      use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  unless validJson?(response.body)
    nil
  end

  data = JSON.parse(response.body)

  if data.key?("message")
    build['error'] = true
    build['errorMessage'] = data['message']
  end

  puts "Json data from distribute #{data}"

end

def append_build_info(build)

  url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/releases/#{build['nextReleaseNumber']}"
  puts "Url: " + url

  uri = URI.parse(url)
  request = Net::HTTP::Get.new(uri)
  request["Accept"] = "application/json"
  request["X-Api-Token"] = $app_center_token

  req_options = {
      use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  unless validJson?(response.body)
    nil
  end

  data = JSON.parse(response.body)

  puts "Json data from append_build_info #{data}"

  build['build_info'] = data

end