# frozen_string_literal: true

require_relative "sides/player"

module Sashite
  module Pcn
    class Game
      # Represents player information for both sides of a game
      #
      # Both players are optional and default to empty player objects.
      # An empty Sides object (no player information) is valid.
      #
      # @example With both players
      #   sides = Sides.new(
      #     first: { name: "Carlsen", elo: 2830, style: "CHESS" },
      #     second: { name: "Nakamura", elo: 2794, style: "chess" }
      #   )
      #
      # @example With only first player
      #   sides = Sides.new(
      #     first: { name: "Player 1", style: "CHESS" }
      #   )
      #
      # @example Empty sides (no player information)
      #   sides = Sides.new  # Both players default to {}
      class Sides
        # Create a new Sides instance
        #
        # @param first [Hash] first player information (defaults to {})
        # @param second [Hash] second player information (defaults to {})
        def initialize(first: {}, second: {})
          @first = Player.new(**first.transform_keys(&:to_sym))
          @second = Player.new(**second.transform_keys(&:to_sym))

          freeze
        end

        # Get first player information
        #
        # @return [Player] first player (may be empty)
        #
        # @example
        #   sides.first  # => #<Sashite::Pcn::Game::Sides::Player ...>
        def first
          @first
        end

        # Get second player information
        #
        # @return [Player] second player (may be empty)
        #
        # @example
        #   sides.second  # => #<Sashite::Pcn::Game::Sides::Player ...>
        def second
          @second
        end

        # Check if no player information is present
        #
        # @return [Boolean] true if both players are empty
        #
        # @example
        #   sides.empty?  # => true
        def empty?
          @first.empty? && @second.empty?
        end

        # Convert to hash representation
        #
        # Returns a hash containing only non-empty player objects.
        # If both players are empty, returns an empty hash.
        #
        # @return [Hash] hash with :first and/or :second keys, or empty hash
        #
        # @example With both players
        #   sides.to_h
        #   # => { first: { name: "Carlsen", elo: 2830, style: "CHESS" },
        #   #      second: { name: "Nakamura", elo: 2794, style: "chess" } }
        #
        # @example With only first player
        #   sides.to_h
        #   # => { first: { name: "Alice" } }
        #
        # @example With no players
        #   sides.to_h
        #   # => {}
        def to_h
          result = {}
          result[:first] = @first.to_h unless @first.empty?
          result[:second] = @second.to_h unless @second.empty?
          result
        end
      end
    end
  end
end
