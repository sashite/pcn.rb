# frozen_string_literal: true

module Sashite
  module Pcn
    # Immutable representation of player information for both sides.
    #
    # Contains player information for first and second player.
    # At least one player must be defined when sides are present.
    #
    # @see https://sashite.dev/specs/pcn/1.0.0/
    class Sides
      # @return [Player, nil] First player information
      attr_reader :first

      # @return [Player, nil] Second player information
      attr_reader :second

      # Parse a sides hash into a Sides object.
      #
      # @param hash [Hash] Sides hash
      # @return [Sides] Immutable sides object
      # @raise [Error::Validation] If validation fails
      #
      # @example
      #   sides = Sides.parse({
      #     "first" => { "name" => "Alice", "elo" => 2800 },
      #     "second" => { "name" => "Bob", "elo" => 2750 }
      #   })
      def self.parse(hash)
        raise Error::Validation, "Sides must be a Hash, got #{hash.class}" unless hash.is_a?(::Hash)

        first = parse_player(hash["first"], "first")
        second = parse_player(hash["second"], "second")

        new(first:, second:)
      end

      # Validate a sides hash without raising exceptions.
      #
      # @param hash [Hash] Sides hash
      # @return [Boolean] true if valid, false otherwise
      #
      # @example
      #   Sides.valid?({ "first" => { "name" => "Alice" } })  # => true
      def self.valid?(hash)
        parse(hash)
        true
      rescue Error
        false
      end

      # Create a new Sides.
      #
      # @param first [Player, Hash, nil] First player information
      # @param second [Player, Hash, nil] Second player information
      # @raise [Error::Validation] If validation fails
      #
      # @example
      #   sides = Sides.new(
      #     first: Player.new(name: "Alice", elo: 2800),
      #     second: Player.new(name: "Bob", elo: 2750)
      #   )
      def initialize(first: nil, second: nil)
        @first = normalize_player(first, "first")
        @second = normalize_player(second, "second")

        validate!

        freeze
      end

      # Check if the sides are valid.
      #
      # @return [Boolean] true if valid
      def valid?
        validate!
        true
      rescue Error
        false
      end

      # Check if both sides are empty.
      #
      # @return [Boolean] true if both players are nil
      def empty?
        first.nil? && second.nil?
      end

      # Convert to hash representation.
      #
      # @return [Hash] Sides hash (excludes nil values)
      #
      # @example
      #   sides.to_h  # => { "first" => {...}, "second" => {...} }
      def to_h
        hash = {}

        hash["first"] = first.to_h unless first.nil?
        hash["second"] = second.to_h unless second.nil?

        hash
      end

      # String representation.
      #
      # @return [String] Inspectable representation
      def to_s
        fields = []
        fields << "first=#{first.name.inspect}" if first && first.name
        fields << "second=#{second.name.inspect}" if second && second.name

        "#<#{self.class} #{fields.join(' ')}>"
      end
      alias inspect to_s

      # Equality comparison.
      #
      # @param other [Sides] Other sides
      # @return [Boolean] true if equal
      def ==(other)
        other.is_a?(self.class) &&
          other.first == first &&
          other.second == second
      end
      alias eql? ==

      # Hash code for equality.
      #
      # @return [Integer] Hash code
      def hash
        [self.class, first, second].hash
      end

      private

      # Parse player field.
      def self.parse_player(value, field_name)
        return nil if value.nil?

        Player.parse(value)
      rescue Error => e
        raise Error::Validation, "Invalid '#{field_name}' player: #{e.message}"
      end

      # Normalize player to Player object.
      def normalize_player(value, field_name)
        return nil if value.nil?
        return value if value.is_a?(Player)

        Player.parse(value)
      rescue Error => e
        raise Error::Validation, "Invalid '#{field_name}' player: #{e.message}"
      end

      # Validate all fields.
      def validate!
        validate_structure!
        validate_first!
        validate_second!
      end

      # Validate that at least one player is defined.
      def validate_structure!
        return unless first.nil? && second.nil?

        raise Error::Validation, "Sides must have at least one player defined"
      end

      # Validate first player.
      def validate_first!
        return if first.nil?

        raise Error::Validation, "Sides 'first' must be a Player object, got #{first.class}" unless first.is_a?(Player)

        return if first.valid?

        raise Error::Validation, "Sides 'first' player validation failed"
      end

      # Validate second player.
      def validate_second!
        return if second.nil?

        unless second.is_a?(Player)
          raise Error::Validation, "Sides 'second' must be a Player object, got #{second.class}"
        end

        return if second.valid?

        raise Error::Validation, "Sides 'second' player validation failed"
      end
    end
  end
end
