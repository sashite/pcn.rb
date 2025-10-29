# frozen_string_literal: true

require "sashite/cgsn"
require "sashite/feen"
require "sashite/pan"
require "sashite/snn"

require_relative "game/meta"
require_relative "game/sides"

module Sashite
  module Pcn
    # Represents a complete game record in PCN (Portable Chess Notation) format.
    #
    # A game consists of an initial position (setup), optional move sequence with time tracking,
    # optional game status, optional draw offer tracking, optional metadata, and optional player
    # information with time control. All instances are immutable - transformations return new instances.
    #
    # All parameters are validated at initialization time. An instance of Game
    # cannot be created with invalid data.
    #
    # @example Minimal game
    #   game = Game.new(setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c")
    #
    # @example Complete game with time tracking
    #   game = Game.new(
    #     meta: {
    #       event: "World Championship",
    #       started_at: "2025-01-27T14:00:00Z"
    #     },
    #     sides: {
    #       first: {
    #         name: "Carlsen",
    #         elo: 2830,
    #         style: "CHESS",
    #         periods: [
    #           { time: 5400, moves: 40, inc: 0 },
    #           { time: 1800, moves: nil, inc: 30 }
    #         ]
    #       },
    #       second: {
    #         name: "Nakamura",
    #         elo: 2794,
    #         style: "chess",
    #         periods: [
    #           { time: 5400, moves: 40, inc: 0 },
    #           { time: 1800, moves: nil, inc: 30 }
    #         ]
    #       }
    #     },
    #     setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    #     moves: [
    #       ["e2-e4", 2.5],
    #       ["c7-c5", 3.1]
    #     ],
    #     status: "in_progress"
    #   )
    #
    # @example Game with draw offer
    #   game = Game.new(
    #     setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    #     moves: [["e2-e4", 8.0], ["e7-e5", 12.0]],
    #     draw_offered_by: "first",
    #     status: "in_progress"
    #   )
    class Game
      # Error messages
      ERROR_MISSING_SETUP = "setup is required"
      ERROR_INVALID_MOVES = "moves must be an array"
      ERROR_INVALID_MOVE_FORMAT = "each move must be [PAN string, seconds float] tuple"
      ERROR_INVALID_PAN = "invalid PAN notation in move"
      ERROR_INVALID_SECONDS = "seconds must be a non-negative number"
      ERROR_INVALID_META = "meta must be a hash"
      ERROR_INVALID_SIDES = "sides must be a hash"
      ERROR_INVALID_DRAW_OFFERED_BY = "draw_offered_by must be nil, 'first', or 'second'"

      # Status constants
      STATUS_IN_PROGRESS = "in_progress"

      # Valid draw_offered_by values
      VALID_DRAW_OFFERED_BY = [nil, "first", "second"].freeze

      # Create a new game instance
      #
      # @param setup [String] initial position in FEEN format (required)
      # @param moves [Array<Array>] sequence of [PAN, seconds] tuples (optional, defaults to [])
      # @param status [String, nil] game status in CGSN format (optional)
      # @param draw_offered_by [String, nil] draw offer indicator: nil, "first", or "second" (optional)
      # @param meta [Hash] game metadata (optional)
      # @param sides [Hash] player information with time control (optional)
      # @raise [ArgumentError] if required fields are missing or invalid
      def initialize(setup:, moves: [], status: nil, draw_offered_by: nil, meta: {}, sides: {})
        # Validate and parse setup (required)
        raise ::ArgumentError, ERROR_MISSING_SETUP if setup.nil?
        @setup = ::Sashite::Feen.parse(setup)

        # Validate and parse moves (optional, defaults to [])
        raise ::ArgumentError, ERROR_INVALID_MOVES unless moves.is_a?(::Array)
        @moves = validate_and_parse_moves(moves).freeze

        # Validate and parse status (optional)
        @status = status.nil? ? nil : ::Sashite::Cgsn.parse(status)

        # Validate draw_offered_by (optional)
        validate_draw_offered_by(draw_offered_by)
        @draw_offered_by = draw_offered_by

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

      # Get move sequence with time tracking
      #
      # @return [Array<Array>] frozen array of [PAN, seconds] tuples
      #
      # @example
      #   game.moves  # => [["e2-e4", 2.5], ["e7-e5", 3.1]]
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

      # Get draw offer indicator
      #
      # @return [String, nil] "first", "second", or nil
      #
      # @example
      #   game.draw_offered_by  # => "first"
      #   game.draw_offered_by  # => nil
      def draw_offered_by
        @draw_offered_by
      end

      # ========================================================================
      # Player Access
      # ========================================================================

      # Get first player information
      #
      # @return [Hash, nil] first player data or nil if not defined
      #
      # @example
      #   game.first_player
      #   # => { name: "Carlsen", elo: 2830, style: "CHESS", periods: [...] }
      def first_player
        @sides.first
      end

      # Get second player information
      #
      # @return [Hash, nil] second player data or nil if not defined
      #
      # @example
      #   game.second_player
      #   # => { name: "Nakamura", elo: 2794, style: "chess", periods: [...] }
      def second_player
        @sides.second
      end

      # ========================================================================
      # Move Operations
      # ========================================================================

      # Get move at specified index
      #
      # @param index [Integer] move index (0-based)
      # @return [Array, nil] [PAN, seconds] tuple at index or nil if out of bounds
      #
      # @example
      #   game.move_at(0)  # => ["e2-e4", 2.5]
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
      # @param move [Array] [PAN, seconds] tuple
      # @return [Game] new game instance with added move
      # @raise [ArgumentError] if move format is invalid
      #
      # @example
      #   new_game = game.add_move(["g1-f3", 1.8])
      def add_move(move)
        # Validate the new move
        validate_move_tuple(move)

        new_moves = @moves + [move]
        self.class.new(
          setup: @setup.to_s,
          moves: new_moves,
          status: @status&.to_s,
          draw_offered_by: @draw_offered_by,
          meta: @meta.to_h,
          sides: @sides.to_h
        )
      end

      # Get the PAN notation from a move
      #
      # @param index [Integer] move index
      # @return [String, nil] PAN notation or nil if out of bounds
      #
      # @example
      #   game.pan_at(0)  # => "e2-e4"
      def pan_at(index)
        move = @moves[index]
        move ? move[0] : nil
      end

      # Get the seconds spent on a move
      #
      # @param index [Integer] move index
      # @return [Float, nil] seconds or nil if out of bounds
      #
      # @example
      #   game.seconds_at(0)  # => 2.5
      def seconds_at(index)
        move = @moves[index]
        move ? move[1] : nil
      end

      # Get total time spent by first player
      #
      # @return [Float] sum of seconds for moves at even indices
      #
      # @example
      #   game.first_player_time  # => 125.3
      def first_player_time
        @moves.each_with_index
              .select { |_, i| i.even? }
              .sum { |move, _| move[1] }
      end

      # Get total time spent by second player
      #
      # @return [Float] sum of seconds for moves at odd indices
      #
      # @example
      #   game.second_player_time  # => 132.7
      def second_player_time
        @moves.each_with_index
              .select { |_, i| i.odd? }
              .sum { |move, _| move[1] }
      end

      # ========================================================================
      # Metadata Shortcuts
      # ========================================================================

      # Get game start timestamp
      #
      # @return [String, nil] start timestamp in ISO 8601 format
      #
      # @example
      #   game.started_at  # => "2025-01-27T14:00:00Z"
      def started_at
        @meta[:started_at]
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
          moves: @moves,
          status: new_status,
          draw_offered_by: @draw_offered_by,
          meta: @meta.to_h,
          sides: @sides.to_h
        )
      end

      # Create new game with updated draw offer
      #
      # @param player [String, nil] "first", "second", or nil
      # @return [Game] new game instance with updated draw offer
      # @raise [ArgumentError] if player is invalid
      #
      # @example
      #   # First player offers a draw
      #   game_with_offer = game.with_draw_offered_by("first")
      #
      #   # Withdraw draw offer
      #   game_no_offer = game.with_draw_offered_by(nil)
      def with_draw_offered_by(player)
        self.class.new(
          setup: @setup.to_s,
          moves: @moves,
          status: @status&.to_s,
          draw_offered_by: player,
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
          moves: @moves,
          status: @status&.to_s,
          draw_offered_by: @draw_offered_by,
          meta: merged_meta,
          sides: @sides.to_h
        )
      end

      # Create new game with specified move sequence
      #
      # @param new_moves [Array<Array>] new move sequence of [PAN, seconds] tuples
      # @return [Game] new game instance with new moves
      # @raise [ArgumentError] if move format is invalid
      #
      # @example
      #   updated = game.with_moves([["e2-e4", 2.0], ["e7-e5", 3.0]])
      def with_moves(new_moves)
        self.class.new(
          setup: @setup.to_s,
          moves: new_moves,
          status: @status&.to_s,
          draw_offered_by: @draw_offered_by,
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

      # Check if a draw offer is pending
      #
      # @return [Boolean] true if a draw offer is pending
      #
      # @example
      #   game.draw_offered?  # => true (if draw_offered_by is "first" or "second")
      #   game.draw_offered?  # => false (if draw_offered_by is nil)
      def draw_offered?
        !@draw_offered_by.nil?
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
      #   #   "moves" => [["e2-e4", 2.5], ["e7-e5", 3.1]],
      #   #   "status" => "in_progress",
      #   #   "draw_offered_by" => "first",
      #   #   "meta" => {...},
      #   #   "sides" => {...}
      #   # }
      def to_h
        result = { "setup" => @setup.to_s }

        # Always include moves array (even if empty)
        result["moves"] = @moves

        # Include optional fields if present
        result["status"] = @status.to_s if @status
        result["draw_offered_by"] = @draw_offered_by if @draw_offered_by
        result["meta"] = @meta.to_h unless @meta.empty?
        result["sides"] = @sides.to_h unless @sides.empty?

        result
      end

      # Compare with another game
      #
      # @param other [Object] object to compare
      # @return [Boolean] true if equal
      #
      # @example
      #   game1 == game2  # => true if all attributes match
      def ==(other)
        return false unless other.is_a?(Game)

        @setup.to_s == other.setup.to_s &&
          @moves == other.moves &&
          @status&.to_s == other.status&.to_s &&
          @draw_offered_by == other.draw_offered_by &&
          @meta == other.meta &&
          @sides == other.sides
      end

      # Generate hash code
      #
      # @return [Integer] hash code for this game
      #
      # @example
      #   game.hash  # => 123456789
      def hash
        [@setup.to_s, @moves, @status&.to_s, @draw_offered_by, @meta, @sides].hash
      end

      # Generate debug representation
      #
      # @return [String] debug string
      #
      # @example
      #   game.inspect
      #   # => "#<Game setup=\"...\" moves=[...] status=\"in_progress\" draw_offered_by=\"first\">"
      def inspect
        parts = ["setup=#{@setup.to_s.inspect}"]
        parts << "moves=#{@moves.inspect}"
        parts << "status=#{@status&.to_s.inspect}" if @status
        parts << "draw_offered_by=#{@draw_offered_by.inspect}" if @draw_offered_by
        parts << "meta=#{@meta.inspect}" unless @meta.empty?
        parts << "sides=#{@sides.inspect}" unless @sides.empty?

        "#<#{self.class.name} #{parts.join(' ')}>"
      end

      private

      # Validate and parse moves array
      #
      # @param moves [Array] array of move tuples
      # @return [Array<Array>] validated moves
      # @raise [ArgumentError] if any move is invalid
      def validate_and_parse_moves(moves)
        moves.map.with_index do |move, index|
          validate_move_tuple(move, index)
        end
      end

      # Validate a single move tuple
      #
      # @param move [Array] [PAN, seconds] tuple
      # @param index [Integer, nil] optional index for error messages
      # @raise [ArgumentError] if move format is invalid
      def validate_move_tuple(move, index = nil)
        position = index ? " at index #{index}" : ""

        # Check it's an array with exactly 2 elements
        raise ::ArgumentError, "#{ERROR_INVALID_MOVE_FORMAT}#{position}" unless move.is_a?(::Array) && move.length == 2

        pan_notation, seconds = move

        # Validate PAN notation
        unless pan_notation.is_a?(::String)
          raise ::ArgumentError, "#{ERROR_INVALID_PAN}#{position}: PAN must be a string"
        end

        # Parse PAN to validate format (this will raise if invalid)
        begin
          ::Sashite::Pan.parse(pan_notation)
        rescue StandardError => e
          raise ::ArgumentError, "#{ERROR_INVALID_PAN}#{position}: #{e.message}"
        end

        # Validate seconds (must be a non-negative number)
        raise ::ArgumentError, "#{ERROR_INVALID_SECONDS}#{position}" unless seconds.is_a?(::Numeric) && seconds >= 0

        # Return the move tuple with seconds as float
        [pan_notation, seconds.to_f].freeze
      end

      # Validate draw_offered_by field
      #
      # @param value [String, nil] draw offer value to validate
      # @raise [ArgumentError] if value is invalid
      def validate_draw_offered_by(value)
        return if VALID_DRAW_OFFERED_BY.include?(value)

        raise ::ArgumentError, ERROR_INVALID_DRAW_OFFERED_BY
      end
    end
  end
end
