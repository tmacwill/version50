class SCM
    # commit changes without pushing
    def commit
        print "What changes have you made since your last save? "
        message = $stdin.gets.chomp
    end

    # configure the repo with the user's info
    def config
    end

    # initialize a new repo
    def init
    end

    # view the project history
    def log
    end

    def pull
    end

    # push existing commits
    def push
    end

    # shortcut for commit and push
    def save
        self.commit
        self.push
    end

    # view changed files
    def status
    end
end
