# frozen_string_literal: true

module Sashite
  module Pcn
    class Game
      # Represents game metadata with standard and custom fields
      #
      # All fields are optional. An empty Meta object (no metadata) is valid.
      # Standard fields are validated, custom fields are accepted without validation.
      #
      # @example With standard fields
      #   meta = Meta.new(
      #     name: "Italian Game",
      #     event: "World Championship",
      #     location: "London",
      #     round: 5,
      #     started_at: "2025-01-27T14:00:00Z",
      #     href: "https://example.com/game/123"
      #   )
      #
      # @example With custom fields
      #   meta = Meta.new(
      #     event: "Online Tournament",
      #     platform: "lichess.org",
      #     time_control: "5+3",
      #     rated: true,
      #     opening_eco: "C50"
      #   )
      #
      # @example Empty metadata
      #   meta = Meta.new  # Valid, no metadata
      class Meta
        # Error messages
        ERROR_INVALID_NAME = "name must be a string"
        ERROR_INVALID_EVENT = "event must be a string"
        ERROR_INVALID_LOCATION = "location must be a string"
        ERROR_INVALID_ROUND = "round must be a positive integer (>= 1)"
        ERROR_INVALID_STARTED_AT = "started_at must be in ISO 8601 datetime format (e.g., 2025-01-27T14:00:00Z)"
        ERROR_INVALID_HREF = "href must be an absolute URL (http:// or https://)"

        # Standard field keys
        STANDARD_FIELDS = %i[name event location round started_at href].freeze

        # Regular expressions for validation
        # ISO 8601 datetime - accepts various formats:
        # - Basic: 2025-01-27T14:00:00Z
        # - With milliseconds: 2025-01-27T14:00:00.123Z
        # - With timezone offset: 2025-01-27T14:00:00+02:00
        # - Local time without timezone: 2025-01-27T14:00:00
        DATETIME_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?\z/
        URL_PATTERN = /\Ahttps?:\/\/.+/

        # Create a new Meta instance
        #
        # @param fields [Hash] metadata with optional standard and custom fields
        # @raise [ArgumentError] if standard field values don't meet validation requirements
        def initialize(**fields)
          @data = {}

          # Process and validate each field
          fields.each do |key, value|
            validate_and_store(key, value)
          end

          @data.freeze
          freeze
        end

        # Get a metadata value by key
        #
        # @param key [Symbol, String] the metadata key
        # @return [Object, nil] the value or nil if not present
        #
        # @example
        #   meta[:event]  # => "World Championship"
        #   meta["started_at"]  # => "2025-01-27T14:00:00Z"
        def [](key)
          @data[key.to_sym]
        end

        # Check if no metadata is present
        #
        # @return [Boolean] true if no fields are defined
        #
        # @example
        #   meta.empty?  # => true
        def empty?
          @data.empty?
        end

        # Get all metadata keys
        #
        # @return [Array<Symbol>] array of defined field keys
        #
        # @example
        #   meta.keys  # => [:event, :round, :platform]
        def keys
          @data.keys
        end

        # Check if a metadata field is present
        #
        # @param key [Symbol, String] the metadata key
        # @return [Boolean] true if the field is defined
        #
        # @example
        #   meta.key?(:event)  # => true
        #   meta.key?("round")  # => true
        def key?(key)
          @data.key?(key.to_sym)
        end

        # Iterate over each metadata field
        #
        # @yield [key, value] yields each key-value pair
        # @return [Enumerator] if no block given
        #
        # @example
        #   meta.each { |k, v| puts "#{k}: #{v}" }
        def each(&)
          return @data.each unless block_given?

          @data.each(&)
        end

        # Convert to hash representation
        #
        # @return [Hash] hash with all defined metadata fields
        #
        # @example
        #   meta.to_h
        #   # => {
        #   #   event: "Tournament",
        #   #   round: 5,
        #   #   started_at: "2025-01-27T14:00:00Z",
        #   #   platform: "lichess.org"
        #   # }
        def to_h
          @data.dup.freeze
        end

        # String representation for debugging
        #
        # @return [String] string representation
        def inspect
          "#<#{self.class.name} #{@data.inspect}>"
        end

        # Check equality with another Meta object
        #
        # @param other [Object] object to compare
        # @return [Boolean] true if equal
        def ==(other)
          return false unless other.is_a?(self.class)

          @data == other.to_h
        end

        alias eql? ==

        # Hash code for use in collections
        #
        # @return [Integer] hash code
        def hash
          @data.hash
        end

        private

        # Validate and store a field
        #
        # @param key [Symbol] the field key
        # @param value [Object] the field value
        # @raise [ArgumentError] if validation fails
        def validate_and_store(key, value)
          case key
          when :name
            validate_name(value)
          when :event
            validate_event(value)
          when :location
            validate_location(value)
          when :round
            validate_round(value)
          when :started_at
            validate_started_at(value)
          when :href
            validate_href(value)
          else
            # Custom fields are accepted without validation
            @data[key] = value
            return
          end

          # Store frozen value for standard string fields
          @data[key] = value.is_a?(::String) ? value.freeze : value
        end

        # Validate name field
        def validate_name(value)
          raise ::ArgumentError, ERROR_INVALID_NAME unless value.is_a?(::String)
        end

        # Validate event field
        def validate_event(value)
          raise ::ArgumentError, ERROR_INVALID_EVENT unless value.is_a?(::String)
        end

        # Validate location field
        def validate_location(value)
          raise ::ArgumentError, ERROR_INVALID_LOCATION unless value.is_a?(::String)
        end

        # Validate round field (must be integer >= 1)
        def validate_round(value)
          raise ::ArgumentError, ERROR_INVALID_ROUND unless value.is_a?(::Integer)
          raise ::ArgumentError, ERROR_INVALID_ROUND unless value >= 1
        end

        # Validate started_at field (ISO 8601 datetime format)
        # Accepts various ISO 8601 formats:
        # - 2025-01-27T14:00:00Z (UTC)
        # - 2025-01-27T14:00:00+02:00 (with timezone offset)
        # - 2025-01-27T14:00:00.123Z (with milliseconds)
        # - 2025-01-27T14:00:00 (local time, no timezone)
        def validate_started_at(value)
          raise ::ArgumentError, ERROR_INVALID_STARTED_AT unless value.is_a?(::String)
          raise ::ArgumentError, ERROR_INVALID_STARTED_AT unless value.match?(DATETIME_PATTERN)
        end

        # Validate href field (absolute URL with http:// or https://)
        def validate_href(value)
          raise ::ArgumentError, ERROR_INVALID_HREF unless value.is_a?(::String)
          raise ::ArgumentError, ERROR_INVALID_HREF unless value.match?(URL_PATTERN)
        end
      end
    end
  end
end
