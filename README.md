# CalcWithRust

素数を数え上げるメソッドをRustを介して実行できるgemです

## Installation

インストール時に`rust`コードをバイナリにコンパイルするため、`cargo`が必要です。`bundle install`や`gem install`を実行する前に`cargo`を実行可能にしておいてください

Install the gem and add to the application's Gemfile by executing:

    $ bundle add calc_with_rust

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install calc_with_rust

## Usage

```ruby
require 'calc_with_rust'

max_size = 10
# execute with ruby code
CalcWithRust::Ruby.primes(max_size)
# => [2, 3, 5, 7]

# ececute with rust code
CalcWithRust::Rust.primes(max_size)
# => [2, 3, 5, 7]
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
