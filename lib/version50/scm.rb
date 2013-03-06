require 'pathname'
require 'yaml'

class SCM
    def initialize(version50)
        @version50 = version50
    end

    # create a branch
    def branch b
    end

    # checkout a branch
    def checkout b
        self.save({ :quiet => true })
    end

    # commit changes without pushing
    def commit(options = {})
        # make sure we're not in a warp
        config = @version50.parse_config
        if config['warp']
            puts "\033[31mYou cannot commit any changes until you warp back to the present!\033[0m"
            return
        end

        # check if we have anything to commit
        files = self.status
        if files[:added].length == 0 && files[:modified].length == 0 && files[:deleted].length == 0
            if !options[:quiet]
                puts "Nothing has changed since your last save!"
            end

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

    def download(url, path = '')
    end

    # initialize a new repo
    def init
    end

    # view the project history
    def log
    end

    # return to the present
    def present
    end

    def pull
    end

    # push existing commits
    def push
    end

    # recover a path from a warp
    def recover path
        # determine what warp we're in
        config = @version50.parse_config
        if !config['warp']
            puts "\033[31mYou have to warp to another revision before you can recover anything!\033[0m"
            return
        end

        # make sure file exists
        if Dir.glob(path).empty?
            puts "\033[31mSpecify a valid path to recover!\033[0m"
            return
        end

        # copy all files in path into warps folder
        warp = config['warp']
        files = Dir.glob path
        root = @version50.root
        files.each do |f|
            FileUtils.mkdir_p(root + '/.version50-warps/' + File.dirname(f))
            FileUtils.cp(f, root + '/.version50-warps/' + File.dirname(f))
        end

        # display which files were recovered
        if files.length == 1
            puts "\033[032mRecovered #{files[0]}!\033[0m"
        else
            puts "\033[032mRecovered:\n"
            files.each do |f|
                puts "* #{f}"
            end
            puts "\033[0m"
        end
    end

    def reset
    end

    # shortcut for commit and push
    def save(commit_options = {})
        self.commit commit_options
        self.push
    end

    # view changed files
    def status
    end

    # warp to a specific revision
    def warp revision = nil
        # warp back to the present
        if revision == 'present'
            puts "\033[032mWarped back to the present!\033[0m"
            self.present

            # remove warp number from .version50
            config = @version50.parse_config
            config.delete 'warp'
            File.open(@version50.root + '/.version50', 'w') do |f|
                f.write config.to_yaml
            end

            # move files from warps folder
            root = @version50.root
            FileUtils.mv(Dir.glob(root + '/.version50-warps/*'), root)
            return false
        end

        # save before doing anything
        self.save({ :quiet => true })

        # prompt for revision if not given
        if !revision
            print "\033[34mWhat version would you like to warp to?\033[0m "
            revision = $stdin.gets.chomp.to_i(10)
        else
            revision = revision.to_i(10)
        end

        # get revision from numerical index
        revisions = self.log
        r = revisions[revisions.length - revision]

        # record where we warped
        config = @version50.parse_config
        config['warp'] = revision
        File.open(@version50.root + '/.version50', 'w') do |f|
            f.write config.to_yaml
        end

        puts "\033[032mWarped to revision ##{revision}!\033[0m"

        # add numerical index to return value
        r[:revision] = revision
        return r
    end
end
