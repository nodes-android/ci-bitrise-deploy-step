require 'json'
require_relative 'hockey'
require_relative 'slack'
require_relative 'git'
puts 'Android CI Deploy'

ENV['HOCKEYBUILDSJSON'] = '
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

$version = "1.0"

# retrieve build info json from env variable
json = ENV['HOCKEYBUILDSJSON']
builds = JSON.parse(json)

# lookup each build on hockey and add info it build exists
addInfoToBuildsHockey builds

#puts builds.inspect.gsub(",", "\n")

uploadBuildsHockey(builds)

postBuildsSlack builds

#postMsg("@stpe", "Hej Per! har du savnet mig?")

puts "committer: #{getCommitterName()}"
puts "committer mail: #{getCommitterMail()}"

puts "BITRISE_APP_URL = #{ENV['BITRISE_APP_URL']}"

puts "#{getCommitterChannelName()}"

#reportError("Error", "Av for helvede")


