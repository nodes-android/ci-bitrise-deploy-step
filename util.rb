require 'shellwords'

def runCurlJson(data, url)
	json_data = JSON.generate(data)
    escaped_data = Shellwords.escape(json_data)
    curl = "curl -sS -X POST -H \'Content-type: application/json\' --data #{escaped_data} -o /dev/null -w \"%{http_code}\" #{url}"
    result = `#{curl}`
    return result
end
