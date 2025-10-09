# frozen_string_literal: true

module Sashite
  module Pcn
    # Immutable representation of player information.
    #
    # All fields are optional. Player provides identification and
    # rating information for game participants.
    #
    # @see https://sashite.dev/specs/pcn/1.0.0/
    class Player
      # @return [String, nil] Style name in SNN format
      attr_reader :style

      # @return [String, nil] Player name or identifier
      attr_reader :name

      # @return [Integer, nil] Elo rating
      attr_reader :elo

      # Parse a player hash into a Player object.
      #
      # @param hash [Hash] Player hash
      # @return [Player] Immutable player object
      # @raise [Error::Validation] If validation fails
      #
      # @example
      #   player = Player.parse({
      #     "name" => "Magnus Carlsen",
      #     "elo" => 2830,
      #     "style" => "CHESS"
      #   })
      def self.parse(hash)
        raise Error::Validation, "Player must be a Hash, got #{hash.class}" unless hash.is_a?(::Hash)

        new(
          style: hash["style"],
          name:  hash["name"],
          elo:   hash["elo"]
        )
      end

      # Validate a player hash without raising exceptions.
      #
      # @param hash [Hash] Player hash
      # @return [Boolean] true if valid, false otherwise
      #
      # @example
      #   Player.valid?({ "name" => "Alice" })  # => true
      def self.valid?(hash)
        parse(hash)
        true
      rescue Error
        false
      end

      # Create a new Player.
      #
      # @param style [String, nil] Style name (SNN format)
      # @param name [String, nil] Player name
      # @param elo [Integer, nil] Elo rating
      # @raise [Error::Validation] If validation fails
      #
      # @example
      #   player = Player.new(
      #     name: "Magnus Carlsen",
      #     elo: 2830,
      #     style: "CHESS"
      #   )
      def initialize(style: nil, name: nil, elo: nil)
        @style = style
        @name = name
        @elo = elo

        validate!

        freeze
      end

      # Check if the player is valid.
      #
      # @return [Boolean] true if valid
      def valid?
        validate!
        true
      rescue Error
        false
      end

      # Check if player is empty (all fields nil).
      #
      # @return [Boolean] true if all fields are nil
      def empty?
        style.nil? && name.nil? && elo.nil?
      end

      # Convert to hash representation.
      #
      # @return [Hash] Player hash (excludes nil values)
      #
      # @example
      #   player.to_h  # => { "name" => "Alice", "elo" => 2800 }
      def to_h
        hash = {}

        hash["style"] = style unless style.nil?
        hash["name"] = name unless name.nil?
        hash["elo"] = elo unless elo.nil?

        hash
      end

      # String representation.
      #
      # @return [String] Inspectable representation
      def to_s
        fields = []
        fields << "name=#{name.inspect}" unless name.nil?
        fields << "elo=#{elo}" unless elo.nil?
        fields << "style=#{style.inspect}" unless style.nil?

        "#<#{self.class} #{fields.join(' ')}>"
      end
      alias inspect to_s

      # Equality comparison.
      #
      # @param other [Player] Other player
      # @return [Boolean] true if equal
      def ==(other)
        other.is_a?(self.class) &&
          other.style == style &&
          other.name == name &&
          other.elo == elo
      end
      alias eql? ==

      # Hash code for equality.
      #
      # @return [Integer] Hash code
      def hash
        [self.class, style, name, elo].hash
      end

      private

      # Validate all fields.
      def validate!
        validate_style!
        validate_name!
        validate_elo!
      end

      # Validate style field.
      def validate_style!
        return if style.nil?

        raise Error::Validation, "Player 'style' must be a String, got #{style.class}" unless style.is_a?(::String)

        return if ::Sashite::Snn.valid?(style)

        raise Error::Validation, "Player 'style' must be valid SNN format, got #{style.inspect}"
      end

      # Validate name field.
      def validate_name!
        return if name.nil?

        return if name.is_a?(::String)

        raise Error::Validation, "Player 'name' must be a String, got #{name.class}"
      end

      # Validate elo field.
      def validate_elo!
        return if elo.nil?

        raise Error::Validation, "Player 'elo' must be an Integer, got #{elo.class}" unless elo.is_a?(::Integer)

        return unless elo < 0

        raise Error::Validation, "Player 'elo' must be >= 0, got #{elo}"
      end
    end
  end
end
