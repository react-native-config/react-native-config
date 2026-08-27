#!/usr/bin/env ruby
# frozen_string_literal: true

# Allow utf-8 charactor in config value
# For example, APP_NAME=中文字符
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Expands build settings referenced in an env file name, so that a single setting can serve every
# configuration: ENVFILE=.env.$(CONFIGURATION) becomes .env.Release-Staging.
#
# Xcode expands $(FOO) itself when the value is a build setting, so this covers the cases where it
# does not - an ENVFILE exported from the shell, or a value passed through untouched. A reference
# to something unset expands to nothing and is reported, because being told that ".env." is
# missing explains very little on its own.
def expand_build_settings(value)
  unset = []
  expanded = value.gsub(/\$[({]([A-Za-z_][A-Za-z0-9_]*)[)}]|\$([A-Za-z_][A-Za-z0-9_]*)/) do
    name = Regexp.last_match(1) || Regexp.last_match(2)
    replacement = ENV[name]
    unset << name if replacement.nil? || replacement.empty?
    replacement.to_s
  end
  [expanded, unset]
end

# Which env file was asked for, and by whom. Kept separate from finding it so that a fallback can
# be reported against what was actually requested.
def select_env_file(default_env_file)
  if File.exist?('/tmp/envfile')
    return { name: File.read('/tmp/envfile').strip, source: :tmp_envfile, unset: [], custom: true }
  end

  requested = ENV['ENVFILE']
  if requested.nil? || requested.empty?
    return { name: default_env_file, source: :default, unset: [], custom: false }
  end

  expanded, unset = expand_build_settings(requested)
  { name: expanded, source: :envfile, unset: unset, custom: false, requested: requested }
end

# TODO: introduce a parameter which controls how to build relative path
def read_dot_env(envs_root)
  defaultEnvFile = '.env'
  puts "going to read env file from root folder #{envs_root}"

  selection = select_env_file(defaultEnvFile)
  file = selection[:name]
  custom_env = selection[:custom]

  if selection[:source] == :envfile
    puts "ENVFILE=#{selection[:requested]}"
    puts "  expands to #{file}" if selection[:requested] != file
    unless selection[:unset].empty?
      puts "  note: #{selection[:unset].uniq.join(', ')} " \
           'resolved to nothing. Outside Xcode these build settings are not set - pass the file ' \
           'name directly, or run the build through Xcode.'
    end
  end

  # Every path considered, in order. A miss here is not a build failure - the app compiles and
  # receives an empty config - so the paths are recorded to be named in the message below and
  # handed to the runtime, rather than leaving "it is empty" as the only available symptom.
  tried = []
  resolved_path = nil
  requested_paths = []

  dotenv = begin
    # https://regex101.com/r/cbm5Tp/1
    dotenv_pattern = /^(?:export\s+|)(?<key>[[:alnum:]_]+)\s*=\s*((?<quote>["'])?(?<val>.*?[^\\])\k<quote>?|)$/

    # The paths that satisfy what was asked for. Anything found beyond these is a fallback.
    requested_paths = [
      File.expand_path(File.join(envs_root, file.to_s)),
      file.to_s
    ]
    candidates = requested_paths + [File.expand_path(File.join(envs_root, defaultEnvFile.to_s))]
    # Last resort, preserving the previous behaviour: treat the default name as a path of its own.
    candidates << defaultEnvFile unless File.exist?(candidates[2])

    tried = candidates.uniq
    resolved_path = tried.find { |candidate| File.exist?(candidate) }
    raise Errno::ENOENT, tried.last if resolved_path.nil?

    # Falling back is not an error - it is long-standing behaviour and some setups rely on it for
    # a gitignored .env.local - but it is silent, and a build that quietly ships the wrong
    # environment is worse than one that fails. Say so where the person configuring it will look.
    if selection[:source] == :envfile && !requested_paths.include?(resolved_path)
      puts('**********************************************')
      puts('*** ENVFILE was set, but that file is missing ')
      puts('**********************************************')
      puts("Asked for: #{file}")
      puts('Not found at:')
      requested_paths.each { |candidate| puts("  - #{candidate}") }
      puts("Falling back to: #{resolved_path}")
      puts('The build will succeed using those values. If that is not what you want, correct')
      puts('ENVFILE or add the missing file.')
    end

    raw = File.read(resolved_path)

    raw.split("\n").each_with_object({}) do |line, h|
      m = line.match(dotenv_pattern)

      next if line.nil? || line.strip.empty?
      next if line.match(/^\s*#/)

      if m.nil?
        abort('Invalid entry in .env file. Please verify your .env file is correctly formatted.')
      end

      key = m[:key]
      # Ensure string (in case of empty value) and escape any quotes present in the value.
      val = m[:val].to_s.gsub('"', '\"')
      h[key] = val
    end
    rescue Errno::ENOENT
      puts('**************************')
      puts('*** Missing .env file ****')
      puts('**************************')
      puts('Tried, in order:')
      tried.each { |candidate| puts("  - #{candidate}") }
      puts('The build will succeed and Config will be empty at runtime.')
      # set dotenv as an empty hash
      return [{}, false, { found: false, path: nil, tried: tried, source: selection[:source],
                           requested: file, fell_back: false }]
  end

  [dotenv, custom_env, { found: true, path: resolved_path, tried: tried,
                         source: selection[:source], requested: file,
                         fell_back: selection[:source] == :envfile &&
                                    !requested_paths.include?(resolved_path) }]
end
