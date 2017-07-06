require 'json'
require_relative 'util'
require_relative 'git'
require_relative 'slack'

$slackErrorColor = "#e03131"
$slackBuildColor = "#BADA55"

def formatCodeString(code)
  return '```' + code + '```'
end

def getProjectChannelName()
  puts "Project Slack Channel: " + ENV['PROJECT_SLACK_CHANNEL']
  if (ENV['PROJECT_SLACK_CHANNEL'])
    return ENV['PROJECT_SLACK_CHANNEL']
  else
    return '#bitrise'
  end
end

def getErrorChannelName()
  puts "Error Channel: " + ENV['ERROR_SLACK_CHANNEL']
  if (ENV['ERROR_SLACK_CHANNEL'])
    return ENV['ERROR_SLACK_CHANNEL']
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

  builds.each do |build|
    if build['error']
      parts = build['build'].split("/")
      apk = parts[-1]
      text += "\nApk #{apk} (Hockey id: #{build['hockeyId']}) could not be deployed due to errors"
      next
    end
    if (build['latestHockeyVersion'] && !build['error'])
      text += "\n<" + build['latestHockeyVersion']['download_url'] + "|" + build['latestHockeyVersion']['title'] + " v#{build['latestHockeyVersion']['shortversion']} (#{build['latestHockeyVersion']['version']})" + ">"
    end
  end

  #text += "\nNew " + type + " build (v " + version + ", branch: " + getCurrentBranchName() + ") deployed, download from <" + hockey_link + "|HockeyApp>";
  title = "#{getProjectName()} (branch: #{getCurrentBranchName()}) builds deployed:"
  fallback = "#{getCommitterName} deployed new build(s) of #{getProjectName()}"

  data = {
      "channel" => getProjectChannelName(),
      "username" => 'bitrise-ci',
      "mrkdwn" => true,
      "attachments" => [{
                            "fallback" => fallback,
                            "title" => title,
                            "title_link" => getGithubPageUrl(),
                            "text" => text,
                            "author_name" => "#{getCommitterName} (#{getCommitterMail})",
                            "color" => $slackBuildColor,
                            "footer" => "Bitrise CI " + $version + ", report bugs and feature requests on the <https://trello.com/b/7Blqe5gH/bitrise-ci|Trello board>",
                            "mrkdwn_in" => ["text"]
                        }]
  }
  puts "data = #{data}"
  result = runCurlJson(data, $slackUrl)
  puts "result = #{result}"
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
  puts "result = #{result}"
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

