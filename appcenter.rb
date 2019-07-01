require 'json'
require_relative 'hockey'
require_relative 'slack'
require_relative 'git'
require 'net/http'
require 'uri'
require 'json'

def generate_next_build_number(build)

  url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/releases"
  curl = 'curl -sS \
			           -H "X-API-Token: ' + $appCenterToken + '" ' + url
  result = `#{curl}`

  puts "Result data:" + result

  unless validJson?(result)
    nil
  end

  data = JSON.parse(result)

  puts "Json data from build releases #{data}"

  if data.empty? #verify if array is empty
    release_id = 1
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
  curl = 'curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "X-API-Token: ' + $appCenterToken + '" ' + url
  result = `#{curl}`

  unless validJson?(result)
    nil
  end

  data = JSON.parse(result)

  puts "Json data from build releases #{data}"

  build['upload_url'] = data['upload_url']
  build['upload_id'] = data['upload_id']

end

def upload_to_appcenter(build)
  url = build['upload_url']

  curl = 'curl -sS \
			           -F "ipa=@' + build['build'] + '" \
			           -H "X-API-Token: ' + $appCenterToken + '" \
			           -o /dev/null -w "%{http_code}" ' + url

  puts "Uploading #{build['build']}"

  `#{curl}`

end

# def uploadAppCenterBuild(build)
#   url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/release_uploads"
#   curl = 'curl -sS \
# 			           -H "X-API-Token: ' + $appCenterToken + '" ' + url
#   result = `#{curl}`
#
#   unless validJson?(result)
#     return nil
#   end
#
#   data = JSON.parse(result)
#
#   if data['status']
#     if data['status'] == "success"
#       return data['app']
#     else
#       puts "getAppInfoHockey error: ${data['message']}"
#     end
#   end
#
#   nil
# end


def commit_upload(build)

  url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/release_uploads" + build['upload_id']

  curl = 'curl -X PATCH --header "Content-Type: application/json" \
              --header "Accept: application/json" \
              --header "X-API-Token: ' + $appCenterToken + '" \
              -d \'{ "status": "committed"  }\' \
              ' + url

  result = `#{curl}`

  unless validJson?(result)
    nil
  end

  data = JSON.parse(result)

  puts "Response from release commit: #{data}"

end

def distribute(build)

  uri = URI.parse("https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/releases/#{build['nextReleaseNumber']}")
  request = Net::HTTP::Patch.new(uri)
  request.content_type = "application/json"
  request["Accept"] = "application/json"
  request["X-Api-Token"] = $appCenterToken
  request.body = JSON.dump({
                               :destination_name => "All-Users-of-" + build['appName'],
                               :release_notes => "Example new release via the APIs"
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

  puts "Json data from build releases #{data}"

end