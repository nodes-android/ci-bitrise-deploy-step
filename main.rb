require 'json'
require_relative 'hockey'
require_relative 'slack'
require_relative 'git'
puts 'Android CI Deploy'

# define these in .bitrise.secrets.yml
$hockeyToken = ENV['HOCKEY_TOKEN']
$slackWebHookUrl = ENV['SLACK_WEBHOOK_URL']


def initBuilds(builds)
	builds.each do |build|
  		build['error'] = false
  	end
end

def sanityCheckBuilds(builds)
	builds.each do |build|
		# skip builds with error or no hockeyinfo
  		if !build['error'] && build['latestHockeyVersion'] == nil && build['hockeyInfo']
			next
		end
		if(build['latestHockeyVersion'] && !build['error']) 
			if(build['latestHockeyVersion']['status'] != 2)
				reportError("Could not post build " + build['latestHockeyVersion']['title'] + ", go to <" + build['latestHockeyVersion']['config_url'] + "|HockeyApp> and set download page to Public")
				build['error'] = true
				next
			end		
		end
		if(build['appId'] != build['hockeyInfo']['bundle_identifier'])
			reportError("appId #{build['appId']} from build.gradle is not the same as the hockey bundle identifier #{build['hockeyInfo']['bundle_identifier']}")
			build['error'] = true
			next
		end
  	end
end

$version = "1.0"

puts "Parsing build info"
# retrieve build info json from env variable
puts ENV['HOCKEYBUILDSJSON']
puts ENV['PROJECT_SLACK_CHANNEL']

json = ENV['HOCKEYBUILDSJSON']

if json == nil
	puts "Env var: HOCKEYBUILDSJSON was empty, trying to read from file: hockeybuilds.json"
	json File.read("./hockeybuilds.json")
end
if json == nil
	reportError("Build info could not be parsed from json (empty)")
	exit 1
end
if(!validJson?(json))
	reportError("Build info could not be parsed from json (json not valid)")
	exit 1
end
builds = JSON.parse(json)
if builds == nil
	reportError("Build info could not be parsed from json (parse failed)")
	exit 1
end

initBuilds builds

puts "Downloading info about latest app versions from hockeyapp..."
# lookup each build on hockey and add info it build exists
addInfoToBuildsHockey builds
#puts builds.inspect.gsub(",", "\n")
sanityCheckBuilds(builds)

puts "Uploading builds to hockeyapp..."
#puts builds.inspect.gsub(",", "\n")
uploadBuildsHockey(builds)

puts "Downloading info about latest app versions from hockeyapp..."
# get hockey info about the just uploaded builds
addInfoToBuildsHockey builds

puts "Posting builds to slack"
#if shouldAbortBuildsPostEntirely(builds)
#	reportError("No builds to post due to previous errors")
#	exit(1)
#end
postBuildsSlack builds

#postMsg("@stpe", "Hej Per! har du savnet mig?")

#reportError("Error", "Av for helvede")


