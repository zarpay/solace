# encoding: ASCII-8BIT

require "ffi"

module Solace
  module Utils
    module Curve25519Dalek
      extend FFI::Library

      libfile = case RUBY_PLATFORM
      when /linux/ then "libcurve25519_dalek.so"
      when /darwin/ then "libcurve25519_dalek.dylib"
      when /mingw|mswin/ then "curve25519_dalek.dll"
      else raise "Unsupported platform"
      end

      LIB_PATH = File.expand_path(libfile, __dir__)
      
      ffi_lib LIB_PATH

      attach_function :is_on_curve, [:pointer], :int

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
