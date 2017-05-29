require 'json'
require_relative 'util'

$slackWebHookUrl = "https://hooks.slack.com/services/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"

def postMsg(channel, msg)
	data = { 
		"channel" => channel,
		"text" => msg, 
		"username" => 'android-ci'
    }
    runCurl(data, $slackWebHookUrl)
end