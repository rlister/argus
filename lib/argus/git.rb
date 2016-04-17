module Argus
  class Git
    attr_reader :org, :repo, :branch, :sha

    def initialize(org, repo, branch = 'master')
      @org    = org
      @repo   = repo
      @branch = branch
      @sha    = nil
    end

    def to_s
      "#{org}/#{repo}:#{branch}"
    end

    ## if we have a token, use https, else depend on ssh being set up
    def url
      if ENV['GITHUB_TOKEN']
        "https://#{ENV['GITHUB_TOKEN']}@github.com/#{org}/#{repo}.git"
      else
        "git@github.com:#{org}/#{repo}.git"
      end
    end

    ## is this dir a git repo?
    def is_inside_work_tree?
      %x[git rev-parse --is-inside-work-tree 2> /dev/null].chomp == 'true'
    end

    ## pull existing, or new git repo, and return sha
    def pull
      if is_inside_work_tree?
        checkout
      else
        clone
      end
      @sha = rev_parse                 # return SHA
    end

    ## checkout branch of an existing repo
    def checkout
      puts "repo exists, pulling #{self}"
      %x[git fetch && git checkout -f #{branch} && git reset --hard origin/#{branch}]
      raise ArgusError, "git checkout failed for #{self}" unless $? == 0
    end

    ## clone a new repo
    def clone
      puts "new repo, cloning #{self}"
      %x[git clone -b #{branch} #{url} .] # not found: clone it
      raise ArgusError, "git clone failed for #{self}" unless $? == 0
    end

    ## get current sha
    def rev_parse
      %x[git rev-parse #{branch} ].chomp
    end
  end
end