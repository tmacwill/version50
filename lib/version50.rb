require 'version50/git'
require 'optparse'
require 'yaml'

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
        @scm.config config['name'], config['email']

        # save a new version
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
        print "What's your name? "
        name = $stdin.gets.chomp
        print "And your email? "
        email = $stdin.gets.chomp
        print "Will your project use git? "
        git = $stdin.gets.chomp

        # create configuration hash
        config = {
            'name' => name,
            'email' => email,
            'scm' => 'git'
        }

        # save config
        File.open(Dir.pwd + '/.version50', 'w') do |f|
            f.write config.to_yaml
        end

        return config
    end

    # given a parsed SCM status output, show file status
    def output_status files
        # new files
        if files[:added].length > 0
            print "\033[32m"
            puts "\nNew Files"
            puts "=========\n\n"

            files[:added].each do |file|
                puts "* #{file}"
            end
        end

        # modified files
        if files[:modified].length > 0
            print "\033[33m"
            puts "\n\nModified Files"
            puts "==============\n\n"

            files[:modified].each do |file|
                puts "* #{file}"
            end
        end

        # deleted files
        if files[:deleted].length > 0
            print "\033[31m"
            puts "\n\nDeleted Files"
            puts "=============\n\n"

            files[:deleted].each do |file|
                puts "* #{file}"
            end
        end

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
