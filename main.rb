require 'json'
require_relative 'appcenter'
require_relative 'slack'
require_relative 'git'

puts 'Nodes CI Deploy'

$app_center_token = ENV['APP_CENTER_TOKEN']
$slack_url = ENV['SLACK_WEBHOOK_URL']
$error_slack_channel = ENV['ERROR_SLACK_CHANNEL']
$project_slack_channel = ENV['PROJECT_SLACK_CHANNEL']
$app_center_json_builds = ENV['APPCENTERJSON']

puts "Slack URL: #{$slack_url}"
puts "Error Channel: #{$error_slack_channel}"
puts "Project Slack Channel: #{$project_slack_channel}"
puts "Json: #{$app_center_json_builds}"
puts "App Center Token: #{$app_center_token}"

def init_builds(builds)
  builds.each do |build|
    build['error'] = false
  end
end

$version = "1.0"

if $app_center_token == nil || $app_center_token.empty?
  puts "APP_CENTER_TOKEN missing in Bitrise app secrets, please add it. Stopping."
  exit 1
end

puts "Parsing build info"
# retrieve build info json
build_path = ENV['BITRISE_SOURCE_DIR']
json = File.read("#{build_path}/appcenterbuilds.json")

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

init_builds builds

builds.each do |build|

  puts "+------------------------------------------------------------------------------+"
  puts build['appName'] + ": Generating build number"
  puts "+------------------------------------------------------------------------------+"
  build['nextReleaseId'] = generate_next_build_number build

  puts "+------------------------------------------------------------------------------+"
  puts build['appName'] + ": Generating build upload url"
  puts "+------------------------------------------------------------------------------+"
  get_upload_url build

  puts "+------------------------------------------------------------------------------+"
  puts build['appName'] + ": Uploading build to AppCenter"
  puts "+------------------------------------------------------------------------------+"
  upload_to_appcenter build

  puts "+------------------------------------------------------------------------------+"
  puts build['appName'] + ": Commiting uploaded build"
  puts "+------------------------------------------------------------------------------+"
  commit_upload build

  puts "+------------------------------------------------------------------------------+"
  puts build['appName'] + ": Distributing build"
  puts "+------------------------------------------------------------------------------+"
  distribute build

  puts "+------------------------------------------------------------------------------+"
  puts build['appName'] + ": Append build info"
  puts "+------------------------------------------------------------------------------+"
  append_build_info build

  puts "+------------------------------------------------------------------------------+"
  puts build['appName'] + ": Finished"
  puts "+------------------------------------------------------------------------------+"

end

postBuildsSlack builds