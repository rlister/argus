require 'base64'

module Argus
  module Lambda

    def lambda
      @_lambda ||= Aws::Lambda::Client.new
    end

    def lambda_invoke(function, msg)
      lambda.invoke(
        function_name: function,
        log_type: :Tail,
        payload: msg.to_json
      ).tap do |response|
        puts Base64.decode64(response.log_result)
      end
    end

  end
end