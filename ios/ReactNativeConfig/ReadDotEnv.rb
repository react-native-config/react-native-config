#!/usr/bin/env ruby
# frozen_string_literal: true

# Allow utf-8 charactor in config value
# For example, APP_NAME=中文字符
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# TODO: introduce a parameter which controls how to build relative path
def read_dot_env(envs_root)
  defaultEnvFile = '.env'
  puts "going to read env file from root folder #{envs_root}"

  # pick a custom env file if set
  if File.exist?('/tmp/envfile')
    custom_env = true
    file = File.read('/tmp/envfile').strip
  else
    custom_env = false
    file = ENV['ENVFILE'] || defaultEnvFile
  end

  # Every path considered, in order. A miss here is not a build failure - the app compiles and
  # receives an empty config - so the paths are recorded to be named in the message below and
  # handed to the runtime, rather than leaving "it is empty" as the only available symptom.
  tried = []
  resolved_path = nil

  dotenv = begin
    # https://regex101.com/r/cbm5Tp/1
    dotenv_pattern = /^(?:export\s+|)(?<key>[[:alnum:]_]+)\s*=\s*((?<quote>["'])?(?<val>.*?[^\\])\k<quote>?|)$/

    candidates = [
      File.expand_path(File.join(envs_root, file.to_s)),
      file.to_s,
      File.expand_path(File.join(envs_root, defaultEnvFile.to_s))
    ]
    # Last resort, preserving the previous behaviour: treat the default name as a path of its own.
    candidates << defaultEnvFile unless File.exist?(candidates[2])

    tried = candidates.uniq
    resolved_path = tried.find { |candidate| File.exist?(candidate) }
    raise Errno::ENOENT, tried.last if resolved_path.nil?

    raw = File.read(resolved_path)

    raw.split("\n").inject({}) do |h, line|
      m = line.match(dotenv_pattern)

      next h if line.nil? || line.strip.empty?
      next h if line.match(/^\s*#/)

      if m.nil?
        abort('Invalid entry in .env file. Please verify your .env file is correctly formatted.')
      end

      key = m[:key]
      # Ensure string (in case of empty value) and escape any quotes present in the value.
      val = m[:val].to_s.gsub('"', '\"')
      h.merge(key => val)
    end
    rescue Errno::ENOENT
      puts('**************************')
      puts('*** Missing .env file ****')
      puts('**************************')
      puts('Tried, in order:')
      tried.each { |candidate| puts("  - #{candidate}") }
      puts('The build will succeed and Config will be empty at runtime.')
      # set dotenv as an empty hash
      return [{}, false, { found: false, path: nil, tried: tried }]
  end

  [dotenv, custom_env, { found: !resolved_path.nil?, path: resolved_path, tried: tried }]
end
