#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'ReadDotEnv'

envs_root = ARGV[0]
config_output = ARGV[1]
puts "reading env file from #{envs_root} and writing .config to #{config_output}"

dotenv, custom_env = read_dot_env(envs_root)

dotenv_xcconfig = dotenv.map { |k, v| %(#{k}=$()#{v.gsub(/\/\//, "/$()/")}) }.join("\n")
File.open(config_output, 'w') { |f| f.puts dotenv_xcconfig }
