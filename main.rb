require 'json'
require_relative 'hockey'
require_relative 'slack'
puts 'Android CI Deploy'

ENV['HOCKEYBUILDSJSON'] = '
[
	{
		"build": "/Users/bison/ci/ci-test-android/app/build/outputs/apk/app-firstSkin-release-unsigned.apk",
		"hockeyId": "firstskinxxxxxxxxxxxx",
		"appId": "dk.nodes.citestflavors.firstskin",
		"mappingFile": "null"
	},
	{
		"build": "/Users/bison/ci/ci-test-android/app/build/outputs/apk/app-firstSkin-staging-unsigned.apk",
		"hockeyId": "firstskinxxxxxxxxxxxx",
		"appId": "dk.nodes.citestflavors.firstskin.staging",
		"mappingFile": "null"
	},
	{
		"build": "/Users/bison/ci/ci-test-android/app/build/outputs/apk/app-secondSkin-release-unsigned.apk",
		"hockeyId": "secondskinxxxxxxxxxxxx",
		"appId": "dk.nodes.citestflavors.secondskin",
		"mappingFile": "null"
	},
	{
		"build": "/Users/bison/ci/ci-test-android/app/build/outputs/apk/app-secondSkin-staging-unsigned.apk",
		"hockeyId": "secondskinxxxxxxxxxxxx",
		"appId": "dk.nodes.citestflavors.secondskin.staging",
		"mappingFile": "null"
	}
]
'


json = ENV['HOCKEYBUILDSJSON']
buildInfo = JSON.parse(json)
puts buildInfo.inspect.gsub(",", "\n")

buildInfo.each do |build|
  #puts "#{key}-----"
  deployBuild build
end

postMsg("@stpe", "Hej Per! har du savnet mig?")


