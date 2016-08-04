require 'docker'
require 'benchmark'

module Argus
  class Image
    attr_reader :repo, :branch, :build_time, :image, :push_time

    def initialize(name)
      @repo, @branch = name.split(':')
    end

    def to_s
      "#{repo}:#{branch}"
    end

    ## make a heroic attempt to pre-load as many layers as we can
    def pull
      [branch, :master, :latest].each do |tag|
        puts "Attempting to pull #{repo}:#{tag}"
        begin
          attempt = Docker::Image.create(fromImage: "#{repo}:#{tag}")
        rescue Docker::Error::ArgumentError
          puts "failed pull"
        rescue Docker::Error::NotFoundError
          puts "image not found"
        end
        break if attempt.is_a?(Docker::Image)
      end
    end

    ## build docker image, with optional API /build params
    def build!(options = {})
      puts "building #{self}"

      @build_time = Benchmark.realtime do
        @image = Docker::Image.build_from_dir('.', options) do |chunk|
          chunk.split(/[\r\n]+/).each do |line| # latest docker jams multiple streams into chunk
            begin
              stream = JSON.parse(line)['stream']
              unless (stream.nil? || stream.match(/^[\s\.]+$/)) # very verbose about build progress
                puts stream.chomp
              end
            rescue => e         # be robust to json parse errors
              puts e.message
            end
          end
        end
      end
    end

    ## check if image built ok
    def is_ok?
      image.is_a?(Docker::Image)
    end

    ## tag with both sha and branch
    def tag!(sha)
      [sha, branch].map do |tag|
        puts "tagging #{repo}:#{tag}"
        image.tag(repo: repo, tag: tag, force: true)
      end
    end

    ## push image and all tags to registry
    def push(sha)
      @push_time = Benchmark.realtime do
        [sha, branch].each do |tag|
          puts "pushing #{repo}:#{tag}"
          image.push(nil, tag: tag)
        end
      end
    end

  end
end