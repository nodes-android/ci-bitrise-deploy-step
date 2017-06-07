require 'shellwords'
require_relative 'util'
require_relative 'git'

def escapeNotes(notes)
	result = Shellwords.escape(notes)
	#result = notes
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
		end
	end
	return nil
end

def uploadBuildHockey(build)
    url = "https://rink.hockeyapp.net/api/2/apps/#{build['hockeyId']}/app_versions/upload"
    notes = "notes="

    if build['latestHockeyVersion'] 
    	notes += getCommitComment()
	end

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
			           -F "notes_type=0" \
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
		if !build['latestHockeyVersion']
			reportError "Build #{build['build']} hockeyapp id #{build['hockeyId']} no latest hockey version found, skipping.\nCheck hockeyIds in gradle.build"
			build['error'] = true
			next
		end
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
	if(versions == nil)
		return nil
	end
	if(versions && versions.key?("app_versions"))
		versions = versions["app_versions"]
	else
		return nil
	end
	if(versions)
		#puts "hockey versions #{versions}"
		versions.each do |version|	
  			version['img_url'] = "https://rink.hockeyapp.net/api/2/apps/" + appId + "?format=png";
		end
		return versions[0]
	else
		return nil
	end
end

def fetchAndAddHockeyInfoToBuild(build)
	app = getAppInfoHockey(build)
	if app == nil
		reportError "Error attempting to fetch info about hockeyapp #{build['hockeyId']}"
		return false
	end
	latest = getLatestAppVersionHockey(build['hockeyId'])
	if latest == nil
		reportError "Error attempting to fetch latest hockeyapp version (#{build['hockeyId']})"
		return false
	end
	build['latestHockeyVersion'] = latest
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

