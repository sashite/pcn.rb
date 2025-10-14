# frozen_string_literal: true

module Sashite
  module Pcn
    # Immutable representation of a complete game record.
    #
    # A Game consists of:
    # - setup: Initial position (FEEN format) [required]
    # - moves: Sequence of moves (PMN format) [required]
    # - status: Game status [optional]
    # - meta: Metadata [optional]
    # - sides: Player information [optional]
    #
    # @see https://sashite.dev/specs/pcn/1.0.0/
    class Game
      # Valid status values according to PCN specification.
      VALID_STATUSES = %w[
        in_progress
        checkmate
        stalemate
        bare_king
        mare_king
        resignation
        illegal_move
        time_limit
        move_limit
        repetition
        agreement
        insufficient
      ].freeze

      # @return [Feen::Position] Initial position
      attr_reader :setup

      # @return [Array<Pmn::Move>] Move sequence
      attr_reader :moves

      # @return [String, nil] Game status
      attr_reader :status

      # @return [Meta, nil] Metadata
      attr_reader :meta

      # @return [Sides, nil] Player information
      attr_reader :sides

      # Parse a PCN hash into a Game object.
      #
      # @param hash [Hash] PCN document hash
      # @return [Game] Immutable game object
      # @raise [Error::Parse] If structure is invalid
      # @raise [Error::Validation] If format is invalid
      #
      # @example
      #   game = Game.parse({
      #     "setup" => "8/8/8/8/8/8/8/8 / C/c",
      #     "moves" => []
      #   })
      def self.parse(hash)
        validate_structure!(hash)

        setup = parse_setup(hash["setup"])
        moves = parse_moves(hash["moves"])
        status = hash["status"]
        meta = parse_meta(hash["meta"])
        sides = parse_sides(hash["sides"])

        new(
          setup:  setup,
          moves:  moves,
          status: status,
          meta:   meta,
          sides:  sides
        )
      end

      # Validate a PCN hash without raising exceptions.
      #
      # @param hash [Hash] PCN document hash
      # @return [Boolean] true if valid, false otherwise
      #
      # @example
      #   Game.valid?({ "setup" => "...", "moves" => [] })  # => true
      def self.valid?(hash)
        parse(hash)
        true
      rescue Error
        false
      end

      # Create a new Game.
      #
      # @param setup [Feen::Position, String] Initial position
      # @param moves [Array<Pmn::Move, Array>] Move sequence
      # @param status [String, nil] Game status
      # @param meta [Meta, Hash, nil] Metadata
      # @param sides [Sides, Hash, nil] Player information
      # @raise [Error::Validation] If validation fails
      #
      # @example
      #   game = Game.new(
      #     setup: Feen.parse("8/8/8/8/8/8/8/8 / C/c"),
      #     moves: []
      #   )
      def initialize(setup:, moves:, status: nil, meta: nil, sides: nil)
        @setup = normalize_setup(setup)
        @moves = normalize_moves(moves)
        @status = normalize_status(status)
        @meta = normalize_meta(meta)
        @sides = normalize_sides(sides)

        validate!

        freeze
      end

      # Check if the game is valid.
      #
      # @return [Boolean] true if valid
      def valid?
        validate!
        true
      rescue Error
        false
      end

      # Get the number of moves.
      #
      # @return [Integer] Move count
      def move_count
        moves.size
      end
      alias size move_count
      alias length move_count

      # Check if no moves have been played.
      #
      # @return [Boolean] true if no moves
      def empty?
        moves.empty?
      end

      # Check if status is present.
      #
      # @return [Boolean] true if status field exists
      def has_status?
        !status.nil?
      end

      # Check if metadata is present.
      #
      # @return [Boolean] true if meta field exists
      def has_meta?
        !meta.nil?
      end

      # Check if player information is present.
      #
      # @return [Boolean] true if sides field exists
      def has_sides?
        !sides.nil?
      end

      # Add a move to the game.
      #
      # @param move [Pmn::Move, Array] Move to add
      # @return [Game] New game with added move
      #
      # @example
      #   new_game = game.add_move(["e2", "e4", "C:P"])
      def add_move(move)
        normalized_move = move.is_a?(::Sashite::Pmn::Move) ? move : ::Sashite::Pmn.parse(move)

        self.class.new(
          setup:  setup,
          moves:  moves + [normalized_move],
          status: status,
          meta:   meta,
          sides:  sides
        )
      end

      # Update the game status.
      #
      # @param new_status [String, nil] New status value
      # @return [Game] New game with updated status
      #
      # @example
      #   finished = game.with_status("checkmate")
      def with_status(new_status)
        self.class.new(
          setup:  setup,
          moves:  moves,
          status: new_status,
          meta:   meta,
          sides:  sides
        )
      end

      # Update the metadata.
      #
      # @param new_meta [Meta, Hash, nil] New metadata
      # @return [Game] New game with updated metadata
      #
      # @example
      #   updated = game.with_meta(Meta.new(event: "Tournament"))
      def with_meta(new_meta)
        self.class.new(
          setup:  setup,
          moves:  moves,
          status: status,
          meta:   new_meta,
          sides:  sides
        )
      end

      # Update the player information.
      #
      # @param new_sides [Sides, Hash, nil] New player information
      # @return [Game] New game with updated sides
      #
      # @example
      #   updated = game.with_sides(Sides.new(first: player1, second: player2))
      def with_sides(new_sides)
        self.class.new(
          setup:  setup,
          moves:  moves,
          status: status,
          meta:   meta,
          sides:  new_sides
        )
      end

      # Convert to hash representation.
      #
      # @return [Hash] PCN document hash
      #
      # @example
      #   game.to_h  # => { "setup" => "...", "moves" => [...], ... }
      def to_h
        hash = {
          "setup" => setup.to_s,
          "moves" => moves.map(&:to_a)
        }

        hash["status"] = status if has_status?
        hash["meta"] = meta.to_h if has_meta?
        hash["sides"] = sides.to_h if has_sides?

        hash
      end

      # String representation.
      #
      # @return [String] Inspectable representation
      def to_s
        "#<#{self.class} setup=#{setup.to_s.inspect} moves=#{moves.size} status=#{status.inspect}>"
      end
      alias inspect to_s

      # Equality comparison.
      #
      # @param other [Game] Other game
      # @return [Boolean] true if equal
      def ==(other)
        other.is_a?(self.class) &&
          other.setup == setup &&
          other.moves == moves &&
          other.status == status &&
          other.meta == meta &&
          other.sides == sides
      end
      alias eql? ==

      # Hash code for equality.
      #
      # @return [Integer] Hash code
      def hash
        [self.class, setup, moves, status, meta, sides].hash
      end

      private

      # Validate PCN hash structure.
      def self.validate_structure!(hash)
        raise Error::Parse, "PCN document must be a Hash, got #{hash.class}" unless hash.is_a?(::Hash)

        raise Error::Parse, "Missing required field 'setup'" unless hash.key?("setup")

        raise Error::Parse, "Missing required field 'moves'" unless hash.key?("moves")

        return if hash["moves"].is_a?(::Array)

        raise Error::Parse, "'moves' must be an Array, got #{hash['moves'].class}"
      end

      # Parse setup field.
      def self.parse_setup(value)
        ::Sashite::Feen.parse(value)
      rescue ::Sashite::Feen::Error => e
        raise Error::Validation, "Invalid setup: #{e.message}"
      end

      # Parse moves field.
      def self.parse_moves(array)
        array.map.with_index do |move_array, index|
          ::Sashite::Pmn.parse(move_array)
        rescue ::Sashite::Pmn::Error => e
          raise Error::Validation, "Invalid move at index #{index}: #{e.message}"
        end
      end

      # Parse meta field.
      def self.parse_meta(value)
        return nil if value.nil?

        Meta.parse(value)
      rescue Error => e
        raise Error::Validation, "Invalid meta: #{e.message}"
      end

      # Parse sides field.
      def self.parse_sides(value)
        return nil if value.nil?

        Sides.parse(value)
      rescue Error => e
        raise Error::Validation, "Invalid sides: #{e.message}"
      end

      # Normalize setup to Position object.
      def normalize_setup(value)
        return value if value.is_a?(::Sashite::Feen::Position)

        ::Sashite::Feen.parse(value)
      rescue ::Sashite::Feen::Error => e
        raise Error::Validation, "Invalid setup: #{e.message}"
      end

      # Normalize moves to array of Move objects.
      def normalize_moves(value)
        raise Error::Validation, "Moves must be an Array, got #{value.class}" unless value.is_a?(::Array)

        value.map.with_index do |move, index|
          next move if move.is_a?(::Sashite::Pmn::Move)

          ::Sashite::Pmn.parse(move)
        rescue ::Sashite::Pmn::Error => e
          raise Error::Validation, "Invalid move at index #{index}: #{e.message}"
        end
      end

      # Normalize status.
      def normalize_status(value)
        return nil if value.nil?

        raise Error::Validation, "Status must be a String, got #{value.class}" unless value.is_a?(::String)

        value
      end

      # Normalize meta.
      def normalize_meta(value)
        return nil if value.nil?
        return value if value.is_a?(Meta)

        Meta.parse(value)
      end

      # Normalize sides.
      def normalize_sides(value)
        return nil if value.nil?
        return value if value.is_a?(Sides)

        Sides.parse(value)
      end

      # Validate all fields.
      def validate!
        validate_setup!
        validate_moves!
        validate_status!
        validate_meta!
        validate_sides!
      end

      # Validate setup field.
      def validate_setup!
        return if setup.is_a?(::Sashite::Feen::Position)

        raise Error::Validation, "Setup must be a Feen::Position"
      end

      # Validate moves field.
      def validate_moves!
        raise Error::Validation, "Moves must be an Array" unless moves.is_a?(::Array)

        moves.each_with_index do |move, index|
          raise Error::Validation, "Move at index #{index} must be a Pmn::Move" unless move.is_a?(::Sashite::Pmn::Move)
        end
      end

      # Validate status field.
      def validate_status!
        return if status.nil?

        raise Error::Validation, "Status must be a String, got #{status.class}" unless status.is_a?(::String)

        return if VALID_STATUSES.include?(status)

        raise Error::Validation, "Invalid status value: #{status.inspect}"
      end

      # Validate meta field.
      def validate_meta!
        return if meta.nil?

        raise Error::Validation, "Meta must be a Meta object" unless meta.is_a?(Meta)

        return if meta.valid?

        raise Error::Validation, "Meta validation failed"
      end

      # Validate sides field.
      def validate_sides!
        return if sides.nil?

        raise Error::Validation, "Sides must be a Sides object" unless sides.is_a?(Sides)

        return if sides.valid?

        raise Error::Validation, "Sides validation failed"
      end
    end
  end
end
