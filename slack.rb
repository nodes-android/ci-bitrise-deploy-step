require 'json'
require_relative 'util'
require_relative 'git'
require_relative 'slack'

$slackErrorColor = "#e03131"
$slackBuildColor = "#36a64f"

def formatCodeString(code)
  return '```' + code + '```'
end

def getProjectChannelName()
	if ENV['PROJECT_SLACK_CHANNEL'] != nil && !ENV['PROJECT_SLACK_CHANNEL'].to_s.empty?
		return ENV['PROJECT_SLACK_CHANNEL'].to_s
	else
		return '#bitrise'
	end
end

def getBitriseBuildURL()
	if ENV['BITRISE_BUILD_URL'] != nil && !ENV['BITRISE_BUILD_URL'].to_s.empty?
		return ENV['BITRISE_BUILD_URL'].to_s
	else
		return 'https://www.bitrise.io/dashboard'
	end
end

def getBitriseTag()
	if ENV['BITRISE_GIT_TAG'] != nil && !ENV['BITRISE_GIT_TAG'].to_s.empty?
		return ENV['BITRISE_GIT_TAG'].to_s
	else
		return '(No tag found)'
	end
end

def getBitriseTimestamp()
	if ENV['BITRISE_BUILD_TRIGGER_TIMESTAMP'] != nil && !ENV['BITRISE_BUILD_TRIGGER_TIMESTAMP'].to_s.empty?
		return ENV['BITRISE_BUILD_TRIGGER_TIMESTAMP'].to_s
	else
		return '(No time found)'
	end
end

def getBitriseBranch()
	if ENV['BITRISE_GIT_BRANCH'] != nil && !ENV['BITRISE_GIT_BRANCH'].to_s.empty?
		return ENV['BITRISE_GIT_BRANCH'].to_s
	else
		return '(unknown branch)'
	end
end

def getErrorChannelName()
	if ENV['ERROR_SLACK_CHANNEL'] != nil && !ENV['ERROR_SLACK_CHANNEL'].to_s.empty?
		return ENV['ERROR_SLACK_CHANNEL'].to_s
	else
		return '#bitrise'
	end
end

def postMsg(channel, msg)
  data = {
      "channel" => channel,
      "text" => msg,
      "username" => 'android-ci'
  }
  runCurlJson(data, $slackUrl)
end

# do checking to determine if we should even attempt to post the builds
def shouldAbortBuildsPostEntirely(builds)
  builds.each do |build|
    if (build['latestHockeyVersion'] && !build['error'])
      return false
    end
  end
  return true
end

def postBuildsSlack(builds)
  comment = getCommitComment()
  text = ""
  if (comment.length > 0)
    text = formatCodeString(comment)
  end

  attachments = []
  # Bitrise attachment
  attachments.push({

            "fallback" => "Tag *#{getBitriseTag()}* triggered on *#{getBitriseBranch()}*, started *#{getBitriseTimestamp()}* by #{getCommitterName} (#{getCommitterMail}).",
            "title" => "Bitrise status",
			      "text" => "Tag *#{getBitriseTag()}* triggered on *#{getBitriseBranch()}*, started *#{getBitriseTimestamp()}* by #{getCommitterName} (#{getCommitterMail}).",
            "mrkdwn_in" => ["footer", "text"],
            "actions" => [
              {
                "type" => "button",
                "text" => "Build log",
                "url" => getBitriseBuildURL(),
                "style" => "primary"
              }
            ]
        })

  builds.each do |build|
    if build['error']
      parts = build['build'].split("/")
      apk = parts[-1]
      attachments.push({
        {
            "fallback" => "Apk #{apk} (Hockey id: #{build['hockeyId']}) could not be deployed due to errors",
            "color" => "#F50057",
            "title" => "Apk #{apk} (Hockey id: #{build['hockeyId']}) could not be deployed due to errors",
			      "actions" => [
              {
                "type" => "button",
                "text" => "Hockey page",
                "url" => "https://rink.hockeyapp.net/manage/apps/#{build['hockeyId']}",
                "style" => "danger"
              }
            ]
        }
      })
      next
    end
    if (build['latestHockeyVersion'] && !build['error'])
      attachments.push({
        {
            "fallback" => "#{build['latestHockeyVersion']['download_url']} #{build['latestHockeyVersion']['title']} v#{build['latestHockeyVersion']['shortversion']} (#{build['latestHockeyVersion']['version']})",
            "color" => $slackBuildColor,
            "title" => "#{build['latestHockeyVersion']['download_url']} #{build['latestHockeyVersion']['title']} v#{build['latestHockeyVersion']['shortversion']} (#{build['latestHockeyVersion']['version']})",
			      "actions" => [
              {
                "type" => "button",
                "text" => "Install",
                "url" => "https://rink.hockeyapp.net/manage/apps/#{build['hockeyId']}",
                "style" => "primary"
              }
            ]
        }
      })
    end
  end

  #text += "\nNew " + type + " build (v " + version + ", branch: " + getCurrentBranchName() + ") deployed, download from <" + hockey_link + "|HockeyApp>";
  title = "#{getProjectName()} (branch: #{getCurrentBranchName()}) builds deployed:"
  fallback = "#{getCommitterName} deployed new build(s) of #{getProjectName()}"

  data = {
      "channel" => getProjectChannelName(),
      "username" => 'bitrise-ci',
      "mrkdwn" => true,
      "attachments" => attachments
  }
  #puts "data = #{data}"
  result = runCurlJson(data, $slackUrl)
  #puts "result = #{result}"
end

def reportErrorSlack(msg)
  title = "Error deploying " + getProjectName() + " (branch: " + getCurrentBranchName() + ")"
  puts "title = #{title}"
  data = {
      "channel" => getErrorChannelName(),
      "username" => 'bitrise-ci',
      "mrkdwn" => true,
      "attachments" => [{
                            "fallback" => msg,
                            "title" => title,
                            "title_link" => getGithubPageUrl(),
                            "text" => msg,
                            "color" => $slackErrorColor,
                            "footer" => "Bitrise CI " + $version + ", report bugs and feature requests on the <https://trello.com/b/7Blqe5gH/bitrise-ci|Trello board>",
                            "mrkdwn_in" => ["text"]
                        }]
  }
  #puts "data = #{data}"
  result = runCurlJson(data, $slackUrl)
end

def reportError(msg, detail = nil)

  if (detail)
    puts "Error: #{msg}\n#{detail}"
  else
    puts "Error: #{msg}"
  end

  if (detail)
    msg += "\n#{detail}"
  end
  reportErrorSlack msg
end

