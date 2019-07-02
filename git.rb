def getCommitterName()
	result = `git --no-pager show -s --format='%cn'`
	return result.strip()
end

def getCommitterMail()
	result = `git --no-pager show -s --format='%ce'`
	return result.strip()
end

def getCommitComment
	result = `git log -1 --pretty=%B`
	result.strip
end

# Git has no knowledge of a project name, this basically just prunes the URL
def getProjectName()
	curl = 'git config --local remote.origin.url|sed -n "s#.*/\([^.]*\)\.git#\1#p"'
	result = `#{curl}`
	return result.strip()
end

def getRemoteOriginUrl()
	result = `git config --local remote.origin.url`
	return result.strip()
end

def getGithubPageUrl()
	origin = getRemoteOriginUrl()
	last_part = origin.split(":")[-1]
	url = "https://github.com/" + last_part
	return url
end

def getCurrentBranchName
	gitcommit = ENV['GIT_CLONE_COMMIT_HASH']
	result = `git rev-parse --abbrev-ref $#{gitcommit}`
	result.strip
end