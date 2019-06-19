require 'json'
require_relative 'hockey'
require_relative 'slack'
require_relative 'git'

puts 'Nodes CI Deploy'


# for testing purposes, when running bitrise run test remove the final festival (FF) at the end
=begin
ENV['HOCKEYBUILDSJSON'] = '[
  {
    "build": "app-firstSkin-release-unsigned.apk",
    "hockeyId": "9aad7c10facc4f569dd6deec2e37a795",
    "appId": "dk.nodes.citestflavors.firstskin",
    "mappingFile": "null"
  },
  {
    "build": "app-secondSkin-release-unsigned.apk",
    "hockeyId": "0c7b2da8e5354a26b8d6d4406c387c6f",
    "appId": "dk.nodes.citestflavors.secondskin",
    "mappingFile": "null"
  }
]'
=end

$hockeyToken = ENV['HOCKEY_TOKEN']
$appCenterToken = ENV['APP_CENTER_TOKEN']
$slackUrl = ENV['SLACK_WEBHOOK_URL']
$errorSlackChannel = ENV['ERROR_SLACK_CHANNEL']
$projectSlackChannel = ENV['PROJECT_SLACK_CHANNEL']
$hockeyJsonBuilds = ENV['HOCKEYBUILDSJSON']

puts "Hockey Token: #{$hockeyToken}"
puts "Slack URL: #{$slackUrl}"
puts "Error Channel: #{$errorSlackChannel}"
puts "Project Slack Channel: #{$projectSlackChannel}"
puts "Json: #{$hockeyJsonBuilds}"
puts "App Center Token: #{$appCenterToken}"

def initBuilds(builds)
  builds.each do |build|
    build['error'] = false
  end
end

def sanityCheckBuilds(builds)
  builds.each do |build|
    # skip builds with error or no hockeyinfo
    if build['error'] || build['hockeyInfo'] == nil
      next
    end
    #puts build['hockeyInfo'].inspect.gsub(",", "\n")
    #puts build['latestHockeyVersion'].inspect.gsub(",", "\n")

    if(build['hockeyInfo']['visibility'] == "private")
      $url = "https://rink.hockeyapp.net/manage/apps/#{build['hockeyInfo']['id']}/settings?type=distribution"
      reportError("Could not post build " + build['hockeyInfo']['title'] + ", go to <" + $url + "| Distribution Settings> and set download page to Public")
      build['error'] = true
      next
    end

    if(build['appId'] != build['hockeyInfo']['bundle_identifier'])
      reportError("appId #{build['appId']} from build.gradle is not the same as the hockey bundle identifier #{build['hockeyInfo']['bundle_identifier']}")
      build['error'] = true
      next
    end
  end
end

$version = "1.0"

if $appCenterToken == nil || $appCenterToken.empty?
  puts "APP_CENTER_TOKEN missing in Bitrise app secrets, please add it. Stopping."
  exit 1
end

puts "Parsing build info"
# retrieve build info json from env variable
json = ENV['HOCKEYBUILDSJSON']
buildPath = ENV['BITRISE_SOURCE_DIR']

if json == nil || json.to_s.empty?
  puts "Env var: HOCKEYBUILDSJSON was empty, trying to read from file: #{buildPath}/hockeybuilds.json"
  json = File.read("#{buildPath}/hockeybuilds.json")
end
if json == nil || json.to_s.empty?
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

puts "[34;1mBuild info (size: #{builds.length}):[0m #{json}"

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


#reportError("Error", "Av for helvede")

