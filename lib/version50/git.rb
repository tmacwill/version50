require 'version50/scm'

class Git < SCM
    # create a branch
    def branch b
        `git branch #{b}`
    end

    # checkout a branch
    def checkout b
        super
        `git checkout #{b}`
    end

    # clone a repository
    def clone url, path = ''
        `git clone #{url} #{path}`
    end

    # commit a new version without pushing
    def commit(options = {})
        # prompt for commit message
        message = super

        # add all files and commit
        `git add --all`
        `git commit -m "#{message}"`
    end

    # configure the repo with user's info
    def config info
        # configure git user
        `git config user.name "#{info['name']}"`
        `git config user.email "#{info['email']}"`

        # configure remote if not already
        origin = `git remote`
        if origin == '' && info['remote'] != ''
            `git remote add origin #{info['remote']}`
        end
    end

    # create a new repo
    def init
        `git init`
        `echo ".version50\n.version50-warps" > .gitignore`
    end

    # view the project history
    def log
        # great idea or greatest idea?
        delimiter = '!@#%^&*'
        history = `git log --graph --pretty=format:'#{delimiter} %h #{delimiter} %s #{delimiter} %cr #{delimiter} %an' --abbrev-commit`

        # iterate over history lines
        commits = []
        lines = history.split "\n"
        lines.each_with_index do |line, i|
            # get information from individual commits
            commit = line.split(delimiter).map { |s| s.strip }
            commits.push({
                :id => commit[1],
                :message => commit[2],
                :timestamp => commit[3],
                :author => commit[4]
            })
        end

        return commits
    end

    # return to the present
    def present
        `git reset --hard`
        `git checkout master > /dev/null 2> /dev/null`
    end

    def pull
        # save before doing anything
        self.save({ :quiet => true })
        `git pull --rebase`
    end

    # push existing commits
    def push
        `git push -u origin master > /dev/null 2>&1`
    end

    # reset all changes since last commit
    def reset
        `git reset --hard`
    end

    # view changed files
    def status
        # get status from SCM
        status = `git status`

        # iterate over each line in status
        tracked = 0
        added, modified, deleted = [], [], []
        status.split("\n").each do |line|
            # ignore git system lines
            if tracked > 0 && line && line !=~ /\(use "git add <file>\.\.\." to include in what will be committed\)/ &&
                    line !=~ /\(use "git add <file>\.\.\." to update what will be committed\)/ &&
                    line !=~ /\(use "git checkout -- <file>\.\.\." to discard changes in working directory\)/

                # untracked files, so mark as added
                if tracked == 1
                    # determine filename
                    line =~ /^#\s*([\w\/\.\-]+)/
                    if $1
                        added.push $1
                    end

                # currently-tracked files
                elsif tracked == 2
                    # determine filename and modified status
                    line =~ /^#\s*([\w]+):\s*([\w\/\.\-]+)/

                    # tracked and modified
                    if $1 == 'modified'
                        modified.push $2

                    # tracked and deleted
                    elsif $1 == 'deleted'
                        deleted.push $2
                    end
                end
            end

            # make sure untracked files are marked as added
            if line =~ /Untracked files:/
                tracked = 1
            elsif line =~ /Changes not staged for commit:/ || line =~ /Changes to be committed:/
                tracked = 2
            end
        end

        return {
            :added => added,
            :deleted => deleted,
            :modified => modified
        }
    end

    # warp to a specific version
    def warp r = nil
        # save current state and determine revision to warp to
        revision = super r
        if revision
            `git checkout #{revision[:id]} -f > /dev/null 2> /dev/null`
        end
    end
end
