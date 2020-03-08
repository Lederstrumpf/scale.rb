# frozen_string_literal: true

require 'scale'
require_relative './types_for_test.rb'
require 'ffi'

module Rust
  extend FFI::Library
  ffi_lib 'target/debug/libvector_ffi.' + FFI::Platform::LIBSUFFIX
  attach_function :byte_string_literal_parse_u64, %i[pointer int uint64], :bool
  attach_function :byte_string_literal_parse_u8, %i[pointer int uint8], :bool
end

parse_u64 = proc { |vec_c, value|
  Rust.byte_string_literal_parse_u64(vec_c, vec_c.size, value)
}

parse_u8 = proc { |vec_c, value|
  Rust.byte_string_literal_parse_u8(vec_c, vec_c.size, value)
}

def check_against_specification(encoded, expectation)
  describe do
    it 'encoding should match specification' do
      expect(encoded).to eql(expectation)
    end
  end
end

def check_against_value(ffi_success)
  describe do
    it 'Rust implementation should decode to expected value' do
      expect(ffi_success).to eql(true)
    end
  end
end

def parse_via_ffi(value, encoding, ffi_function, expectation)
  encoded = encoding.new(value).encode
  check_against_specification(encoded, expectation)
  puts encoded
  vec = Scale::Bytes.new('0x' + encoded).bytes
  puts vec

  vec_c = FFI::MemoryPointer.new(:int8, vec.size)
  vec_c.write_array_of_int8 vec
  ffi_success = ffi_function.call(vec_c, value)
  check_against_value(ffi_success)
end

parse_via_ffi(14_294_967_296, Scale::Types::U64, parse_u64, '00e40b5403000000')

parse_via_ffi(69, Scale::Types::U8, parse_u8, '45')
