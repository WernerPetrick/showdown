
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "showdown/version"

Gem::Specification.new do |spec|
  spec.name          = "showdown"
  spec.version       = Showdown::VERSION
  spec.authors       = ["Werner Petrick"]
  spec.email         = ["werpet@gmail.com"]

  spec.summary       = %q{Convert markdown presentations to PDF with custom layouts and themes.}
  spec.description   = %q{Showdown is a Ruby gem that converts markdown files into presentation PDFs using Prawn. It supports GitHub Flavored Markdown, custom slide delimiters, ERB layouts, speaker notes, and theming.}
  spec.homepage      = "https://github.com/wernerpetrick/showdown"
  spec.license       = "MIT"
  spec.required_ruby_version = '>= 2.7.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/wernerpetrick/showdown"
    spec.metadata["changelog_uri"] = "https://github.com/wernerpetrick/showdown/blob/main/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.17"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  
  # Runtime dependencies
  spec.add_dependency "prawn", "~> 2.4"
  spec.add_dependency "prawn-table", "~> 0.2"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "commonmarker", "~> 0.23"
  spec.add_dependency "rouge", "~> 4.0"
  spec.add_dependency "front_matter_parser", "~> 1.0"
  spec.add_dependency "nokogiri", "~> 1.15"
  spec.add_dependency "mini_magick", "~> 4.12"
  spec.add_dependency "base64", "~> 0.1"
  spec.add_dependency "prawn-svg", "~> 0.32"
  spec.add_dependency "listen", "~> 3.8"
end
