class SCM
    # configure the repo with the user's info
    def config
    end

    # initialize a new repo
    def init
    end

    def log
    end

    def pull
    end

    def push
    end

    # save a new version
    def save
        print "What changes have you made since your last save? "
        message = $stdin.gets.chomp
    end

    # view changed files
    def status
    end
end
