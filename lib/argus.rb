require "argus/version"
require 'argus/git'
require 'argus/docker'
require 'argus/slack'
require 'argus/ecr'
require 'argus/runner'

module Argus
  class ArgusError < StandardError
  end
end