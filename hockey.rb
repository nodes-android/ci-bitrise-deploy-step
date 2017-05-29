require 'shellwords'
$hockeyToken = "7998516508134a98b971850f0b244286"

def uploadBuild(build)
    url = "https://rink.hockeyapp.net/api/2/apps/#{build['hockeyId']}/app_versions/upload"
    notes = "notes=hej per"
    if build['mappingFile'] != "null"
		curl = 'curl -sS \
			           -F "status=2" \
			           -F "notify=0" \
			           -F "ipa=@' + build['build'] + '" \
			           -F "dsym=@' + build['mappingFile'] + '" \
			           -F ' + Shellwords.escape(notes) + ' \
			           -F "notes_type=0" \
			           -H "X-HockeyAppToken: ' + $hockeyToken + '" \
			           -o /dev/null -w "%{http_code}" ' + url;
		puts curl
		#result = `#{curl}`
	end
end

