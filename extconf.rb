# frozen_string_literal: true

require 'mkmf'
require_relative 'lib/calc_with_rust.rb'

# cargoの存在チェック
abort 'Error: cargoが見つかりません。cargoがインストールされているか確認してください。' unless find_executable('cargo')

puts 'Rustコードをビルドしています...'
Dir.chdir(CalcWithRust::Rust::RUST_DIR) do
  abort 'Rustコードのビルドに失敗しました。' unless system('cargo build --release')
end

abort "ビルド成果物が見つかりません: #{lib_file_path}" unless File.exist?(CalcWithRust::Rust::RUST_LIB_FILE_PATH)
