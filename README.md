# Argus

Extremely simple ruby daemon to build docker images and push them to
[AWS Elastic Container Registry](https://aws.amazon.com/ecr/).

Features:

- does one thing well (kinda)
- queue builds with SQS messages
- built-in ECR authentication
- can notify [Slack](https://slack.com/) of build details

The primary goal of this project is simplicity. It should be easy to
adapt to your exact image-building needs.

Argus is implemented as a shoryuken
worker. [Shoryuken](https://github.com/phstc/shoryuken) is a super
efficient AWS SQS thread based message processor.

## Quick-start

You will need:

- AWS credentials set, either with the usual environment variables or
  with a credentials file
- a github repo to build, and access to it, with ssh keys or
  `GITHUB_TOKEN`
- a repository created on ECR to push the docker image once built

Create an SQS queue called `argus`, then:

```
gem install argus-builder
argus-send rlister/argus:master  # replace with your github repo
argus-worker
```

## Installation

Install via ruby gems:

```
gem install argus-builder
```

or clone from git:

```
git clone rlister/argus
```

## Usage

`argus` is implemented as a
[Shoryuken](https://github.com/phstc/shoryuken) worker. It will poll
SQS for build messages, and run:

- git pull
- docker build
- docker push to ECR

Set the following environment variables to configure `argus`:

```
export GITHUB_TOKEN=xxx
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export ARGUS_QUEUE=my_queue
export ARGUS_HOME=/data
export SLACK_WEBHOOK=https://hooks.slack.com/services/xxx
```

Git repositories will be kept in the `ARGUS_HOME` directory (default `/tmp`).

Send a message to your queue:

```
argus-send org/repo:branch
```

Start the worker daemon to start consuming the queue:

```
argus-worker
```

## Build procedure

Argus builds images as follows. Examine and modify `lib/argus/git.rb`
and `lib/argus/docker.git` to change exact behaviour.

1. `git clone` a new github repo, or `git checkout` an existing one
1. authenticate to elastic container registry using provided credentials
1. attempt to `docker pull` existing image from repo to take advantage of cache
1. `docker build` the new image
1. `docker push` to the registry
1. notify Slack

## Message format

Implementation of your own message sender is simple, using any library
that can push a JSON object to SQS.

Example:

```
require 'aws-sdk'

msg = {
  org:    org,
  repo:   repo,
  branch: branch
}

sqs = Aws::SQS::Client.new
sqs.send_message(
  queue_url:    sqs.get_queue_url(queue_name: myqueue).queue_url,
  message_body: msg.to_json
)
```

## Shoryuken options

`argus` is a simple shoryuken worker. You can run it directly from the
argus repository with any shoryuken options you like:

```
bundle exec shoyruken -r ./lib/argus/worker.rb -q myqueue -c 1
```

It is advisable to run a single thread (concurrency of 1) per host, as
argus shares build directory between builds, to take advantage of git
and docker caching.

Writing your own shoryuken worker class is straightforward, see
`lib/argus/worker.rb` for details.

## Docker

Argus runs happily inside a docker container, but needs access to a
docker daemon to trigger builds. For example, using local socket:

```
docker run \
  --name argus \
  -e GITHUB_TOKEN \
  -e AWS_REGION \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e ARGUS_QUEUE \
  -e ARGUS_HOME=/data \
  -e SLACK_WEBHOOK \
  -v /data:/data \
  -v /var/run/docker.sock:/var/run/docker.sock \
  rlister/argus:latest
```

You will probably want to bind-mount the `ARGUS_HOME` data directory,
to preserve git repos between container restarts. This avoids cloning
the entire repos on the next build.

## Development

After checking out the repo, run `bin/setup` to install
dependencies. You can also run `bin/console` for an interactive prompt
that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will
create a git tag for the version, push git commits and tags, and push
the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/argus. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected
to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of
conduct.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).