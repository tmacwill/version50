require 'pathname'

class SCM
    # check out a specific revision
    def checkout
        # prompt for revision
        print "\033[34mWhat version would you like to warp to?\033[0m "
        commit = $stdin.gets.chomp.to_i(10)

        return commit
    end

    # commit changes without pushing
    def commit
        # check if we have anything to commit
        files = self.status
        if files[:added].length == 0 && files[:modified].length == 0 && files[:deleted].length == 0
            puts "Nothing has changed since your last save!"

        # prompt for commit message
        else
            puts "\033[34mWhat changes have you made since your last save?\033[0m "
            message = $stdin.gets.chomp
        end

        return message
    end

    # configure the repo with the user's info
    def config info
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
