# frozen_string_literal: true

require_relative "pcn/game"

module Sashite
  # PCN (Portable Chess Notation) implementation for Ruby
  #
  # Provides functionality for representing complete chess game records
  # across variants using a comprehensive JSON-based format.
  #
  # This implementation is strictly compliant with PCN Specification v1.0.0
  # @see https://sashite.dev/specs/pcn/1.0.0/ PCN Specification v1.0.0
  module Pcn
    # Parse a PCN document from a hash structure
    #
    # @param hash [Hash] the PCN document data
    # @return [Game] new game instance
    # @raise [ArgumentError] if the document is invalid
    #
    # @example Parse minimal PCN
    #   game = Sashite::Pcn.parse({
    #     "setup" => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c"
    #   })
    #
    # @example Parse complete game
    #   game = Sashite::Pcn.parse({
    #     "meta" => { "event" => "World Championship" },
    #     "sides" => {
    #       "first" => { "name" => "Carlsen", "elo" => 2830, "style" => "CHESS" },
    #       "second" => { "name" => "Nakamura", "elo" => 2794, "style" => "chess" }
    #     },
    #     "setup" => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
    #     "moves" => [["e2", "e4"], ["e7", "e5"]],
    #     "status" => "in_progress"
    #   })
    def self.parse(hash)
      Game.new(**hash.transform_keys(&:to_sym))
    end

    # Validate a PCN document structure
    #
    # @param hash [Hash] the PCN document data
    # @return [Boolean] true if the document is structurally valid
    #
    # @example
    #   Sashite::Pcn.valid?({ "setup" => "8/8/8/8/8/8/8/8 / C/c" })  # => true
    #   Sashite::Pcn.valid?({ "moves" => [] })                        # => false
    def self.valid?(hash)
      return false unless hash.is_a?(::Hash)
      return false unless hash.key?("setup") || hash.key?(:setup)

      parse(hash)
      true
    rescue ::ArgumentError, ::TypeError
      false
    end
  end
end
