# encoding: ASCII-8BIT

require "ffi"

module Solace
  module Utils
    module Curve25519Dalek
      extend FFI::Library

      # Load the native library
      #
      # If the platform is not supported, a RuntimeError is raised. The native library
      # can be built by compiling the Rust code in the root/ext directory.
      #
      # @return [String] The path to the native library
      # @raise [RuntimeError] If the platform is not supported
      libfile = case RUBY_PLATFORM
      when /linux/ then "libcurve25519_dalek.so"
      when /darwin/ then "libcurve25519_dalek.dylib"
      when /mingw|mswin/ then "curve25519_dalek.dll"
      else raise "Unsupported platform"
      end

      # The path to the native library
      #
      # @return [String] The path to the native library
      LIB_PATH = File.expand_path(libfile, __dir__)
      
      # Load the native library
      ffi_lib LIB_PATH

      # Attach the native function
      #
      # @return [FFI::Function] The native function
      attach_function :is_on_curve, [:pointer], :int

      # Checks if a point is on the curve
      # 
      # @param bytes [Array] The bytes to check
      # @return [Boolean] True if the point is on the curve, false otherwise
      # @raise [ArgumentError] If the input is not 32 bytes
      def self.on_curve?(bytes)
        raise ArgumentError, "Must be 32 bytes" unless bytes.bytesize == 32

        FFI::MemoryPointer.new(:uchar, 32) do |ptr|
          ptr.put_bytes(0, bytes) # double check this packs to 32 bytes
          result = Curve25519Dalek.is_on_curve(ptr)
          
          case result
          when 1 then return true
          when 0 then return false
          else raise "Unexpected return code from native is_on_curve: #{result}"
          end
        end
      end
    end
  end
end
