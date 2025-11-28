# frozen_string_literal: true

require_relative 'lib/better_controller/version'

Gem::Specification.new do |spec|
  spec.name    = 'better_controller'
  spec.version = BetterController::VERSION
  spec.authors = ['alessiobussolari']
  spec.email   = ['alessio.bussolari@pandev.it']

  spec.summary               = 'A Ruby gem to enhance Rails controllers with additional functionality'
  spec.description           = 'BetterController provides tools and utilities to improve Rails controllers, making them more maintainable and feature-rich.'
  spec.homepage              = 'https://github.com/alessiobussolari/better_controller'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  # spec.metadata["allowed_push_host"] = "Set to your gem server 'https://example.com'"

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/alessiobussolari/better_controller'
  spec.metadata['changelog_uri']   = 'https://github.com/alessiobussolari/better_controller/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec            = File.basename(__FILE__)
  spec.files         = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'actionpack', '>= 6.0'
  spec.add_dependency 'activesupport', '>= 6.0'
  spec.add_dependency 'kaminari', '~> 1.2' # For pagination support
  spec.add_dependency 'zeitwerk', '~> 2.6'

  # Optional dependencies (for HtmlController with Turbo support)
  # spec.add_dependency 'turbo-rails', '>= 1.0'     # For Turbo Streams/Frames
  # spec.add_dependency 'view_component', '>= 3.0' # For ViewComponent rendering

  # Development dependencies
  spec.add_development_dependency 'rails', '>= 6.0'
  spec.add_development_dependency 'rspec-rails', '~> 5.0'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rails', '~> 2.19'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.22'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'turbo-rails', '>= 1.0'
  spec.add_development_dependency 'view_component', '>= 3.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
