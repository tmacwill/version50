require 'rubygems'
require 'version50/git'
require 'json'
require 'optparse'
require 'yaml'
require 'net/http'
require 'net/https'
require 'highline/import'
HighLine.track_eof = false

class Version50
    def initialize(args)
        # parse configuration
        config = self.parse_config
        @scm = self.scm config

        # no configuration file, so prompt to create a new project
        if !config
            config = self.create
            @scm = self.scm config
        end

        # set user info
        @scm.config config

        # commit a new version without pushing
        if args[:action] == 'commit'
            @scm.commit
        end

        # view the commit history
        if args[:action] == 'history' || args[:action] == 'log'
            commits = @scm.log
            self.output_history commits
        end

        # push the current project
        if args[:action] == 'push'
            @scm.push
        end

        # save a new version, which means commit and push
        if args[:action] == 'save'
            @scm.save
        end

        # get the current status of files
        if args[:action] == 'status'
            files = @scm.status
            self.output_status files
        end
    end

    def create
        # prompt for user info
        puts "\nLooks like you're creating a new project!\n\n"
        name = ask("What's your name? ").chomp
        email = ask("And your email? ").chomp
        puts "If you're hosting your project using a service like GitHub or BitBucket, paste the URL here."
        puts "If not, you can just leave this blank!"
        remote = $stdin.gets.chomp

        # create configuration hash
        config = {
            'name' => name,
            'email' => email,
            'remote' => remote,
            'scm' => 'git'
        }

        # prompt to create ssh key if one doesn't exist
        if !File.exists?(File.expand_path '~/.ssh/id_rsa') && !File.exists?(File.expand_path '~/.ssh/id_dsa')
            puts "It looks like you don't have an SSH key!"
            answer = ask("Would you like to create one now? [y/n] ").chomp

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
            answer = ask("If you've already done this, you won't need to do so again! [y/n] ").chomp.downcase

            # prompt for github info
            if answer == 'y' || answer == 'yes'
                # repeat until authentication is successful
                response = nil
                while !response || response.code != '201'
                    username = ask("What's your GitHub username? ").chomp
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
        File.open(Dir.pwd + '/.version50', 'w') do |f|
            f.write config.to_yaml
        end

        puts "\nYour project created successfully, have fun!"
        puts "<3 version50"

        return config
    end

    # given a parsed SCM history output, show log
    def output_history commits
        commits.each_with_index do |commit, i|
            puts "\033[031m#%03d \033[0m#{commit[:message]} \033[34m(#{commit[:timestamp]} by #{commit[:author]})" % (commits.length - i)
        end

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
        # create config file if not existing
        config_file = Dir.pwd + '/.version50'
        if !File.exists? config_file
            File.open(config_file, 'w') {}
        end

        # load version50 config
        YAML.load_file config_file
    end

    # determine the scm engine based on the config file
    def scm config
        # no engine specified
        if !config
            return nil
        end

        # git backend
        if config['scm'] == 'git'
            return Git.new
        end
    end
end
