require 'shellwords'
require_relative 'util'
require_relative 'git'

def escapeNotes(notes)
	result = Shellwords.escape(notes)
	#result = notes
	puts "escaped notes: " + result
	return result
end

def setAppVisibilityPublicHockey(build)
	url = "https://rink.hockeyapp.net/api/2/apps/#{build['hockeyId']}/meta"
	curl = 'curl -sS -X PUT \
			           -F "visibility=public" \
			           -H "X-HockeyAppToken: ' + $hockeyToken + '" ' + url;
	result = `#{curl}`
	if(!validJson?(result))
		return false
	end
	data = JSON.parse(result)
	if(data['status'])
		if(data['status'] == "success")
			return true
		else
			puts "setAppVisibilityPublicHockey error: ${data['message']}"
		end
	end
	return false
end

def getAppInfoHockey(build)
	url = "https://rink.hockeyapp.net/api/2/apps/#{build['hockeyId']}/meta"
	curl = 'curl -sS \
			           -H "X-HockeyAppToken: ' + $hockeyToken + '" ' + url;
	result = `#{curl}`

	if(!validJson?(result))
		return nil
	end
	data = JSON.parse(result)
	if(data['status'])
		if(data['status'] == "success")
			return data['app']
		else
			puts "getAppInfoHockey error: ${data['message']}"
		end
	end
	return nil
end

def uploadBuildHockey(build)
    url = "https://rink.hockeyapp.net/api/2/apps/#{build['hockeyId']}/app_versions/upload"
    notes = "notes="
	changelog = ENV['COMMIT_CHANGELOG']
	if changelog != nil
		puts "uploadBuildHockey: " + changelog
	end

    if build['latestHockeyVersion'] 
		if changelog != nil && !changelog.to_s.empty?
			notes += changelog
		else
    		notes += getCommitComment()
		end
	end

	puts "uploadBuildHockey: " + notes

	#notes = Shellwords.escape("notes=line 1\nline 2\nline 3")

    if build['mappingFile'] != "null"
		curl = 'curl -sS \
			           -F "status=2" \
			           -F "notify=0" \
			           -F "ipa=@' + build['build'] + '" \
			           -F "dsym=@' + build['mappingFile'] + '" \
			           -F ' + escapeNotes(notes) + ' \
			           -F "notes_type=0" \
			           -H "X-HockeyAppToken: ' + $hockeyToken + '" \
			           -o /dev/null -w "%{http_code}" ' + url;
	else
		curl = 'curl -sS \
			           -F "status=2" \
			           -F "notify=0" \
			           -F "ipa=@' + build['build'] + '" \
			           -F ' + escapeNotes(notes) + ' \
			           -F "notes_type=1" \
			           -H "X-HockeyAppToken: ' + $hockeyToken + '" \
			           -o /dev/null -w "%{http_code}" ' + url;
	end
	#puts "curl = #{curl}"
	#exit 0
	puts "Uploading #{build['build']}"
	result = `#{curl}`
	return result
end

def uploadBuildsHockey(builds)
	builds.each do |build|
		if build['error']
			next
		end
		# Is this actually what we want?
		#if !build['latestHockeyVersion']
		#	reportError "Build #{build['build']} hockeyapp id #{build['hockeyId']} no latest hockey version found, skipping.\nCheck hockeyIds in gradle.build"
		#	build['error'] = true
		#	next
		#end
  		result = uploadBuildHockey build
  		if(!wasCurlOk(result))
  			reportError("Uploading build #{build['build']} to hockey app id #{build['hockeyId']} failed with code #{result}")
  			exit 1
  		else
  			puts "Uploaded build #{build['build']} to hockey app id #{build['hockeyId']}"
  		end
  	end
end

def getAppVersionsHockey(appId)
	curl = 'curl -sS \
	           -H "X-HockeyAppToken: ' + $hockeyToken + '" \
	           https://rink.hockeyapp.net/api/2/apps/' + appId + '/app_versions'
	result = `#{curl}`
	if validJson?(result) == false
		return nil
	else
		return JSON.parse(result)
	end
end

def getLatestAppVersionHockey(appId)
	versions = getAppVersionsHockey(appId)
	#puts "getLatestAppVersionHockey for appId #{appId} --> #{versions}"
	success = versions["status"] == "success"
	if(versions == nil)
		#puts "getLatestAppVersionHockey -> no versions found"
		return success, nil
	end
	if(versions && versions.key?("app_versions"))
		versions = versions["app_versions"]
	else
		#puts "getLatestAppVersionHockey -> could not find key app_versions in response #{versions}"
		return success, nil
	end
	if(versions)
		#puts "getLatestAppVersionHockey -> hockey versions #{versions}"
		versions.each do |version|	
  			version['img_url'] = "https://rink.hockeyapp.net/api/2/apps/" + appId + "?format=png";
		end
		return success, versions[0]
	else
		#puts "getLatestAppVersionHockey -> versions was empty or nil"
		return success, nil
	end
end


def fetchAndAddHockeyInfoToBuild(build)
	app = getAppInfoHockey(build)
	if app == nil
		reportError "Error attempting to fetch info about hockeyapp #{build['hockeyId']}. Please check if the app is marked as private or created on your own HockeyApp account."
		return false
	end
	success, latest = getLatestAppVersionHockey(build['hockeyId'])
	if latest == nil && !success
		reportError "Error attempting to fetch latest hockeyapp version (#{build['hockeyId']})"
		return false
	else
		build['latestHockeyVersion'] = latest	
	end
	build['hockeyInfo'] = app
	#puts build.inspect.gsub(",", "\n")
	return true
end

def addInfoToBuildsHockey(builds)
	# iterate trough each build and deploy
	builds.each do |build|
		if !build['error']
	  		if fetchAndAddHockeyInfoToBuild(build) == false
	  			build['error'] = true
	  		end
  		end
  	end
end

def uploadAppCenterBuild(build)
	url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/release_uploads"
	curl = 'curl -sS \
			           -H "X-API-Token: ' + $appCenterToken + '" ' + url;
	result = `#{curl}`

	if(!validJson?(result))
		return nil
	end
	data = JSON.parse(result)
	if(data['status'])
		if(data['status'] == "success")
			return data['app']
		else
			puts "getAppInfoHockey error: ${data['message']}"
		end
	end
	return nil
end

def getLatestBuildReleaseId(build)

	#url = "https://api.appcenter.ms/v0.1/apps/#{build['ownerName']}/#{build['appName']}/releases"
	url = "https://api.appcenter.ms/v0.1/apps/Casper-Rasmussen-Organization/Roast-Staging/releases"
	curl = 'curl -sS \
			           -H "X-API-Token: ' + $appCenterToken + '" ' + url
	result = `#{curl}`

	unless validJson?(result)
		nil
	end

	data = JSON.parse(result)

	put "Json data from build releases #{data}"

	release_id = data[0]['id']

	unless release_id.is_a? Integer
		nil
	end

	put "Current build id #{release_id}"
	put "Build id #{release_id + 1}"

	release_id + 1

end