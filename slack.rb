require 'json'
require_relative 'util'
require_relative 'git'
require_relative 'slack'
require 'date'

$slackErrorColor = "#e03131" # Red
$slackBuildColor = "#36a64f" # Green
$slackWarningColor = "#36a64f" # Orange

def formatCodeString(code)
  '```' + code + '```'
end

def getProjectChannelName
  if ENV['PROJECT_SLACK_CHANNEL'] != nil && !ENV['PROJECT_SLACK_CHANNEL'].to_s.empty?
    ENV['PROJECT_SLACK_CHANNEL'].to_s
  else
    '#bitrise'
  end
end

def getBitriseBuildURL
  if ENV['BITRISE_BUILD_URL'] != nil && !ENV['BITRISE_BUILD_URL'].to_s.empty?
    ENV['BITRISE_BUILD_URL'].to_s
  else
    'https://www.bitrise.io/dashboard'
  end
end

def getBitriseTag
  if ENV['BITRISE_GIT_TAG'] != nil && !ENV['BITRISE_GIT_TAG'].to_s.empty?
    ENV['BITRISE_GIT_TAG'].to_s
  else
    '(No tag found)'
  end
end

def getBitriseTimestamp
  if ENV['BITRISE_BUILD_TRIGGER_TIMESTAMP'] != nil && !ENV['BITRISE_BUILD_TRIGGER_TIMESTAMP'].to_s.empty?
    ENV['BITRISE_BUILD_TRIGGER_TIMESTAMP'].to_s
  else
    '(No time found)'
  end
end

def getBitriseBranch
  if ENV['BITRISE_GIT_BRANCH'] != nil && !ENV['BITRISE_GIT_BRANCH'].to_s.empty?
    ENV['BITRISE_GIT_BRANCH'].to_s
  else
    '(unknown branch)'
  end
end

def getErrorChannelName
  if ENV['ERROR_SLACK_CHANNEL'] != nil && !ENV['ERROR_SLACK_CHANNEL'].to_s.empty?
    ENV['ERROR_SLACK_CHANNEL'].to_s
  else
    '#bitrise'
  end
end

def postMsg(channel, msg)
  data = {
      :channel => channel,
      :text => msg,
      :username => 'android-ci'
  }
  runCurlJson(data, $slackUrl)
end

def post_build_finished(builds)

  has_failed_build = false
  failed_build_count = 0

  builds.each do |build|
    if build['error']
      has_failed_build = true
      failed_build_count = failed_build_count + 1
    end
  end

  message_color = $slackBuildColor

  if has_failed_build
    message_color = $slackWarningColor
  end

  if failed_build_count == builds.length
    message_color = $slackErrorColor
  end

  attachments = []
  # Bitrise attachment
  attachments.push({
                       :fallback => "Build finished",
                       :title => "Bitrise status",
                       :text => "Build finished",
                       :color => message_color,
                       :mrkdwn_in => %w(footer text),
                       :actions => [{
                                        :type => "button",
                                        :text => "Build log",
                                        :url => getBitriseBuildURL,
                                        :style => "primary"
                                    }]
                   })
  data = {
      :channel => getProjectChannelName,
      :username => 'bitrise-ci',
      :mrkdwn => true,
      :attachments => attachments
  }

  runCurlJson(data, $slackUrl)

end

def postBuildsSlack(builds)

  has_failed_build = false
  failed_build_count = 0

  builds.each do |build|
    if build['error']
      has_failed_build = true
      failed_build_count = failed_build_count + 1
    end
  end

  message_color = $slackBuildColor

  if has_failed_build
    message_color = $slackWarningColor
  end

  if failed_build_count == builds.length
    message_color = $slackErrorColor
  end

  attachments = []

  # Bitrise attachment
  attachments.push(
      {
          :fallback => "Tag *#{getBitriseTag}* triggered on *#{getBitriseBranch}* by #{getCommitterName} (#{getCommitterMail})",
          :title => "Bitrise status",
          :color => message_color,
          :text => "Tag *#{getBitriseTag}* triggered on *#{getBitriseBranch}* by #{getCommitterName} (#{getCommitterMail})",
          :mrkdwn_in => %w(footer text),
          :actions => [{
                           :type => "button",
                           :text => "Build log",
                           :url => getBitriseBuildURL,
                           :style => "primary"
                       }]
      })

  builds.each do |build|

    if build['errorMessage']

      attachments.push(
          {
              :fallback => msg,
              :title => "Error deploying #{getProjectName} [branch: #{getBitriseBranch}]",
              :title_link => getGithubPageUrl,
              :text => build['errorMessage'],
              :color => $slackErrorColor,
              :mrkdwn_in => ["text"]
          }
      )

    else

      attachments.push(
          {
              :fallback => "#{build['build_info']['app_display_name']} v#{build['build_info']['shortversion']} (#{build['build_info']['version']})",
              :color => $slackBuildColor,
              :title => "#{build['build_info']['app_display_name']} v#{build['build_info']['shortversion']} (#{build['build_info']['version']})",
              :actions => [
                  {
                      :type => "button",
                      :text => "Install",
                      :url => "https://install.appcenter.ms/orgs/#{build['ownerName']}/apps/#{build['appName']}/distribution_groups/all-users-of-#{build['appName']}",
                      :style => "primary"
                  }
              ]
          })
    end

  end

  data = {
      :channel => getProjectChannelName,
      :username => 'bitrise-ci',
      :mrkdwn => true,
      :attachments => attachments
  }

  runCurlJson(data, $slackUrl)

end

def reportErrorSlack(msg)
  title = "Error deploying #{getProjectName} [branch: #{getBitriseBranch}]"
  puts "title = #{title}"
  data = {
      :channel => getErrorChannelName,
      :username => 'bitrise-ci',
      :mrkdwn => true,
      :attachments => [
          {
              :fallback => msg,
              :title => title,
              :title_link => getGithubPageUrl,
              :text => msg,
              :color => $slackErrorColor,
              :footer => "Bitrise CI " + $version + ", report bugs and feature requests on the <https://trello.com/b/7Blqe5gH/bitrise-ci|Trello board>",
              :mrkdwn_in => ["text"]
          }
      ]
  }
  #puts "data = #{data}"
  runCurlJson(data, $slackUrl)
end

def reportError(msg, detail = nil)

  if detail
    puts "Error: #{msg}\n#{detail}"
  else
    puts "Error: #{msg}"
  end

  if detail
    msg += "\n#{detail}"
  end
  reportErrorSlack msg

end

