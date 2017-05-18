module Argus
  module Ecr

    ## AWS client
    def ecr
      @_ecr ||= Aws::ECR::Client.new
    end

    ## authenticate to AWS ECR
    def authenticate_ecr
      ## get token and extract creds
      auth = ecr.get_authorization_token.authorization_data.first
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

    ## check image as reg/repo:tag exists in ECR
    def ecr_exists?(image)
      registry, repo, tag = image.split(/[\/:]/)
      ecr.batch_get_image(repository_name: repo, image_ids: [{image_tag: tag}]).images.any?
    end

  end
end