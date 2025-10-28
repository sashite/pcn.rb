# frozen_string_literal: true

module Sashite
  module Pcn
    class Game
      class Sides
        # Represents a single player with optional metadata and time control
        #
        # All fields are optional. An empty Player object (no information) is valid.
        # The periods field defines time control settings for this player.
        #
        # @example Complete player with time control
        #   player = Player.new(
        #     name: "Carlsen",
        #     elo: 2830,
        #     style: "CHESS",
        #     periods: [
        #       { time: 5400, moves: 40, inc: 0 },    # 90 min for first 40 moves
        #       { time: 1800, moves: nil, inc: 30 }   # 30 min + 30s/move for rest
        #     ]
        #   )
        #
        # @example Fischer/Increment time control (5+3 blitz)
        #   player = Player.new(
        #     name: "Player 1",
        #     periods: [
        #       { time: 300, moves: nil, inc: 3 }     # 5 min + 3s increment
        #     ]
        #   )
        #
        # @example Byōyomi time control
        #   player = Player.new(
        #     name: "Yamada",
        #     style: "SHOGI",
        #     periods: [
        #       { time: 3600, moves: nil, inc: 0 },   # Main time: 1 hour
        #       { time: 60, moves: 1, inc: 0 },       # 60s per move (5 periods)
        #       { time: 60, moves: 1, inc: 0 },
        #       { time: 60, moves: 1, inc: 0 },
        #       { time: 60, moves: 1, inc: 0 },
        #       { time: 60, moves: 1, inc: 0 }
        #     ]
        #   )
        #
        # @example No time control (casual game)
        #   player = Player.new(name: "Casual Player", periods: [])
        #
        # @example Empty player
        #   player = Player.new  # Valid, no player information
        class Player
          # Error messages
          ERROR_INVALID_STYLE = "style must be a valid SNN string"
          ERROR_INVALID_NAME = "name must be a string"
          ERROR_INVALID_ELO = "elo must be a non-negative integer (>= 0)"
          ERROR_INVALID_PERIODS = "periods must be an array"
          ERROR_INVALID_PERIOD = "each period must be a hash"
          ERROR_MISSING_TIME = "period must have 'time' field"
          ERROR_INVALID_TIME = "time must be a non-negative integer (>= 0)"
          ERROR_INVALID_MOVES = "moves must be nil or a positive integer (>= 1)"
          ERROR_INVALID_INC = "inc must be a non-negative integer (>= 0)"

          # Create a new Player instance
          #
          # @param style [String, nil] player style in SNN format (optional)
          # @param name [String, nil] player name (optional)
          # @param elo [Integer, nil] player Elo rating (optional, >= 0)
          # @param periods [Array<Hash>, nil] time control periods (optional)
          # @raise [ArgumentError] if field values don't meet constraints
          def initialize(style: nil, name: nil, elo: nil, periods: nil)
            # Validate and assign style (optional)
            if style
              raise ::ArgumentError, ERROR_INVALID_STYLE unless style.is_a?(::String)
              @style = ::Sashite::Snn.parse(style)
            else
              @style = nil
            end

            # Validate and assign name (optional)
            if name
              raise ::ArgumentError, ERROR_INVALID_NAME unless name.is_a?(::String)
              @name = name.freeze
            else
              @name = nil
            end

            # Validate and assign elo (optional, must be >= 0)
            if elo
              raise ::ArgumentError, ERROR_INVALID_ELO unless elo.is_a?(::Integer)
              raise ::ArgumentError, ERROR_INVALID_ELO unless elo >= 0
              @elo = elo
            else
              @elo = nil
            end

            # Validate and assign periods
            periods = [] if periods.nil?

            raise ::ArgumentError, ERROR_INVALID_PERIODS unless periods.is_a?(::Array)
            @periods = validate_and_normalize_periods(periods).freeze

            freeze
          end

          # Get player style
          #
          # @return [Sashite::Snn::Name, nil] style or nil if not defined
          #
          # @example
          #   player.style  # => #<Sashite::Snn::Name ...>
          def style
            @style
          end

          # Get player name
          #
          # @return [String, nil] name or nil if not defined
          #
          # @example
          #   player.name  # => "Carlsen"
          def name
            @name
          end

          # Get player Elo rating
          #
          # @return [Integer, nil] elo or nil if not defined
          #
          # @example
          #   player.elo  # => 2830
          def elo
            @elo
          end

          # Get time control periods
          #
          # @return [Array<Hash>] periods if not defined
          #
          # @example
          #   player.periods
          #   # => [
          #   #   { time: 300, moves: nil, inc: 3 }
          #   # ]
          def periods
            @periods
          end

          # Check if player has time control
          #
          # @return [Boolean] true if periods are defined
          #
          # @example
          #   player.has_time_control?  # => true
          def has_time_control?
            !unlimited_time?
          end

          # Check if player has unlimited time (no time control)
          #
          # @return [Boolean] true if periods is empty array or nil
          #
          # @example
          #   player.unlimited_time?  # => false
          def unlimited_time?
            @periods.empty?
          end

          # Get initial time budget (sum of all period times)
          #
          # @return [Integer, nil] total seconds or nil if no periods
          #
          # @example
          #   player.initial_time_budget  # => 7200 (2 hours)
          def initial_time_budget
            return if unlimited_time?

            @periods.sum { |period| period[:time] }
          end

          # Check if no player information is present
          #
          # @return [Boolean] true if all fields are nil
          #
          # @example
          #   player.empty?  # => true
          def empty?
            @style.nil? && @name.nil? && @elo.nil? && @periods.empty?
          end

          # Convert to hash representation
          #
          # Returns a hash containing only defined (non-nil) fields.
          # If all fields are nil, returns an empty hash.
          #
          # @return [Hash] hash with :style, :name, :elo, and/or :periods keys
          #
          # @example Complete player
          #   player.to_h
          #   # => {
          #   #   style: "CHESS",
          #   #   name: "Carlsen",
          #   #   elo: 2830,
          #   #   periods: [
          #   #     { time: 5400, moves: 40, inc: 0 },
          #   #     { time: 1800, moves: nil, inc: 30 }
          #   #   ]
          #   # }
          #
          # @example Partial player
          #   player.to_h
          #   # => { name: "Alice", periods: [] }
          #
          # @example Empty player
          #   player.to_h
          #   # => {}
          def to_h
            result = {}
            result[:style] = @style.to_s unless @style.nil?
            result[:name] = @name unless @name.nil?
            result[:elo] = @elo unless @elo.nil?
            result[:periods] = @periods unless @periods.empty?
            result
          end

          # String representation for debugging
          #
          # @return [String] string representation
          def inspect
            attrs = []
            attrs << "style=#{@style.inspect}" if @style
            attrs << "name=#{@name.inspect}" if @name
            attrs << "elo=#{@elo.inspect}" if @elo
            attrs << "periods=#{@periods.inspect}" if @periods.any?

            "#<#{self.class.name} #{attrs.join(' ')}>"
          end

          # Check equality with another Player object
          #
          # @param other [Object] object to compare
          # @return [Boolean] true if equal
          def ==(other)
            return false unless other.is_a?(self.class)

            @style == other.style &&
              @name == other.name &&
              @elo == other.elo &&
              @periods == other.periods
          end

          alias eql? ==

          # Hash code for use in collections
          #
          # @return [Integer] hash code
          def hash
            [@style, @name, @elo, @periods].hash
          end

          private

          # Validate and normalize periods array
          #
          # @param periods [Array<Hash>] array of period hashes
          # @return [Array<Hash>] normalized periods with all required fields
          # @raise [ArgumentError] if any period is invalid
          def validate_and_normalize_periods(periods)
            periods.map.with_index do |period, index|
              validate_and_normalize_period(period, index)
            end
          end

          # Validate and normalize a single period
          #
          # @param period [Hash] period hash
          # @param index [Integer] index for error messages
          # @return [Hash] normalized period with time, moves, and inc fields
          # @raise [ArgumentError] if period is invalid
          def validate_and_normalize_period(period, index)
            raise ::ArgumentError, "#{ERROR_INVALID_PERIOD} at index #{index}" unless period.is_a?(::Hash)

            # Convert keys to symbols for consistent access
            period = period.transform_keys(&:to_sym)

            # Validate required 'time' field
            raise ::ArgumentError, "#{ERROR_MISSING_TIME} at index #{index}" unless period.key?(:time)

            time = period[:time]
            raise ::ArgumentError, "#{ERROR_INVALID_TIME} at index #{index}" unless time.is_a?(::Integer) && time >= 0

            # Validate optional 'moves' field (nil or integer >= 1)
            moves = period[:moves]
            unless moves.nil? || (moves.is_a?(::Integer) && moves >= 1)
              raise ::ArgumentError, "#{ERROR_INVALID_MOVES} at index #{index}"
            end

            # Validate optional 'inc' field (defaults to 0)
            inc = period.fetch(:inc, 0)
            raise ::ArgumentError, "#{ERROR_INVALID_INC} at index #{index}" unless inc.is_a?(::Integer) && inc >= 0

            # Return normalized period with all three fields
            {
              time:  time,
              moves: moves,
              inc:   inc
            }.freeze
          end
        end
      end
    end
  end
end
