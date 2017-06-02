require 'json'
require_relative 'hockey'
require_relative 'slack'
require_relative 'git'
puts 'Android CI Deploy'

# define these in .bitrise.secrets.yml
$hockeyToken = ENV['HOCKEY_TOKEN']
$slackWebHookUrl = ENV['SLACK_WEBHOOK_URL']

# for testing purposes, when running bitrise run test remove the final festival (FF) at the end
ENV['HOCKEYBUILDSJSONFF'] = '
[
	{
		"build": "/Users/bison/ci/ci-test-android/app/build/outputs/apk/app-firstSkin-release-unsigned.apk",
		"hockeyId": "9aad7c10facc4f569dd6deec2e37a795",
		"appId": "dk.nodes.citestflavors.firstskin",
		"mappingFile": "null"
	},
	{
		"build": "/Users/bison/ci/ci-test-android/app/build/outputs/apk/app-secondSkin-release-unsigned.apk",
		"hockeyId": "0c7b2da8e5354a26b8d6d4406c387c6f",
		"appId": "dk.nodes.citestflavors.secondskin",
		"mappingFile": "null"
	}
]
'


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
json = ENV['HOCKEYBUILDSJSON']
if json == nil
	reportError("Build info could not be parsed from HOCKEYBUILDSJSON env var (empty)")
	exit 1
end
if(!validJson?(json))
	reportError("Build info could not be parsed from HOCKEYBUILDSJSON env var (parse failed)")
	exit 1
end
builds = JSON.parse(json)
if builds == nil
	reportError("Build info could not be parsed from HOCKEYBUILDSJSON env var (parse failed)")
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


