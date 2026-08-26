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

# Selecting the env file without copying one over another: ENVFILE can reference build settings,
# so a single setting serves every configuration, and a fallback is reported rather than silent.
class ReadDotEnvSelectionTest < Minitest::Test
  TRACKED = %w[ENVFILE CONFIGURATION PLATFORM_NAME].freeze

  def setup
    @previous = TRACKED.to_h { |name| [name, ENV[name]] }
    TRACKED.each { |name| ENV.delete(name) }
    @root = Dir.mktmpdir('rnc-selection')
  end

  def teardown
    @previous.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
    FileUtils.remove_entry(@root) if @root && File.directory?(@root)
  end

  def write_env(name, contents = "API_URL=#{name}\n")
    path = File.join(@root, name)
    File.write(path, contents)
    path
  end

  def read
    result = nil
    output = capture_io { result = read_dot_env(@root) }
    [result, output.join]
  end

  def test_expands_a_build_setting_in_parentheses
    expected = write_env('.env.Release-Staging')
    ENV['CONFIGURATION'] = 'Release-Staging'
    ENV['ENVFILE'] = '.env.$(CONFIGURATION)'

    (dotenv, _custom, resolution), = read

    assert_equal '.env.Release-Staging', dotenv['API_URL']
    assert_equal expected, resolution[:path]
    refute resolution[:fell_back], 'the requested file existed, so nothing was fallen back to'
  end

  def test_expands_a_build_setting_in_braces_and_bare_form
    write_env('.env.Debug')
    ENV['CONFIGURATION'] = 'Debug'

    ENV['ENVFILE'] = '.env.${CONFIGURATION}'
    (_dotenv, _custom, braces), = read
    assert_equal File.join(@root, '.env.Debug'), braces[:path]

    ENV['ENVFILE'] = '.env.$CONFIGURATION'
    (_dotenv, _custom, bare), = read
    assert_equal File.join(@root, '.env.Debug'), bare[:path]
  end

  def test_expands_more_than_one_build_setting
    write_env('.env.Debug.iphonesimulator')
    ENV['CONFIGURATION'] = 'Debug'
    ENV['PLATFORM_NAME'] = 'iphonesimulator'
    ENV['ENVFILE'] = '.env.$(CONFIGURATION).$(PLATFORM_NAME)'

    (_dotenv, _custom, resolution), = read

    assert_equal File.join(@root, '.env.Debug.iphonesimulator'), resolution[:path]
  end

  def test_reports_a_build_setting_that_is_not_set
    write_env('.env')
    ENV['ENVFILE'] = '.env.$(CONFIGURATION)'

    _result, output = read

    assert_includes output, 'CONFIGURATION'
    assert_includes output, 'resolved to nothing'
  end

  # The #853 trap: a configured ENVFILE that names a missing file quietly used .env instead, so a
  # correct-looking setup produced the wrong environment with nothing to show for it.
  def test_reports_falling_back_to_dot_env_when_envfile_is_missing
    write_env('.env', "API_URL=default\n")
    ENV['ENVFILE'] = '.env.production'

    (dotenv, _custom, resolution), output = read

    assert_equal 'default', dotenv['API_URL']
    assert resolution[:fell_back], 'the fallback must be recorded'
    assert_includes output, 'ENVFILE was set, but that file is missing'
    assert_includes output, '.env.production'
    assert_includes output, 'Falling back to'
  end

  def test_does_not_report_a_fallback_when_the_requested_file_exists
    write_env('.env', "API_URL=default\n")
    write_env('.env.production', "API_URL=production\n")
    ENV['ENVFILE'] = '.env.production'

    (dotenv, _custom, resolution), output = read

    assert_equal 'production', dotenv['API_URL']
    refute resolution[:fell_back]
    refute_includes output, 'ENVFILE was set, but that file is missing'
  end

  def test_does_not_report_a_fallback_when_envfile_was_never_set
    write_env('.env', "API_URL=default\n")

    (_dotenv, _custom, resolution), output = read

    assert_equal :default, resolution[:source]
    refute resolution[:fell_back]
    refute_includes output, 'ENVFILE was set'
  end

  def test_records_how_the_file_was_chosen
    write_env('.env')
    (_dotenv, _custom, default_selection), = read
    assert_equal :default, default_selection[:source]

    write_env('.env.production')
    ENV['ENVFILE'] = '.env.production'
    (_dotenv, _custom, explicit), = read
    assert_equal :envfile, explicit[:source]
    assert_equal '.env.production', explicit[:requested]
  end

  def test_an_absolute_envfile_path_is_used_as_given
    outside = Dir.mktmpdir('rnc-outside')
    absolute = File.join(outside, '.env.shared')
    File.write(absolute, "API_URL=shared\n")
    ENV['ENVFILE'] = absolute

    (dotenv, _custom, resolution), = read

    assert_equal 'shared', dotenv['API_URL']
    assert_equal absolute, resolution[:path]
    refute resolution[:fell_back]
  ensure
    FileUtils.remove_entry(outside) if outside && File.directory?(outside)
  end
end
