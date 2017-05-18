require 'aws-sdk'
require 'base64'

module Argus
  class Runner
    include Ecr

    ## override notifier if setup for Slack ...
    prepend SlackNotifier if ENV.has_key?('SLACK_WEBHOOK')

    ## ... else notify stdout
    def notify(message, color = nil)
      puts message
    end

    def symbolize_keys(hash)
      Hash[ hash.map { |k,v| [ k.to_sym, v ] }]
    end

    ## return image tag, or make it out of:
    ## repo:branch with / changed to - in branch;
    ## prepend registry if none given
    def image_name(registry, msg)
      name = msg[:tag] || (msg[:repo] + ':' + msg[:branch].gsub('/', '-'))
      if name.include?('/')
        name
      else
        "#{registry}/#{name}"
      end
    end

    def initialize(msg)
      msg = symbolize_keys(msg)
      puts "Received message: #{msg}"

      ## set default
      msg[:branch] ||= 'master'

      ## make working directory
      dir = File.join(ENV.fetch('ARGUS_HOME', '/tmp'), msg[:org], msg[:repo])
      FileUtils.mkdir_p(dir)

      ## github repo to get
      git = Git.new(msg[:org], msg[:repo], msg[:branch], msg.fetch(:sha, nil))

      ## authenticate to registry
      registry = authenticate_ecr

      ## docker image to build
      img = Image.new(image_name(registry, msg))

      Dir.chdir(dir) do
        img.pull              # pull some layers to speed up the build
        git.pull              # get the git repo
        raise ArgusError, "git sha not found: #{git}" unless git.sha

        options = msg.fetch(:build_options, {})
        img.build!(options) # build docker image
        raise ArgusError, 'docker build failed' unless img.is_ok?

        short_sha = git.sha.slice(0,7) # human-readable sha for messages

        notify("build complete for #{img} #{short_sha} (#{img.build_time.round}s)", :good)

        img.tag!(git.sha)       # tag the image
        img.push(git.sha)       # push to registry
        notify("push complete for #{img} #{short_sha} (#{img.push_time.round}s)", :good)
      end

      ## ensure image is in ECR with all tags
      img.image.info['RepoTags'].each do |rtag|
        ecr_exists?(rtag) or raise ArgusError, "Not found in ECR: #{rtag}"
      end
    rescue ArgusError => e
      notify(e.message, :danger)
      raise # re-raise for shoryuken to delete failed job
    end
  end
end