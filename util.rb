require 'shellwords'

def runCurlJson(data, url)
	json_data = JSON.generate(data)
    escaped_data = Shellwords.escape(json_data)
    curl = "curl -sS -X POST -H \'Content-type: application/json\' --data #{escaped_data} -o /dev/null -w \"%{http_code}\" #{url}"
    #puts "running curl:\n#{curl}\n"
    result = `#{curl}`
    return result
end

def wasCurlOk(result)
	if !result.is_a? String 
		return false
	end
	if result[0, 2] == "20"
		return true
	else
		return false
	end
end

def validJson?(string)
	begin
		!!JSON.parse(string)
	rescue JSON::ParserError
		false
	end
end
