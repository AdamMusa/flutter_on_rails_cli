Gem::Specification.new do |spec|
  spec.name          = "flutter_on_rails"
  spec.version       = "0.1.0.alpha"
  spec.authors       = "Adam Moussa Ali"
  spec.email         = ["adammusaaly@gmail.com"]

  spec.summary       = "Flutter on Rails CLI"
  spec.description   = "Flutter on rails is the fastest way to bridge your web app with a Flutter-powered for cross plateform mobile and desktop app with ease and minimal changes, maximum freedom"
  spec.homepage      = "https://github.com/AdamMusa/flutter_on_rails_cli"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir["{bin,lib}/**/*", "LICENSE", "README.md"]
  spec.bindir        = "bin"
  spec.executables   = ["flutter_on_rails", "frails"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.2"
  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "yaml", "~> 0.2"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end 