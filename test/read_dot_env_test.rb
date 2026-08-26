# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'

require_relative '../ios/ReactNativeConfig/ReadDotEnv'

# read_dot_env reports which env file it used, so that an empty Config can be explained rather
# than merely observed. These cover the reporting, and pin the resolution behaviour it describes.
class ReadDotEnvTest < Minitest::Test
  def setup
    @previous_envfile = ENV['ENVFILE']
    ENV.delete('ENVFILE')
    @root = Dir.mktmpdir('rnc-read-dot-env')
  end

  def teardown
    ENV['ENVFILE'] = @previous_envfile
    FileUtils.remove_entry(@root) if @root && File.directory?(@root)
  end

  def write_env(name, contents)
    path = File.join(@root, name)
    File.write(path, contents)
    path
  end

  # read_dot_env is chatty by design - the build log is where its findings normally surface.
  def read(root = @root)
    result = nil
    capture_io { result = read_dot_env(root) }
    result
  end

  def test_reports_the_file_it_read_when_the_env_file_exists
    expected = write_env('.env', "API_URL=https://example.com\n")

    dotenv, _custom_env, resolution = read

    assert_equal({ 'API_URL' => 'https://example.com' }, dotenv)
    assert resolution[:found], 'expected the env file to be reported as found'
    assert_equal expected, resolution[:path]
  end

  def test_reports_not_found_and_names_every_path_tried_when_no_env_file_exists
    dotenv, _custom_env, resolution = read

    assert_empty dotenv
    refute resolution[:found], 'expected the missing env file to be reported as not found'
    assert_nil resolution[:path]
    refute_empty resolution[:tried], 'a miss must name the paths it tried'
    assert_includes resolution[:tried], File.join(@root, '.env')
  end

  # The regression this suite exists for: a missing env file is not a build failure, so the only
  # signal that something is wrong is this flag reaching the generated source.
  def test_a_missing_env_file_does_not_raise
    dotenv, _custom_env, resolution = read

    assert_empty dotenv
    refute resolution[:found]
  end

  def test_paths_tried_are_ordered_and_free_of_duplicates
    _dotenv, _custom_env, resolution = read

    assert_equal resolution[:tried].uniq, resolution[:tried], 'tried paths must be deduplicated'
    assert_equal File.join(@root, '.env'), resolution[:tried].first,
                 'the project-root candidate is tried first'
  end

  def test_envfile_selects_the_named_file_and_is_reported_as_the_source
    write_env('.env', "API_URL=default\n")
    expected = write_env('.env.staging', "API_URL=staging\n")
    ENV['ENVFILE'] = '.env.staging'

    dotenv, _custom_env, resolution = read

    assert_equal 'staging', dotenv['API_URL']
    assert resolution[:found]
    assert_equal expected, resolution[:path]
  end

  # Pins behaviour this change deliberately left alone: ENVFILE naming a file that does not exist
  # silently falls back to .env. The reported path is what makes that fallback visible.
  def test_envfile_naming_a_missing_file_falls_back_to_dot_env_and_says_so
    fallback = write_env('.env', "API_URL=default\n")
    ENV['ENVFILE'] = '.env.does-not-exist'

    dotenv, _custom_env, resolution = read

    assert_equal 'default', dotenv['API_URL']
    assert resolution[:found]
    assert_equal fallback, resolution[:path],
                 'the reported path must be the file the values actually came from'
  end

  def test_parses_quotes_comments_blank_lines_export_and_empty_values
    write_env('.env', <<~ENVFILE)
      # a comment
      PLAIN=value

      QUOTED="has space"
      SINGLE='single'
      export EXPORTED=exported
      EMPTY=
    ENVFILE

    dotenv, = read

    assert_equal 'value', dotenv['PLAIN']
    assert_equal 'has space', dotenv['QUOTED']
    assert_equal 'single', dotenv['SINGLE']
    assert_equal 'exported', dotenv['EXPORTED']
    assert_equal '', dotenv['EMPTY']
    refute dotenv.key?('# a comment')
  end

  def test_a_malformed_line_still_aborts_the_build
    write_env('.env', "this is not a valid entry\n")

    assert_raises(SystemExit) { capture_io { read_dot_env(@root) } }
  end
end
