# frozen_string_literal: true

require_relative 'calc_with_rust/version'
require_relative 'calc_with_rust/rust_lib_conf'

module CalcWithRust
  class Error < StandardError; end

  module Ruby
    # 素数探索：エラトステネスのふるい
    def self.primes(n)
      return [] if n < 2

      # 素数判定用の配列を用意 初期値は全てtrue(素数と仮定)
      num_arr = Array.new(n + 1, true)
      # 0と1は素数ではないのでfalseにする
      num_arr[0] = num_arr[1] = false
      # ふるいにかける基準値はnの平方根まで。
      # 例えば　n=100の場合、10を素数と仮定した場合に10 * 10 からふるいにかけるが、このとき最初の値が範囲の最大値となるため。
      limit = Math.sqrt(n).to_i

      (2..limit).each do |i|
        next unless num_arr[i]

        # iがtrue(素数)の場合、iの倍数は素数ではないのでfalseにする。
        # i*2 ~ i*(i-1) まではすでにふるいにかけられているので i*i からスタート
        (i * i).step(n, i) { |j| num_arr[j] = false }
      end
      num_arr.each_index.select { |i| num_arr[i] }
    end
  end

  module Rust
    require 'ffi'

    extend FFI::Library
    ffi_lib CalcWithRust::RustLibConf::RUST_LIB_FILE_PATH

    def self.primes(n)
      out_len_ptr = FFI::MemoryPointer.new(:size_t)
      out_ptr = calc_primes(n, out_len_ptr)

      len = out_len_ptr.read_ulong
      primes_array = out_ptr.read_array_of_ulong(len)

      free_primes_array(out_ptr, len)
      primes_array
    end

    private

    attach_function :calc_primes, %i[size_t pointer], :pointer
    attach_function :free_primes_array, %i[pointer size_t], :void
  end
end
