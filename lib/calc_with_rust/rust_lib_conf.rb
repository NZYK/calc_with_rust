module CalcWithRust
  module RustLibConf
    RUST_DIR = File.expand_path('../../rust/calculator', __dir__)
    RUST_LIB_FILE_NAME = case RUBY_PLATFORM
                         when /darwin/ then 'libcalculator.dylib'
                         when /win32|mingw/ then 'libcalculator.dll'
                         else 'libcalculator.so'
                         end
    RUST_LIB_FILE_PATH = File.join(RUST_DIR, 'target', 'release', RUST_LIB_FILE_NAME)
  end
end
