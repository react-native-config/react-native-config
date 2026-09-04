#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs the iOS codegen test suite:
#   ruby test/run.rb

require 'minitest/autorun'

Dir[File.join(__dir__, '*_test.rb')].sort.each { |test| require test }
