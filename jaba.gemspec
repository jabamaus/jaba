require_relative 'lib/jaba/version'

Gem::Specification.new do |spec|
  spec.name          = "jaba"
  spec.version       = JABA::VERSION
  spec.authors       = ["jabamaus"]
  spec.email         = ["49597106+jabamaus@users.noreply.github.com"]

  spec.summary       = "JABA cross platform build file generator"
  spec.description   = "Generates Visual Studio and Xcode projects"
  #spec.homepage      = ""
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  #spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  spec.files         = ["lib/**/*"]
  spec.bindir        = "exe"
  spec.executables   = "jaba"
  spec.require_paths = ["lib"]
end
