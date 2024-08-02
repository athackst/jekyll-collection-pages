Gem::Specification.new do |spec|
  spec.name          = "jekyll-collection-pages"
  spec.version       = "0.1.0"
  spec.authors       = ["allison@allisonthackston.com"]

  spec.summary       = "A Jekyll plugin for generating tag pages for multiple collections"
  spec.description   = "This Jekyll plugin allows you to generate tag pages for multiple collections, with support for pagination."
  spec.homepage      = "https://github.com/athackst/jekyll-collection-pages"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 3.7", "< 5.0"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
