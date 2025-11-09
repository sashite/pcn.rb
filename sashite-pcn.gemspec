# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = "sashite-pcn"
  spec.version = ::File.read("VERSION.semver").chomp
  spec.author  = "Cyril Kato"
  spec.email   = "contact@cyril.email"
  spec.summary = "PCN (Portable Chess Notation) implementation for Ruby with comprehensive game record representation"

  spec.description = <<~DESC
    PCN (Portable Chess Notation) provides a comprehensive, JSON-based format for representing
    complete chess game records across variants. This gem implements the PCN Specification v1.0.0
    with a modern Ruby interface featuring immutable game objects and functional programming
    principles. PCN integrates the Sashité ecosystem specifications (PMN for moves, FEEN for
    positions, and SNN for style identification) to create a unified, rule-agnostic game recording
    system. Supports traditional single-variant games and cross-variant scenarios where players
    use different game systems, with complete metadata tracking including player information,
    tournament context, and game status. Perfect for game engines, database storage, game analysis
    tools, and archival systems requiring comprehensive game record management across diverse
    abstract strategy board games.
  DESC

  spec.homepage               = "https://github.com/sashite/pcn.rb"
  spec.license                = "MIT"
  spec.files                  = ::Dir["LICENSE.md", "README.md", "lib/**/*"]
  spec.required_ruby_version  = ">= 3.2.0"

  spec.add_dependency "sashite-cgsn", "~> 0.2"
  spec.add_dependency "sashite-feen", "~> 0.3"
  spec.add_dependency "sashite-pan", "~> 4.0"
  spec.add_dependency "sashite-snn", "~> 3.1"

  spec.metadata = {
    "bug_tracker_uri"       => "https://github.com/sashite/pcn.rb/issues",
    "documentation_uri"     => "https://rubydoc.info/github/sashite/pcn.rb/main",
    "homepage_uri"          => "https://github.com/sashite/pcn.rb",
    "source_code_uri"       => "https://github.com/sashite/pcn.rb",
    "specification_uri"     => "https://sashite.dev/specs/pcn/1.0.0/",
    "rubygems_mfa_required" => "true"
  }
end
