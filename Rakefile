# frozen_string_literal: true

# Rakefile for running all Minitest tests in the test/ directory
require 'rake'
require 'rake/testtask'
require 'fileutils'

# Constants
GEM_NAME = 'solace'
BUILDS_DIR = 'builds'

PLATFORMS = {
  linux: {
    target: 'x86_64-unknown-linux-gnu',
    ext: 'so',
    rustlib: 'libcurve25519_dalek.so',
    path: 'lib/solace/utils/linux/libcurve25519_dalek.so'
  },
  windows: {
    target: 'x86_64-pc-windows-gnu',
    ext: 'dll',
    rustlib: 'curve25519_dalek.dll',
    path: 'lib/solace/utils/windows/curve25519_dalek.dll'
  },
  macos: {
    target: 'x86_64-apple-darwin',
    ext: 'dylib',
    rustlib: 'libcurve25519_dalek.dylib',
    path: 'lib/solace/utils/macos/libcurve25519_dalek.dylib'
  }
}.freeze

# Run all Minitest tests
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

# Bootstrap test environment
Rake::TestTask.new(:bootstrap) do |t|
  t.libs << 'test'
  t.pattern = 'test/bootstrap.rb'
  t.verbose = false
end

# Run all usecases
Rake::TestTask.new(:usecases) do |t|
  t.libs << 'test'
  # Get the named usecase from the CLI argument
  t.pattern = "test/usecases/#{ARGV[1] || '*'}.rb"
  t.verbose = false
end

# Build gem
task :build do
  FileUtils.mkdir_p(BUILDS_DIR)

  # Build gem in current directory
  sh "gem build #{GEM_NAME}.gemspec"

  # Move to builds directory
  gem_file = Dir["#{GEM_NAME}-*.gem"].first
  if gem_file
    FileUtils.mv(gem_file, BUILDS_DIR)
    puts "Moved #{gem_file} to #{BUILDS_DIR}/"
  end
end

# Install gem locally
task install: :build do
  gem_file = Dir["#{BUILDS_DIR}/#{GEM_NAME}-*.gem"].max_by { |f| File.mtime(f) }
  sh "gem install #{gem_file}"
end

# Publish gem to RubyGems.org
task publish: :build do
  gem_file = Dir["#{BUILDS_DIR}/#{GEM_NAME}-*.gem"].max_by { |f| File.mtime(f) }
  puts "Publishing #{gem_file} to RubyGems.org..."
  sh "gem push #{gem_file}"
end

# Compile the Rust library
task :compile do
  PLATFORMS.each do |name, cfg|
    puts "Building for #{name}..."
    sh "cargo build --manifest-path=ext/curve25519_dalek/Cargo.toml --release --target=#{cfg[:target]}"

    src = File.join('ext', 'curve25519_dalek', 'target', cfg[:target], 'release', cfg[:rustlib])
    dest = File.join(cfg[:path])

    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp(src, dest)
  end
end
