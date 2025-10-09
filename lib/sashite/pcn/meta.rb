# frozen_string_literal: true

module Sashite
  module Pcn
    # Immutable representation of game metadata.
    #
    # All fields are optional. Metadata provides contextual information
    # about the game session.
    #
    # @see https://sashite.dev/specs/pcn/1.0.0/
    class Meta
      # ISO 8601 date format: YYYY-MM-DD
      DATE_PATTERN = /\A\d{4}-\d{2}-\d{2}\z/

      # ISO 8601 datetime format with UTC timezone: YYYY-MM-DDTHH:MM:SSZ
      DATETIME_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/

      # Absolute URL pattern (http:// or https://)
      URL_PATTERN = %r{\Ahttps?://.+\z}

      # @return [String, nil] Game name or opening identification
      attr_reader :name

      # @return [String, nil] Tournament or event name
      attr_reader :event

      # @return [String, nil] Physical or virtual venue
      attr_reader :location

      # @return [Integer, nil] Round number in tournament context
      attr_reader :round

      # @return [String, nil] Game start date (ISO 8601: YYYY-MM-DD)
      attr_reader :started_on

      # @return [String, nil] Game completion timestamp (ISO 8601 UTC: YYYY-MM-DDTHH:MM:SSZ)
      attr_reader :finished_at

      # @return [String, nil] Reference link to external resource
      attr_reader :href

      # Parse a meta hash into a Meta object.
      #
      # @param hash [Hash] Metadata hash
      # @return [Meta] Immutable meta object
      # @raise [Error::Validation] If validation fails
      #
      # @example
      #   meta = Meta.parse({
      #     "event" => "World Championship",
      #     "round" => 5
      #   })
      def self.parse(hash)
        raise Error::Validation, "Meta must be a Hash, got #{hash.class}" unless hash.is_a?(::Hash)

        new(
          name:        hash["name"],
          event:       hash["event"],
          location:    hash["location"],
          round:       hash["round"],
          started_on:  hash["started_on"],
          finished_at: hash["finished_at"],
          href:        hash["href"]
        )
      end

      # Validate a meta hash without raising exceptions.
      #
      # @param hash [Hash] Metadata hash
      # @return [Boolean] true if valid, false otherwise
      #
      # @example
      #   Meta.valid?({ "event" => "Tournament" })  # => true
      def self.valid?(hash)
        parse(hash)
        true
      rescue Error
        false
      end

      # Create a new Meta.
      #
      # @param name [String, nil] Game name
      # @param event [String, nil] Event name
      # @param location [String, nil] Location
      # @param round [Integer, nil] Round number
      # @param started_on [String, nil] Start date (YYYY-MM-DD)
      # @param finished_at [String, nil] Finish timestamp (YYYY-MM-DDTHH:MM:SSZ)
      # @param href [String, nil] Reference URL
      # @raise [Error::Validation] If validation fails
      #
      # @example
      #   meta = Meta.new(
      #     event: "World Championship",
      #     round: 5,
      #     started_on: "2025-11-15"
      #   )
      def initialize(name: nil, event: nil, location: nil, round: nil, started_on: nil, finished_at: nil, href: nil)
        @name = name
        @event = event
        @location = location
        @round = round
        @started_on = started_on
        @finished_at = finished_at
        @href = href

        validate!

        freeze
      end

      # Check if the meta is valid.
      #
      # @return [Boolean] true if valid
      def valid?
        validate!
        true
      rescue Error
        false
      end

      # Check if metadata is empty (all fields nil).
      #
      # @return [Boolean] true if all fields are nil
      def empty?
        name.nil? && event.nil? && location.nil? && round.nil? &&
          started_on.nil? && finished_at.nil? && href.nil?
      end

      # Convert to hash representation.
      #
      # @return [Hash] Metadata hash (excludes nil values)
      #
      # @example
      #   meta.to_h  # => { "event" => "Tournament", "round" => 5 }
      def to_h
        hash = {}

        hash["name"] = name unless name.nil?
        hash["event"] = event unless event.nil?
        hash["location"] = location unless location.nil?
        hash["round"] = round unless round.nil?
        hash["started_on"] = started_on unless started_on.nil?
        hash["finished_at"] = finished_at unless finished_at.nil?
        hash["href"] = href unless href.nil?

        hash
      end

      # String representation.
      #
      # @return [String] Inspectable representation
      def to_s
        fields = []
        fields << "event=#{event.inspect}" unless event.nil?
        fields << "round=#{round}" unless round.nil?
        fields << "location=#{location.inspect}" unless location.nil?

        "#<#{self.class} #{fields.join(' ')}>"
      end
      alias inspect to_s

      # Equality comparison.
      #
      # @param other [Meta] Other meta
      # @return [Boolean] true if equal
      def ==(other)
        other.is_a?(self.class) &&
          other.name == name &&
          other.event == event &&
          other.location == location &&
          other.round == round &&
          other.started_on == started_on &&
          other.finished_at == finished_at &&
          other.href == href
      end
      alias eql? ==

      # Hash code for equality.
      #
      # @return [Integer] Hash code
      def hash
        [self.class, name, event, location, round, started_on, finished_at, href].hash
      end

      private

      # Validate all fields.
      def validate!
        validate_name!
        validate_event!
        validate_location!
        validate_round!
        validate_started_on!
        validate_finished_at!
        validate_href!
      end

      # Validate name field.
      def validate_name!
        return if name.nil?

        return if name.is_a?(::String)

        raise Error::Validation, "Meta 'name' must be a String, got #{name.class}"
      end

      # Validate event field.
      def validate_event!
        return if event.nil?

        return if event.is_a?(::String)

        raise Error::Validation, "Meta 'event' must be a String, got #{event.class}"
      end

      # Validate location field.
      def validate_location!
        return if location.nil?

        return if location.is_a?(::String)

        raise Error::Validation, "Meta 'location' must be a String, got #{location.class}"
      end

      # Validate round field.
      def validate_round!
        return if round.nil?

        raise Error::Validation, "Meta 'round' must be an Integer, got #{round.class}" unless round.is_a?(::Integer)

        return unless round < 1

        raise Error::Validation, "Meta 'round' must be >= 1, got #{round}"
      end

      # Validate started_on field.
      def validate_started_on!
        return if started_on.nil?

        unless started_on.is_a?(::String)
          raise Error::Validation, "Meta 'started_on' must be a String, got #{started_on.class}"
        end

        return if DATE_PATTERN.match?(started_on)

        raise Error::Validation, "Meta 'started_on' must match format YYYY-MM-DD, got #{started_on.inspect}"
      end

      # Validate finished_at field.
      def validate_finished_at!
        return if finished_at.nil?

        unless finished_at.is_a?(::String)
          raise Error::Validation, "Meta 'finished_at' must be a String, got #{finished_at.class}"
        end

        return if DATETIME_PATTERN.match?(finished_at)

        raise Error::Validation, "Meta 'finished_at' must match format YYYY-MM-DDTHH:MM:SSZ, got #{finished_at.inspect}"
      end

      # Validate href field.
      def validate_href!
        return if href.nil?

        raise Error::Validation, "Meta 'href' must be a String, got #{href.class}" unless href.is_a?(::String)

        return if URL_PATTERN.match?(href)

        raise Error::Validation, "Meta 'href' must be an absolute URL (http:// or https://), got #{href.inspect}"
      end
    end
  end
end
