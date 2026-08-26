# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'

# BuildDotenvConfig.rb carries the outcome of the env lookup into the generated source, so that
# RNCConfig.m can tell "no env file was found" apart from "the file was empty" at runtime.
class BuildDotenvConfigTest < Minitest::Test
  SCRIPT = File.expand_path('../ios/ReactNativeConfig/BuildDotenvConfig.rb', __dir__)

  def setup
    @root = Dir.mktmpdir('rnc-build-root')
    @out = Dir.mktmpdir('rnc-build-out')
    @build_dir = Dir.mktmpdir('rnc-build-dir')
  end

  def teardown
    [@root, @out, @build_dir].each do |dir|
      FileUtils.remove_entry(dir) if dir && File.directory?(dir)
    end
  end

  def run_codegen(envfile: nil)
    env = { 'BUILD_DIR' => @build_dir }
    env['ENVFILE'] = envfile if envfile
    # ENVFILE is inherited from the surrounding shell otherwise, which would leak into the run.
    env['ENVFILE'] = nil if envfile.nil?
    stdout, stderr, status = Open3.capture3(env, 'ruby', SCRIPT, @root, @out)
    [stdout + stderr, status]
  end

  def generated
    File.read(File.join(@out, 'GeneratedDotEnv.m'))
  end

  def test_emits_values_and_marks_the_env_file_as_found
    File.write(File.join(@root, '.env'), "API_URL=https://example.com\nAPP_NAME=Demo\n")

    _output, status = run_codegen

    assert status.success?, 'codegen should succeed'
    assert_includes generated, '@"API_URL":@"https://example.com"'
    assert_includes generated, '@"APP_NAME":@"Demo"'
    assert_includes generated, '#define RNC_DOT_ENV_FOUND 1'
    assert_includes generated, %(#define RNC_DOT_ENV_PATH @"#{File.join(@root, '.env')}")
  end

  # The core regression guard. Before this change the generated file was an empty DOT_ENV and
  # nothing else, leaving the app with {} and no way to explain it.
  def test_marks_the_env_file_as_not_found_when_there_is_none
    _output, status = run_codegen

    assert status.success?, 'a missing env file must not fail the build'
    assert_includes generated, '#define DOT_ENV @{  };'
    assert_includes generated, '#define RNC_DOT_ENV_FOUND 0'
    refute_includes generated, '#define RNC_DOT_ENV_FOUND 1'
  end

  def test_names_a_candidate_path_even_when_nothing_was_found
    _output, = run_codegen

    assert_includes generated, %(#define RNC_DOT_ENV_PATH @"#{File.join(@root, '.env')}"),
                    'a miss must still report where it looked, so the message can name it'
  end

  def test_build_log_lists_every_path_tried_in_order
    output, = run_codegen

    assert_includes output, 'Missing .env file'
    assert_includes output, 'Tried, in order:'
    assert_includes output, File.join(@root, '.env')
    assert_includes output, 'The build will succeed and Config will be empty at runtime.'
  end

  def test_reports_the_env_file_selected_by_envfile
    File.write(File.join(@root, '.env'), "API_URL=default\n")
    File.write(File.join(@root, '.env.staging'), "API_URL=staging\n")

    _output, = run_codegen(envfile: '.env.staging')

    assert_includes generated, '@"API_URL":@"staging"'
    assert_includes generated, '#define RNC_DOT_ENV_FOUND 1'
    assert_includes generated, %(#define RNC_DOT_ENV_PATH @"#{File.join(@root, '.env.staging')}")
  end

  def test_still_writes_the_info_plist_preprocessor_header
    File.write(File.join(@root, '.env'), "API_URL=https://example.com\n")

    run_codegen

    header = File.read(File.join(@build_dir, 'GeneratedInfoPlistDotEnv.h'))
    assert_includes header, '#define API_URL  https://example.com'
  end

  def test_a_malformed_env_file_still_fails_the_build
    File.write(File.join(@root, '.env'), "this is not a valid entry\n")

    output, status = run_codegen

    refute status.success?, 'a malformed env file must abort'
    assert_includes output, 'Invalid entry in .env file'
  end

  def test_quotes_in_the_reported_path_are_escaped
    quoted_root = File.join(@root, 'a"quoted')
    FileUtils.mkdir_p(quoted_root)
    File.write(File.join(quoted_root, '.env'), "API_URL=ok\n")

    _stdout, _stderr, status = Open3.capture3(
      { 'BUILD_DIR' => @build_dir, 'ENVFILE' => nil }, 'ruby', SCRIPT, quoted_root, @out
    )

    assert status.success?
    assert_includes generated, '\\"quoted'
    refute_includes generated, %(@"#{quoted_root}"),
                    'an unescaped quote would produce a source file that does not compile'
  end

  def test_selects_the_env_file_for_the_build_configuration
    File.write(File.join(@root, '.env'), "API_URL=default\n")
    File.write(File.join(@root, '.env.Release-Staging'), "API_URL=staging\n")

    _stdout, _stderr, status = Open3.capture3(
      { 'BUILD_DIR' => @build_dir, 'CONFIGURATION' => 'Release-Staging',
        'ENVFILE' => '.env.$(CONFIGURATION)' },
      'ruby', SCRIPT, @root, @out
    )

    assert status.success?
    assert_includes generated, '@"API_URL":@"staging"'
    assert_includes generated, %(#define RNC_DOT_ENV_PATH @"#{File.join(@root, '.env.Release-Staging')}")
  end

  def test_warns_in_the_build_log_when_envfile_names_a_missing_file
    File.write(File.join(@root, '.env'), "API_URL=default\n")

    stdout, stderr, status = Open3.capture3(
      { 'BUILD_DIR' => @build_dir, 'ENVFILE' => '.env.production' },
      'ruby', SCRIPT, @root, @out
    )
    output = stdout + stderr

    assert status.success?, 'the fallback is not a build failure'
    assert_includes output, 'ENVFILE was set, but that file is missing'
    assert_includes output, '.env.production'
    assert_includes generated, '@"API_URL":@"default"'
  end
end
