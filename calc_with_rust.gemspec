# frozen_string_literal: true

require_relative 'lib/calc_with_rust/version'

Gem::Specification.new do |spec|
  spec.name = 'calc_with_rust'
  spec.version = CalcWithRust::VERSION
  spec.authors = ['NZYK']
  spec.email = ['nozuyukiwork@gmail.com']

  spec.summary = 'this gem provides a simple calculate method using Rust binary.'
  spec.description = "this gem provides a simple calculate method using Rust binary. It's uses FFI to call Rust binary from Ruby."
  spec.homepage = 'https://github.com/NZYK/calc_with_rust'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/NZYK/calc_with_rust'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
