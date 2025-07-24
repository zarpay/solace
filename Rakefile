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
  platforms = {
    linux:   { target: 'x86_64-unknown-linux-gnu', ext: 'so',     rustlib: 'libcurve25519_dalek.so',   path: 'lib/solace/utils/linux/libcurve25519_dalek.so' },
    windows: { target: 'x86_64-pc-windows-gnu',    ext: 'dll',    rustlib: 'curve25519_dalek.dll',    path: 'lib/solace/utils/windows/curve25519_dalek.dll' },
    # macos:   { target: 'x86_64-apple-darwin',      ext: 'dylib',  rustlib: 'libcurve25519_dalek.dylib', path: 'lib/solace/utils/macos/libcurve25519_dalek.dylib' }
  }

  platforms.each do |name, cfg|
    puts "Building for #{name}..."
    sh "cargo build --manifest-path=ext/curve25519_dalek/Cargo.toml --release --target=#{cfg[:target]}"

    src = File.join('ext', 'curve25519_dalek', 'target', cfg[:target], 'release', cfg[:rustlib])
    dest = File.join(cfg[:path])

    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp(src, dest)
  end
end
