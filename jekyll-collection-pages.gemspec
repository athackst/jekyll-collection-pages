# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'jekyll-collection-pages'
  spec.version       = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.authors       = ['allison@allisonthackston.com']

  spec.summary       = 'A Jekyll plugin for generating tag pages for multiple collections'
  spec.description   = 'This Jekyll plugin allows you to generate tag pages for multiple collections, with support for pagination.'
  spec.homepage      = 'https://github.com/athackst/jekyll-collection-pages'
  spec.license       = 'MIT'
  spec.metadata       = {
    'source_code_uri' => spec.homepage,
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'rubygems_mfa_required' => 'true'
  }
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'jekyll', '>= 3.7', '< 5.0'
end
