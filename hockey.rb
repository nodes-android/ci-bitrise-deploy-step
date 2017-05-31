require 'shellwords'
require_relative 'util'
require_relative 'git'
$hockeyToken = "7998516508134a98b971850f0b244286"
#$hockeyToken = "7998516508134a98b971850f0b2442"

def uploadBuildHockey(build)
    url = "https://rink.hockeyapp.net/api/2/apps/#{build['hockeyId']}/app_versions/upload"
    notes = ""
    if build['latestHockeyVersion'] 
    	notes = getCommitComment() + "\n\n"
	end

    if build['mappingFile'] != "null"
		curl = 'curl -sS \
			           -F "status=2" \
			           -F "notify=0" \
			           -F "ipa=@' + build['build'] + '" \
			           -F "dsym=@' + build['mappingFile'] + '" \
			           -F "notes=' + Shellwords.escape(notes) + '" \
			           -F "notes_type=0" \
			           -H "X-HockeyAppToken: ' + $hockeyToken + '" \
			           -o /dev/null -w "%{http_code}" ' + url;
	else
		curl = 'curl -sS \
			           -F "status=2" \
			           -F "notify=0" \
			           -F "ipa=@' + build['build'] + '" \
			           -F "notes=' + Shellwords.escape(notes) + '" \
			           -F "notes_type=0" \
			           -H "X-HockeyAppToken: ' + $hockeyToken + '" \
			           -o /dev/null -w "%{http_code}" ' + url;
	end
	puts "curl = #{curl}"
	exit 1
	puts "Uploading #{build['build']}"
	result = `#{curl}`
	return result
end

def uploadBuildsHockey(builds)
	builds.each do |build|
  		result = uploadBuildHockey build
  		if(!wasCurlOk(result))
  			puts "Uploading build #{build['build']} to hockey app id #{build['hockeyId']} failed with code #{result}"
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
	return JSON.parse(result)
end

def getLatestAppVersionHockey(appId)
	versions = getAppVersionsHockey(appId)
	if(versions && versions.key?("app_versions"))
		versions = versions["app_versions"]
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
	latest = getLatestAppVersionHockey(build['hockeyId'])
	build['latestHockeyVersion'] = latest
	#puts build.inspect.gsub(",", "\n")
end

def addInfoToBuildsHockey(builds)
	# iterate trough each build and deploy
	builds.each do |build|
  		fetchAndAddHockeyInfoToBuild build
  		#break
  	end
end

