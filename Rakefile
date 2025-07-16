# frozen_string_literal: true

# Rakefile for running all Minitest tests in the test/ directory
require 'rake'
require 'rake/testtask'
require 'fileutils'

# Run all Minitest tests
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

# Run all usecases
Rake::TestTask.new(:usecases) do |t|
  t.libs << 'test'
  # Get the named usecase from the CLI argument
  t.pattern = "test/usecases/#{ARGV[1] || '*'}.rb"
  t.verbose = false
end

# Compile the Rust library
task :compile do
  sh 'cargo build --manifest-path=ext/curve25519_dalek/Cargo.toml --release'

  shared_lib = case RUBY_PLATFORM
               when /darwin/ then 'libcurve25519_dalek.dylib'
               when /linux/ then 'libcurve25519_dalek.so'
               when /mingw|mswin/ then 'curve25519_dalek.dll'
               else raise 'Unknown platform'
               end

  src = File.join('ext', 'curve25519_dalek', 'target', 'release', shared_lib)
  dest = File.join('lib', 'solace', 'utils', shared_lib)

  FileUtils.mkdir_p(File.dirname(dest))
  FileUtils.cp(src, dest)
end
