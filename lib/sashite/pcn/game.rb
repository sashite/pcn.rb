# frozen_string_literal: true

require "sashite/cgsn"
require "sashite/feen"
require "sashite/pmn"
require "sashite/snn"

require_relative "game/meta"
require_relative "game/sides"

module Sashite
  module Pcn
    # Represents a complete game record in PCN (Portable Chess Notation) format.
    #
    # A game consists of an initial position (setup), optional move sequence,
    # optional game status, optional metadata, and optional player information.
    # All instances are immutable - transformations return new instances.
    #
    # All parameters are validated at initialization time. An instance of Game
    # cannot be created with invalid data.
    #
    # @example Minimal game
    #   game = Game.new(setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c")
    #
    # @example Complete game
    #   game = Game.new(
    #     meta: { event: "World Championship" },
    #     sides: {
    #       first: { name: "Carlsen", elo: 2830, style: "CHESS" },
    #       second: { name: "Nakamura", elo: 2794, style: "chess" }
    #     },
    #     setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
    #     moves: [["e2", "e4"], ["c7", "c5"]],
    #     status: "in_progress"
    #   )
    class Game
      # Error messages
      ERROR_MISSING_SETUP = "setup is required"
      ERROR_INVALID_MOVES = "moves must be an array"
      ERROR_INVALID_META = "meta must be a hash"
      ERROR_INVALID_SIDES = "sides must be a hash"

      # Status constants
      STATUS_IN_PROGRESS = "in_progress"

      # Create a new game instance
      #
      # @param setup [String] initial position in FEEN format (required)
      # @param moves [Array<Array>] sequence of moves in PMN format (optional, defaults to [])
      # @param status [String, nil] game status in CGSN format (optional)
      # @param meta [Hash] game metadata (optional)
      # @param sides [Hash] player information (optional)
      # @raise [ArgumentError] if required fields are missing or invalid
      def initialize(setup:, moves: [], status: nil, meta: {}, sides: {})
        # Validate and parse setup (required)
        raise ::ArgumentError, ERROR_MISSING_SETUP if setup.nil?
        @setup = ::Sashite::Feen.parse(setup)

        # Validate and parse moves (optional, defaults to [])
        raise ::ArgumentError, ERROR_INVALID_MOVES unless moves.is_a?(::Array)
        @moves = moves.map { |move| ::Sashite::Pmn.parse(move) }.freeze

        # Validate and parse status (optional)
        @status = status.nil? ? nil : ::Sashite::Cgsn.parse(status)

        # Validate meta (optional)
        raise ::ArgumentError, ERROR_INVALID_META unless meta.is_a?(::Hash)
        @meta = Meta.new(**meta.transform_keys(&:to_sym))

        # Validate sides (optional)
        raise ::ArgumentError, ERROR_INVALID_SIDES unless sides.is_a?(::Hash)
        @sides = Sides.new(**sides.transform_keys(&:to_sym))

        freeze
      end

      # ========================================================================
      # Core Data Access
      # ========================================================================

      # Get initial position
      #
      # @return [Sashite::Feen::Position] initial position in FEEN format
      #
      # @example
      #   game.setup  # => #<Sashite::Feen::Position ...>
      def setup
        @setup
      end

      # Get game metadata
      #
      # @return [Meta] metadata object
      #
      # @example
      #   game.meta  # => #<Sashite::Pcn::Game::Meta ...>
      def meta
        @meta
      end

      # Get player information
      #
      # @return [Sides] sides object
      #
      # @example
      #   game.sides  # => #<Sashite::Pcn::Game::Sides ...>
      def sides
        @sides
      end

      # Get move sequence
      #
      # @return [Array<Sashite::Pmn::Move>] frozen array of moves
      #
      # @example
      #   game.moves  # => [#<Sashite::Pmn::Move ...>, ...]
      def moves
        @moves
      end

      # Get game status
      #
      # @return [Sashite::Cgsn::Status, nil] status object or nil
      #
      # @example
      #   game.status  # => #<Sashite::Cgsn::Status ...>
      def status
        @status
      end

      # ========================================================================
      # Player Access
      # ========================================================================

      # Get first player information
      #
      # @return [Hash, nil] first player data or nil if not defined
      #
      # @example
      #   game.first_player  # => { name: "Carlsen", elo: 2830, style: "CHESS" }
      def first_player
        @sides.first
      end

      # Get second player information
      #
      # @return [Hash, nil] second player data or nil if not defined
      #
      # @example
      #   game.second_player  # => { name: "Nakamura", elo: 2794, style: "chess" }
      def second_player
        @sides.second
      end

      # ========================================================================
      # Move Operations
      # ========================================================================

      # Get move at specified index
      #
      # @param index [Integer] move index (0-based)
      # @return [Sashite::Pmn::Move, nil] move at index or nil if out of bounds
      #
      # @example
      #   game.move_at(0)  # => #<Sashite::Pmn::Move ...>
      def move_at(index)
        @moves[index]
      end

      # Get total number of moves
      #
      # @return [Integer] number of moves in the game
      #
      # @example
      #   game.move_count  # => 2
      def move_count
        @moves.length
      end

      # Add a move to the game
      #
      # @param move [Array] move in PMN format
      # @return [Game] new game instance with added move
      #
      # @example
      #   new_game = game.add_move(["g1", "f3"])
      def add_move(move)
        new_moves = @moves.map(&:to_a) + [move]
        self.class.new(
          setup: @setup.to_s,
          moves: new_moves,
          status: @status&.to_s,
          meta: @meta.to_h,
          sides: @sides.to_h
        )
      end

      # ========================================================================
      # Metadata Shortcuts
      # ========================================================================

      # Get game start date
      #
      # @return [String, nil] start date in ISO 8601 format
      #
      # @example
      #   game.started_on  # => "2024-11-20"
      def started_on
        @meta[:started_on]
      end

      # Get game completion timestamp
      #
      # @return [String, nil] completion timestamp in ISO 8601 format with UTC
      #
      # @example
      #   game.finished_at  # => "2024-11-20T18:45:00Z"
      def finished_at
        @meta[:finished_at]
      end

      # Get event name
      #
      # @return [String, nil] event name
      #
      # @example
      #   game.event  # => "World Championship"
      def event
        @meta[:event]
      end

      # Get event location
      #
      # @return [String, nil] location
      #
      # @example
      #   game.location  # => "London"
      def location
        @meta[:location]
      end

      # Get round number
      #
      # @return [Integer, nil] round number
      #
      # @example
      #   game.round  # => 5
      def round
        @meta[:round]
      end

      # ========================================================================
      # Transformations
      # ========================================================================

      # Create new game with updated status
      #
      # @param new_status [String, nil] new status value
      # @return [Game] new game instance with updated status
      #
      # @example
      #   updated = game.with_status("resignation")
      def with_status(new_status)
        self.class.new(
          setup: @setup.to_s,
          moves: @moves.map(&:to_a),
          status: new_status,
          meta: @meta.to_h,
          sides: @sides.to_h
        )
      end

      # Create new game with updated metadata
      #
      # @param new_meta [Hash] metadata to merge
      # @return [Game] new game instance with updated metadata
      #
      # @example
      #   updated = game.with_meta(event: "Casual Game", round: 1)
      def with_meta(**new_meta)
        merged_meta = @meta.to_h.merge(new_meta)
        self.class.new(
          setup: @setup.to_s,
          moves: @moves.map(&:to_a),
          status: @status&.to_s,
          meta: merged_meta,
          sides: @sides.to_h
        )
      end

      # Create new game with specified move sequence
      #
      # @param new_moves [Array<Array>] new move sequence
      # @return [Game] new game instance with new moves
      #
      # @example
      #   updated = game.with_moves([["e2", "e4"], ["e7", "e5"]])
      def with_moves(new_moves)
        self.class.new(
          setup: @setup.to_s,
          moves: new_moves,
          status: @status&.to_s,
          meta: @meta.to_h,
          sides: @sides.to_h
        )
      end

      # ========================================================================
      # Predicates
      # ========================================================================

      # Check if the game is in progress
      #
      # @return [Boolean, nil] true if in progress, false if finished, nil if indeterminate
      #
      # @example
      #   game.in_progress?  # => true
      def in_progress?
        return if @status.nil?

        @status.to_s == STATUS_IN_PROGRESS
      end

      # Check if the game is finished
      #
      # @return [Boolean, nil] true if finished, false if in progress, nil if indeterminate
      #
      # @example
      #   game.finished?  # => false
      def finished?
        return if @status.nil?

        !in_progress?
      end

      # ========================================================================
      # Serialization
      # ========================================================================

      # Convert to hash representation
      #
      # @return [Hash] hash with string keys ready for JSON serialization
      #
      # @example
      #   game.to_h
      #   # => {
      #   #   "setup" => "...",
      #   #   "moves" => [[...], [...]],
      #   #   "status" => "in_progress",
      #   #   "meta" => {...},
      #   #   "sides" => {...}
      #   # }
      def to_h
        result = { "setup" => @setup.to_s }

        # Always include moves array (even if empty)
        result["moves"] = @moves.map(&:to_a)

        # Include optional fields if present
        result["status"] = @status.to_s if @status
        result["meta"] = @meta.to_h unless @meta.empty?
        result["sides"] = @sides.to_h unless @sides.empty?

        result
      end
    end
  end
end
