require "argus/version"
require 'argus/git'
require 'argus/docker'
require 'argus/slack'
require 'argus/ecr'
require 'argus/sqs'
require 'argus/runner'

module Argus
  class ArgusError < StandardError
  end
end