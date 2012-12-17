require 'version50/scm'

class Git < SCM
    # configure the repo with user's info
    def config(name, email)
        # make sure repo exists
        self.init

        # configure git user
        `git config user.name "#{name}"`
        `git config user.email "#{email}"`
    end

    # create a new repo
    def init
        if !File.directory? '.git'
            `git init`
        end
    end

    def log
    end

    def pull
    end

    def push
    end

    # save a new version
    def save
        # prompt for commit message
        message = super

        # add all files and commit
        `git add --all`
        `git commit -m "#{message}"`
    end

    # view changed files
    def status
        # get status from SCM
        #status = `git status`
        status = "# On branch master\nChanges not staged for commit:\n#   (use \"git add <file>...\" to update what will be committed)\n#   (use \"git checkout -- <file>...\" to discard changes in working directory)\n#\n# modified:   file1\n#\n# Untracked files:\n#   (use \"git add <file>...\" to include in what will be committed)\n#\n# file2\nno changes added to commit (use \"git add\" and/or \"git commit -a\")"
        lines = status.split "\n"

        # iterate over each line in status
        tracked = 0
        added, modified, deleted = [], [], []
        lines.each do |line|
            # ignore git system lines
            if tracked > 0 && line && line !=~ /\(use "git add <file>\.\.\." to include in what will be committed\)/ &&
                    line !=~ /\(use "git add <file>\.\.\." to update what will be committed\)/ &&
                    line !=~ /\(use "git checkout -- <file>\.\.\." to discard changes in working directory\)/

                # untracked files, so mark as added
                if tracked == 1
                    # determine filename
                    line =~ /^#\s*([\w\/\.]+)/
                    if $1
                        added.push $1
                    end

                # currently-tracked files
                elsif tracked == 2
                    # determine filename and modified status
                    line =~ /^#\s*([\w]+):\s*([\w\/\.]+)/

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
end
