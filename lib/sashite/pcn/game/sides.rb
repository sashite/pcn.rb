# frozen_string_literal: true

require_relative "sides/player"

module Sashite
  module Pcn
    class Game
      # Represents player information for both sides of a game
      #
      # Manages two Player objects (first and second) with support for
      # player metadata, styles, and time control settings. Both players
      # are optional and default to empty player objects.
      #
      # @example With both players and time control
      #   sides = Sides.new(
      #     first: {
      #       name: "Carlsen",
      #       elo: 2830,
      #       style: "CHESS",
      #       periods: [
      #         { time: 5400, moves: 40, inc: 0 },
      #         { time: 1800, moves: nil, inc: 30 }
      #       ]
      #     },
      #     second: {
      #       name: "Nakamura",
      #       elo: 2794,
      #       style: "chess",
      #       periods: [
      #         { time: 5400, moves: 40, inc: 0 },
      #         { time: 1800, moves: nil, inc: 30 }
      #       ]
      #     }
      #   )
      #
      # @example With Fischer time control (5+3 blitz)
      #   sides = Sides.new(
      #     first: {
      #       name: "Alice",
      #       periods: [{ time: 300, moves: nil, inc: 3 }]
      #     },
      #     second: {
      #       name: "Bob",
      #       periods: [{ time: 300, moves: nil, inc: 3 }]
      #     }
      #   )
      #
      # @example With only first player
      #   sides = Sides.new(
      #     first: { name: "Player 1", style: "CHESS" }
      #   )
      #
      # @example Empty sides (no player information)
      #   sides = Sides.new  # Both players default to empty
      class Sides
        # Error messages
        ERROR_INVALID_FIRST = "first must be a hash"
        ERROR_INVALID_SECOND = "second must be a hash"

        # Create a new Sides instance
        #
        # @param first [Hash] first player information (defaults to {})
        # @param second [Hash] second player information (defaults to {})
        # @raise [ArgumentError] if parameters are not hashes
        def initialize(first: {}, second: {})
          raise ::ArgumentError, ERROR_INVALID_FIRST unless first.is_a?(::Hash)
          raise ::ArgumentError, ERROR_INVALID_SECOND unless second.is_a?(::Hash)

          @first = Player.new(**first.transform_keys(&:to_sym))
          @second = Player.new(**second.transform_keys(&:to_sym))

          freeze
        end

        # Get first player information
        #
        # @return [Player] first player (may be empty)
        #
        # @example
        #   player = sides.first
        #   player.name     # => "Carlsen"
        #   player.periods  # => [{ time: 5400, moves: 40, inc: 0 }, ...]
        def first
          @first
        end

        # Get second player information
        #
        # @return [Player] second player (may be empty)
        #
        # @example
        #   player = sides.second
        #   player.name     # => "Nakamura"
        #   player.elo      # => 2794
        def second
          @second
        end

        # Access player by index
        #
        # @param index [Integer] 0 for first, 1 for second
        # @return [Player, nil] player or nil if index out of bounds
        #
        # @example
        #   sides[0]  # => first player
        #   sides[1]  # => second player
        #   sides[2]  # => nil
        def [](index)
          case index
          when 0 then @first
          when 1 then @second
          end
        end

        # Get player by side
        #
        # @param side [Symbol, String] :first or :second
        # @return [Player, nil] player or nil if invalid side
        #
        # @example
        #   sides.player(:first)   # => first player
        #   sides.player("second") # => second player
        def player(side)
          case side.to_sym
          when :first then @first
          when :second then @second
          end
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

        # Check if both players have information
        #
        # @return [Boolean] true if both players have data
        #
        # @example
        #   sides.complete?  # => true
        def complete?
          !@first.empty? && !@second.empty?
        end

        # Check if both players have same time control
        #
        # @return [Boolean] true if periods match
        #
        # @example
        #   sides.symmetric_time_control?  # => true
        def symmetric_time_control?
          @first.periods == @second.periods
        end

        # Check if both players have time control
        #
        # @return [Boolean] true if both have periods defined
        #
        # @example
        #   sides.both_have_time_control?  # => true
        def both_have_time_control?
          @first.has_time_control? && @second.has_time_control?
        end

        # Check if neither player has time control
        #
        # @return [Boolean] true if both have unlimited time
        #
        # @example
        #   sides.unlimited_game?  # => false
        def unlimited_game?
          @first.unlimited_time? && @second.unlimited_time?
        end

        # Check if players have different time controls
        #
        # Returns true when the two players have different time control settings.
        # This is the logical opposite of symmetric_time_control?.
        #
        # @return [Boolean] true if time controls differ
        #
        # @example Different periods
        #   # First: 5+3 blitz, Second: 10 minutes
        #   sides.mixed_time_control?  # => true
        #
        # @example One with time control, one without
        #   # First: 5+3 blitz, Second: nil (unlimited)
        #   sides.mixed_time_control?  # => true
        #
        # @example Both unlimited (but different representation)
        #   # First: [], Second: nil
        #   sides.mixed_time_control?  # => true
        #
        # @example Identical time controls
        #   # Both: 5+3 blitz
        #   sides.mixed_time_control?  # => false
        #
        # @example Both unlimited (same representation)
        #   # Both: nil
        #   sides.mixed_time_control?  # => false
        def mixed_time_control?
          !symmetric_time_control?
        end

        # Get both players' names
        #
        # @return [Array<String>] array of [first_name, second_name]
        #
        # @example
        #   sides.names  # => ["Carlsen", "Nakamura"]
        def names
          [@first.name, @second.name]
        end

        # Get both players' Elo ratings
        #
        # @return [Array<Integer>] array of [first_elo, second_elo]
        #
        # @example
        #   sides.elos  # => [2830, 2794]
        def elos
          [@first.elo, @second.elo]
        end

        # Get both players' styles
        #
        # @return [Array<String>] array of [first_style, second_style]
        #
        # @example
        #   sides.styles  # => ["CHESS", "chess"]
        def styles
          [
            @first.style&.to_s,
            @second.style&.to_s
          ]
        end

        # Get both players' time budgets
        #
        # @return [Array<Integer>] array of [first_time, second_time]
        #
        # @example
        #   sides.time_budgets  # => [7200, 7200]
        def time_budgets
          [
            @first.initial_time_budget,
            @second.initial_time_budget
          ]
        end

        # Iterate over both players
        #
        # @yield [player] yields each player
        # @return [Enumerator] if no block given
        #
        # @example
        #   sides.each { |player| puts player.name }
        #   sides.each.with_index { |player, i| puts "Player #{i+1}: #{player.name}" }
        def each
          return enum_for(:each) unless block_given?

          yield @first
          yield @second
        end

        # Map over both players
        #
        # @yield [player] yields each player
        # @return [Array] results of block for each player
        #
        # @example
        #   sides.map(&:name)  # => ["Carlsen", "Nakamura"]
        #   sides.map(&:elo)   # => [2830, 2794]
        def map(&)
          return enum_for(:map) unless block_given?

          [@first, @second].map(&)
        end

        # Get array of both players
        #
        # @return [Array<Player>] [first, second]
        #
        # @example
        #   sides.to_a  # => [#<Player ...>, #<Player ...>]
        def to_a
          [@first, @second]
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
        #   # => {
        #   #   first: {
        #   #     name: "Carlsen",
        #   #     elo: 2830,
        #   #     style: "CHESS",
        #   #     periods: [{ time: 5400, moves: 40, inc: 0 }]
        #   #   },
        #   #   second: {
        #   #     name: "Nakamura",
        #   #     elo: 2794,
        #   #     style: "chess",
        #   #     periods: [{ time: 5400, moves: 40, inc: 0 }]
        #   #   }
        #   # }
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

        # String representation for debugging
        #
        # @return [String] string representation
        def inspect
          players = []
          players << "first=#{@first.name || '(empty)'}"
          players << "second=#{@second.name || '(empty)'}"

          "#<#{self.class.name} #{players.join(' ')}>"
        end

        # Check equality with another Sides object
        #
        # @param other [Object] object to compare
        # @return [Boolean] true if equal
        def ==(other)
          return false unless other.is_a?(self.class)

          @first == other.first && @second == other.second
        end

        alias eql? ==

        # Hash code for use in collections
        #
        # @return [Integer] hash code
        def hash
          [@first, @second].hash
        end

        # Check if a specific side is present
        #
        # @param side [Symbol, String] :first or :second
        # @return [Boolean] true if that player has data
        #
        # @example
        #   sides.has_player?(:first)   # => true
        #   sides.has_player?("second")  # => false
        def has_player?(side)
          player = player(side)
          player && !player.empty?
        end

        # Get time control description
        #
        # @return [String, nil] human-readable time control or nil
        #
        # @example
        #   sides.time_control_description
        #   # => "5+3 blitz (both players)"
        #   # => "Classical 90+30 (symmetric)"
        #   # => "Unlimited time"
        #   # => "Mixed: first has 5+3, second unlimited"
        def time_control_description
          if unlimited_game?
            "Unlimited time"
          elsif mixed_time_control?
            first_tc = describe_periods(@first.periods)
            second_tc = describe_periods(@second.periods)
            "Mixed: first #{first_tc}, second #{second_tc}"
          elsif symmetric_time_control?
            tc = describe_periods(@first.periods)
            "#{tc} (symmetric)"
          else
            first_tc = describe_periods(@first.periods)
            second_tc = describe_periods(@second.periods)
            "First: #{first_tc}, Second: #{second_tc}"
          end
        end

        private

        # Describe time control periods in human-readable format
        #
        # @param periods [Array<Hash>] period array
        # @return [String] description
        def describe_periods(periods)
          return "unlimited" if periods.empty?

          if periods.length == 1 && periods[0][:moves].nil?
            period = periods[0]
            time_min = period[:time] / 60
            inc = period[:inc]

            if inc > 0
              "#{time_min}+#{inc}"
            else
              "#{time_min} min"
            end
          elsif periods.any? { |p| p[:moves] == 1 }
            "Byōyomi"
          elsif periods.any? { |p| p[:moves] && p[:moves] > 1 }
            "Canadian"
          else
            "Classical #{periods.length} periods"
          end
        end
      end
    end
  end
end
