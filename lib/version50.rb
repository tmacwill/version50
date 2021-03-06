require 'rubygems'
require 'version50/git'
require 'json'
require 'optparse'
require 'yaml'
require 'net/http'
require 'net/https'
require 'fileutils'
require 'highline/import'
HighLine.track_eof = false

class Version50
    def initialize(action, args = [])
        # help text
        if action == 'help'
            return self.help
        end

        # version number
        if action == 'version'
            return self.version
        end

        # parse configuration
        config = self.parse_config
        @scm = self.scm config

        # download a repository
        if action == 'download'
            if args[0] =~ /git/
                @scm = self.scm({ 'scm' => 'git' })
            end

            # download repository
            puts "\033[033mDownloading project...\033[0m"
            @scm.download args[0], args[1]
            puts "\033[032mDownload complete!\033[0m"
            return
        end

        # no configuration file, so prompt to create a new project
        if !config
            config = self.create
            @scm = self.scm config
            @scm.init
        end

        # set user info
        @scm.config config

        # create a new branch
        if action == 'branch'
            @scm.branch args[0]
        end

        # commit a new version without pushing
        if action == 'commit'
            @scm.commit
        end

        # view the commit history
        if action == 'history' || action == 'log'
            commits = @scm.log
            self.output_history commits
        end

        # pull from the main remote
        if action == 'pull'
            @scm.pull
        end

        # push the current project
        if action == 'push'
            @scm.push
        end

        # undo all changes since last save
        if action == 'reset'
            @scm.reset
        end

        # save a new version, which means commit and push
        if action == 'save'
            @scm.save
            puts "\n\033[032mSaved a new version!\033[0m"
        end

        # switch to a branch
        if action == 'switch'
            @scm.checkout args[0]
        end

        # get the current status of files
        if action == 'status'
            files = @scm.status
            self.output_status files
        end

        # recover a file from a warp
        if action == 'recover'
            @scm.recover args[0]
        end

        # warp to a past version
        if action == 'warp'
            @scm.warp args[0]
        end
    end

    def create
        # prompt for user info
        puts "\nLooks like you're creating a new project!\n\n"
        name = ask("What's your name? ")
        email = ask("And your email? ")
        puts "If you're hosting your project using a service like GitHub or BitBucket, paste the URL here."
        puts "If not, you can just leave this blank!"
        remote = $stdin.gets.chomp

        # create configuration hash
        config = {
            'name' => name.to_s,
            'email' => email.to_s,
            'remote' => remote.to_s,
            'scm' => 'git'
        }

        # prompt to create ssh key if one doesn't exist
        if !File.exists?(File.expand_path '~/.ssh/id_rsa') && !File.exists?(File.expand_path '~/.ssh/id_dsa')
            puts "It looks like you don't have an SSH key!"
            answer = ask("Would you like to create one now? [y/n] ")

            # user responded with yes, so create key
            if answer == 'y' || answer == 'yes'
                # prompt for password of at length 5
                path = File.expand_path '~/.ssh/id_rsa'
                password = ''
                while password.length < 5
                    password = ask("Type a password for your key (at least 5 characters): ") { |q| q.echo = '*' }
                end

                # use ssh keygen to create key
                `ssh-keygen -q -C "#{email}" -t rsa -N "#{password}" -f #{path}`
            end
        end

        # prompt to add key to remote account
        if remote =~ /github/
            puts "Would you like to add your key to your GitHub account?"
            answer = ask("If you've already done this, you won't need to do so again! [y/n] ")

            # prompt for github info
            if answer == 'y' || answer == 'yes'
                # repeat until authentication is successful
                response = nil
                while !response || response.code != '201'
                    username = ask("What's your GitHub username? ")
                    password = ask("And your GitHub password? ")  { |q| q.echo = '*' }

                    # post key to github
                    http = Net::HTTP.new('api.github.com', 443)
                    http.use_ssl = true
                    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                    request = Net::HTTP::Post.new('/user/keys')
                    request['Content-Type'] = 'application/json'
                    request.basic_auth username, password
                    request.body = {
                        'title' => 'version50',
                        'key' => File.open(File.expand_path('~/.ssh/id_rsa.pub')).gets
                    }.to_json
                    response = http.request(request)
                end
            end
        end

        # save config
        FileUtils.mkdir(Dir.pwd + '/.version50-warps')
        File.open(Dir.pwd + '/.version50', 'w') do |f|
            f.write config.to_yaml
        end

        puts "\n\033[032mYour project was created successfully!"
        puts "<3 version50\033[0m"

        return config
    end

    # help text
    def help
        puts "\033[34mThis is Version50.\033[0m"
        puts "Here are some things you can do!"
        puts "* history: View the history of your project's versions"
        puts "* recover: Recover an earlier version of a file"
        puts "* save: Save a version of your project"
        puts "* status: Get the current status of your project"
        puts "* warp: Warp back to an earlier point in time"
    end

    # given a parsed SCM history output, show log
    def output_history commits
        # output each commit
        commits.each_with_index do |commit, i|
            puts "\033[031m#%03d \033[0m#{commit[:message]} \033[34m(#{commit[:timestamp]} by #{commit[:author]})" % (commits.length - i)
        end

        # ansi reset
        print "\033[0m"
    end

    # given a parsed SCM status output, show file status
    def output_status files
        # new files (ansi green)
        if files[:added].length > 0
            print "\033[32m"
            puts "\nNew Files"
            puts "=========\n\n"

            files[:added].each do |file|
                puts "* #{file}"
            end
            puts ""
        end

        # modified files (ansi yellow)
        if files[:modified].length > 0
            print "\033[33m"
            puts "\nModified Files"
            puts "==============\n\n"

            files[:modified].each do |file|
                puts "* #{file}"
            end
        end

        # deleted files (ansi red)
        if files[:deleted].length > 0
            print "\033[31m"
            puts "\nDeleted Files"
            puts "=============\n\n"

            files[:deleted].each do |file|
                puts "* #{file}"
            end

            puts ""
        end

        # nothing changed
        if files[:added].length == 0 && files[:modified].length == 0 && files[:deleted].length == 0
            print "Nothing has changed since your last save!"
        end

        # ansi reset
        print "\033[0m\n"
    end

    # parse the version50 configuration file
    def parse_config
        # search upward to find project root
        path = self.root
        if path
            return YAML.load_file(path + '/.version50')
        end

        # project root not found
        return false
    end

    # get the path of the project root, as determined by the location of the .version50 file
    def root
        # search upward for a file called ".version50"
        path = Pathname.new(Dir.pwd)
        while path.to_s != '/'
            # check if file exists in this directory
            if path.children(false).select { |e| e.to_s == '.version50' }.length > 0
                return path.to_s
            end

            # continue to traverse upwards
            path = path.parent
        end

        # .version50 file not found
        return false
    end

    # determine the scm engine based on the config file
    def scm config
        # no engine specified
        if !config
            return nil
        end

        # git backend
        if config['scm'] == 'git'
            return Git.new(self)
        end
    end

    # version number
    def version
        puts "This is Version50 v0.0.1"
    end
end
