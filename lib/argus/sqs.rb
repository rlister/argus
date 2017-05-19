module Argus
  module Sqs

    def sqs
      @_sqs ||= Aws::SQS::Client.new
    end

    ## turn queue name into URL if not already
    def sqs_get_url(queue)
      if queue =~ /\A#{URI::regexp}\z/
        queue
      else
        sqs.get_queue_url(queue_name: queue).queue_url
      end
    end

    def sqs_send(msg)
      sqs.send_message(
        queue_url:    sqs_get_url(msg[:sqs]),
        message_body: msg.to_json,
      )
    end

  end
end