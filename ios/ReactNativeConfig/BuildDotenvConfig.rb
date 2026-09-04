#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'ReadDotEnv'

envs_root = ARGV[0]
m_output_path = ARGV[1]
puts "reading env file from #{envs_root} and writing .m to #{m_output_path}"

# Allow utf-8 charactor in config value
# For example, APP_NAME=中文字符
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

dotenv, custom_env, resolution = read_dot_env(envs_root)
puts "read dotenv #{dotenv}"

def escape_objc_string(value)
  value.to_s.each_char.map do |char|
    case char
    when '"' then '\\"'
    when '\\' then '\\\\'
    when "\n" then '\\n'
    when "\r" then '\\r'
    when "\t" then '\\t'
    else
      if char.ord < 32 || char.ord == 127
        char.bytes.map { |byte| format('\\%03o', byte) }.join
      else
        char
      end
    end
  end.join
end

# create obj file that sets DOT_ENV as a NSDictionary
dotenv_objc = dotenv.map do |key, value|
  %(@"#{escape_objc_string(key)}":@"#{escape_objc_string(value.chomp)}")
end.join(',')

# Carry the outcome of the lookup into the binary alongside the values themselves. An empty
# DOT_ENV is otherwise indistinguishable at runtime from an env file that was never found, and
# the latter is by far the more common cause - see RNCConfig.m.
env_found = resolution && resolution[:found] ? 1 : 0
env_path = (resolution && (resolution[:path] || resolution[:tried].first)).to_s
env_path_objc = escape_objc_string(env_path)

template = <<EOF
  #define DOT_ENV @{ #{dotenv_objc} };
  #define RNC_DOT_ENV_FOUND #{env_found}
  #define RNC_DOT_ENV_PATH @"#{env_path_objc}"
EOF

# write it so that RNCConfig.m can return it
path = File.join(m_output_path, 'GeneratedDotEnv.m')
File.open(path, 'w') { |f| f.puts template }

# create header file with defines for the Info.plist preprocessor
info_plist_defines_objc = dotenv.map { |k, v| %Q(#define #{k}  #{v}) }.join("\n")

# write it so the Info.plist preprocessor can access it
path = File.join(ENV["BUILD_DIR"], "GeneratedInfoPlistDotEnv.h")
File.open(path, "w") { |f| f.puts info_plist_defines_objc }

puts "Wrote to #{path}"
