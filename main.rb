require 'json'
require_relative 'appcenter'
require_relative 'slack'
require_relative 'git'

puts 'Nodes CI Deploy'

$appCenterToken = ENV['APP_CENTER_TOKEN']
$slackUrl = ENV['SLACK_WEBHOOK_URL']
$errorSlackChannel = ENV['ERROR_SLACK_CHANNEL']
$projectSlackChannel = ENV['PROJECT_SLACK_CHANNEL']
$appCenterJsonBuilds = ENV['APPCENTERJSON']

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

$version = "1.0"

if $appCenterToken == nil || $appCenterToken.empty?
  puts "APP_CENTER_TOKEN missing in Bitrise app secrets, please add it. Stopping."
  exit 1
end

puts "Parsing build info"
# retrieve build info json
buildPath = ENV['BITRISE_SOURCE_DIR']
json = File.read("#{buildPath}/appcenterbuilds.json")

if json == nil || json.to_s.empty?
  reportError("Build info could not be parsed from json (empty)")
  exit 1
end

unless validJson?(json)
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

builds.each do |build|

  puts build['appName'] + "Generating build number"
  build['nextReleaseId'] = generate_next_build_number build

  puts build['appName'] + "Generating build upload url"
  get_upload_url build

  puts build['appName'] + "Uploading build to AppCenter"
  upload_to_appcenter build

  puts build['appName'] + "Commiting uploaded build"
  commit_upload build

  puts build['appName'] + "Distributing build"
  distribute build

end

postBuildsSlack builds

