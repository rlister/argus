require 'aws-sdk'
require 'base64'

module Argus
  class Runner
    ## override notifier if setup for Slack ...
    prepend SlackNotifier if ENV.has_key?('SLACK_WEBHOOK')

    ## ... else notify stdout
    def notify(message, color = nil)
      puts message
    end

    def symbolize_keys(hash)
      Hash[ hash.map { |k,v| [ k.to_sym, v ] }]
    end

    ## authenticate to AWS ECR
    def authenticate_ecr
      ## get token and extract creds
      auth = Aws::ECR::Client.new.get_authorization_token.authorization_data.first
      username, password = Base64.decode64(auth.authorization_token).split(':')

      ## authenticate our docker client
      Docker.authenticate!(
        username:      username,
        password:      password,
        serveraddress: auth.proxy_endpoint
      )

      ## return registry name
      URI.parse(auth.proxy_endpoint).host
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

      ## make working directory
      dir = File.join(ENV.fetch('ARGUS_HOME', '/tmp'), msg[:org], msg[:repo])
      FileUtils.mkdir_p(dir)

      ## github repo to get
      git = Git.new(msg[:org], msg[:repo], msg[:branch])

      ## authenticate to registry
      registry = authenticate_ecr

      ## docker image to build
      img = Image.new(image_name(registry, msg))

      Dir.chdir(dir) do
        img.pull              # pull some layers to speed up the build
        git.pull              # get the git repo
        raise ArgusError, "git sha not found: #{git}" unless git.sha

        img.build!              # build docker image
        raise ArgusError, 'docker build failed' unless img.is_ok?

        notify("build complete for #{img} (#{img.build_time.round}s)", :good)

        img.tag!(git.sha)       # tag the image
        img.push(git.sha)       # push to registry

        notify("push complete for #{img} (#{img.push_time.round}s)", :good)
      end
    rescue ArgusError => e
      notify(e.message, :danger)
      raise # re-raise for shoryuken to delete failed job
    end
  end
end