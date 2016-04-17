require 'net/http'
require 'json'

module Argus
  module SlackNotifier
    def notify(message, color = '#808080')
      uri = URI.parse(ENV['SLACK_WEBHOOK'])

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(
        payload: {
          attachments: [
            {
              text:      message,
              color:     color.to_s,
              mrkdwn_in: %w[ text ],  #allow link formatting in attachment
            }
          ]
        }.to_json
      )

      http.request(request)
    end
  end
end