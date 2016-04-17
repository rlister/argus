require 'argus'

module Argus
  class Worker
    include Shoryuken::Worker

    shoryuken_options queue: ENV.fetch('ARGUS_QUEUE', 'argus')
    shoryuken_options body_parser: :json
    shoryuken_options auto_delete: true

    ## prevent timeout on docker api operations (e.g. long bundle install during build)
    Excon.defaults[:write_timeout] = ENV.fetch('DOCKER_WRITE_TIMEOUT', 1000)
    Excon.defaults[:read_timeout]  = ENV.fetch('DOCKER_READ_TIMEOUT',  1000)

    def perform(_, body)
      Argus::Runner.new(body)
    end
  end
end