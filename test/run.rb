#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs the iOS codegen test suite:
#   ruby test/run.rb

# read_dot_env consults /tmp/envfile - a machine-global path - before ENVFILE. A copy left behind
# by a real build would silently select the env file for every test here, so refuse to run rather
# than report a result that describes that file instead of the fixtures.
if File.exist?('/tmp/envfile')
  warn <<~MESSAGE
    Refusing to run: /tmp/envfile exists.

    The env resolution under test reads that path before ENVFILE, so its contents would override
    every fixture in this suite. It is written by Xcode scheme pre-actions; remove it and re-run:

        rm /tmp/envfile
  MESSAGE
  exit 1
end

require 'minitest/autorun'

Dir[File.join(__dir__, '*_test.rb')].sort.each { |test| require test }
