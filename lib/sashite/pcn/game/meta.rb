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
      #     event: "World Championship",
      #     location: "London",
      #     round: 5,
      #     started_on: "2024-11-20",
      #     finished_at: "2024-11-20T18:45:00Z",
      #     href: "https://example.com/game/123"
      #   )
      #
      # @example With custom fields
      #   meta = Meta.new(
      #     event: "Tournament",
      #     platform: "lichess.org",
      #     time_control: "3+2",
      #     rated: true
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
        ERROR_INVALID_STARTED_ON = "started_on must be in ISO 8601 date format (YYYY-MM-DD)"
        ERROR_INVALID_FINISHED_AT = "finished_at must be in ISO 8601 datetime format with UTC (YYYY-MM-DDTHH:MM:SSZ)"
        ERROR_INVALID_HREF = "href must be an absolute URL (http:// or https://)"

        # Standard field keys
        STANDARD_FIELDS = %i[name event location round started_on finished_at href].freeze

        # Regular expressions for validation
        DATE_PATTERN = /\A\d{4}-\d{2}-\d{2}\z/
        DATETIME_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/
        URL_PATTERN = /\Ahttps?:\/\/.+/

        # Create a new Meta instance
        #
        # @param fields [Hash] metadata with optional standard and custom fields
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

        # Convert to hash representation
        #
        # @return [Hash] hash with all defined metadata fields
        #
        # @example
        #   meta.to_h
        #   # => { event: "Tournament", round: 5, platform: "lichess.org" }
        def to_h
          @data.dup.freeze
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
          when :started_on
            validate_started_on(value)
          when :finished_at
            validate_finished_at(value)
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

        # Validate started_on field (ISO 8601 date format)
        def validate_started_on(value)
          raise ::ArgumentError, ERROR_INVALID_STARTED_ON unless value.is_a?(::String)
          raise ::ArgumentError, ERROR_INVALID_STARTED_ON unless value.match?(DATE_PATTERN)
        end

        # Validate finished_at field (ISO 8601 datetime format with Z)
        def validate_finished_at(value)
          raise ::ArgumentError, ERROR_INVALID_FINISHED_AT unless value.is_a?(::String)
          raise ::ArgumentError, ERROR_INVALID_FINISHED_AT unless value.match?(DATETIME_PATTERN)
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
