# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'

# RNCConfig.m is what the user actually sees: it turns an empty config into a message naming the
# file that was looked for. Compiled and run for real, because the behaviour under test is the
# logged output and the once-only guard, neither of which is visible by reading the source.
class RNCConfigDiagnosticTest < Minitest::Test
  SOURCE_DIR = File.expand_path('../ios/ReactNativeConfig', __dir__)

  HARNESS = <<~OBJC
    #import <Foundation/Foundation.h>
    #import "RNCConfig.h"
    int main() { @autoreleasepool {
      NSDictionary *first = [RNCConfig env];
      [RNCConfig env];                 // a second read must not log again
      [RNCConfig envFor:@"API_URL"];   // nor must a lookup through envFor:
      printf("COUNT=%lu\\n", (unsigned long)first.count);
    } return 0; }
  OBJC

  def setup
    skip 'clang is unavailable' unless system('which clang > /dev/null 2>&1')
    skip 'Foundation is unavailable (macOS only)' unless RUBY_PLATFORM.include?('darwin')
    @dir = Dir.mktmpdir('rnc-objc')
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && File.directory?(@dir)
  end

  # Builds RNCConfig.m against a given GeneratedDotEnv.m and returns what it logged.
  # NSLog writes to stderr.
  def run_with(generated)
    FileUtils.cp(File.join(SOURCE_DIR, 'RNCConfig.m'), @dir)
    FileUtils.cp(File.join(SOURCE_DIR, 'RNCConfig.h'), @dir)
    File.write(File.join(@dir, 'GeneratedDotEnv.m'), generated)
    File.write(File.join(@dir, 'main.m'), HARNESS)

    binary = File.join(@dir, 'app')
    _out, compile_err, compile_status = Open3.capture3(
      'clang', '-fobjc-arc', '-Werror', '-framework', 'Foundation', '-I', @dir,
      File.join(@dir, 'RNCConfig.m'), File.join(@dir, 'main.m'), '-o', binary
    )
    assert compile_status.success?, "RNCConfig.m failed to compile:\n#{compile_err}"

    stdout, stderr, status = Open3.capture3(binary)
    assert status.success?, 'the harness should exit cleanly'
    [stdout, stderr]
  end

  def generated_source(entries, found:, path:)
    <<~OBJC
      #define DOT_ENV @{ #{entries} };
      #define RNC_DOT_ENV_FOUND #{found}
      #define RNC_DOT_ENV_PATH @"#{path}"
    OBJC
  end

  def test_says_nothing_when_the_config_has_values
    stdout, stderr = run_with(
      generated_source('@"API_URL":@"https://example.com"', found: 1, path: '/proj/.env')
    )

    assert_includes stdout, 'COUNT=1'
    refute_includes stderr, 'react-native-config',
                    'a populated config must not warn'
  end

  def test_names_the_file_and_the_causes_when_no_env_file_was_found
    _stdout, stderr = run_with(generated_source('', found: 0, path: '/proj/.env.staging'))

    assert_includes stderr, 'no env file was found'
    assert_includes stderr, '/proj/.env.staging'
    assert_includes stderr, 'ENVFILE'
    assert_includes stderr, 'Config codegen'
  end

  def test_distinguishes_a_file_that_was_read_but_yielded_nothing
    _stdout, stderr = run_with(generated_source('', found: 1, path: '/proj/.env'))

    assert_includes stderr, 'was read from /proj/.env'
    assert_includes stderr, 'no variables were parsed out of it'
    refute_includes stderr, 'no env file was found',
                    'a file that was found must not be reported as missing'
  end

  def test_warns_only_once_however_many_times_the_config_is_read
    _stdout, stderr = run_with(generated_source('', found: 0, path: '/proj/.env'))

    assert_equal 1, stderr.scan('[react-native-config]').length,
                 'the warning must not repeat on every read'
  end

  # A GeneratedDotEnv.m left by an older version defines DOT_ENV alone. It must still compile,
  # and must not be mistaken for a missing env file when it carries values.
  def test_a_generated_file_from_an_older_version_still_compiles_and_does_not_warn
    stdout, stderr = run_with(%(#define DOT_ENV @{ @"API_URL":@"https://example.com" };\n))

    assert_includes stdout, 'COUNT=1'
    refute_includes stderr, 'react-native-config',
                    'a stale generated file carrying values must not produce a false positive'
  end

  # The placeholder committed to the repo stands in until the codegen build phase runs. If that
  # phase never runs, this is what compiles - and it must report itself as ungenerated.
  def test_the_committed_placeholder_reports_itself_as_ungenerated
    _stdout, stderr = run_with(File.read(File.join(SOURCE_DIR, 'GeneratedDotEnv.m')))

    assert_includes stderr, 'no env file was found'
    assert_includes stderr, 'Config codegen'
  end
end
