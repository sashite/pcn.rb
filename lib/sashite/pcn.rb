# frozen_string_literal: true

require "sashite/pmn"
require "sashite/feen"
require "sashite/snn"

require_relative "pcn/error"
require_relative "pcn/meta"
require_relative "pcn/player"
require_relative "pcn/sides"
require_relative "pcn/game"

module Sashite
  # PCN (Portable Chess Notation) implementation.
  #
  # Provides a comprehensive, rule-agnostic format for representing complete
  # chess game records across variants, integrating PMN, FEEN, and SNN
  # specifications.
  #
  # @see https://sashite.dev/specs/pcn/1.0.0/
  module Pcn
    # Parse a PCN hash into a Game object.
    #
    # @param hash [Hash] PCN document hash
    # @return [Game] Immutable game object
    # @raise [Error] If parsing or validation fails
    #
    # @example
    #   game = Sashite::Pcn.parse({
    #     "setup" => "8/8/8/8/8/8/8/8 / C/c",
    #     "moves" => []
    #   })
    def self.parse(hash)
      Game.parse(hash)
    end

    # Validate a PCN hash without raising exceptions.
    #
    # @param hash [Hash] PCN document hash
    # @return [Boolean] true if valid, false otherwise
    #
    # @example
    #   Sashite::Pcn.valid?({ "setup" => "...", "moves" => [] })  # => true
    #   Sashite::Pcn.valid?({ "setup" => "" })                    # => false
    def self.valid?(hash)
      Game.valid?(hash)
    end

    # Create a new game from components.
    #
    # @param attributes [Hash] Game attributes as keyword arguments
    # @option attributes [Feen::Position, String] :setup Initial position (required)
    # @option attributes [Array<Pmn::Move, Array>] :moves Move sequence (required)
    # @option attributes [String, nil] :status Game status (optional)
    # @option attributes [Meta, Hash, nil] :meta Metadata (optional)
    # @option attributes [Sides, Hash, nil] :sides Player information (optional)
    # @return [Game] Immutable game object
    #
    # @example
    #   game = Sashite::Pcn.new(
    #     setup: Sashite::Feen.parse("8/8/8/8/8/8/8/8 / C/c"),
    #     moves: []
    #   )
    def self.new(**attributes)
      Game.new(**attributes)
    end
  end
end
