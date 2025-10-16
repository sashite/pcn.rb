# frozen_string_literal: true

module Sashite
  module Pcn
    class Game
      class Sides
        # Represents a single player with optional metadata
        #
        # All fields are optional. An empty Player object (no information) is valid.
        #
        # @example Complete player
        #   player = Player.new(name: "Carlsen", elo: 2830, style: "CHESS")
        #
        # @example Minimal player
        #   player = Player.new(name: "Player 1")
        #
        # @example Empty player
        #   player = Player.new  # Valid, no player information
        class Player
          # Error messages
          ERROR_INVALID_STYLE = "style must be a valid SNN string"
          ERROR_INVALID_NAME = "name must be a string"
          ERROR_INVALID_ELO = "elo must be a non-negative integer (>= 0)"

          # Create a new Player instance
          #
          # @param style [String, nil] player style in SNN format (optional)
          # @param name [String, nil] player name (optional)
          # @param elo [Integer, nil] player Elo rating (optional, >= 0)
          # @raise [ArgumentError] if field values don't meet constraints
          def initialize(style: nil, name: nil, elo: nil)
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

          # Check if no player information is present
          #
          # @return [Boolean] true if all fields are nil
          #
          # @example
          #   player.empty?  # => true
          def empty?
            @style.nil? && @name.nil? && @elo.nil?
          end

          # Convert to hash representation
          #
          # Returns a hash containing only defined (non-nil) fields.
          # If all fields are nil, returns an empty hash.
          #
          # @return [Hash] hash with :style, :name, and/or :elo keys
          #
          # @example Complete player
          #   player.to_h
          #   # => { style: "CHESS", name: "Carlsen", elo: 2830 }
          #
          # @example Partial player
          #   player.to_h
          #   # => { name: "Alice" }
          #
          # @example Empty player
          #   player.to_h
          #   # => {}
          def to_h
            result = {}
            result[:style] = @style.to_s unless @style.nil?
            result[:name] = @name unless @name.nil?
            result[:elo] = @elo unless @elo.nil?
            result
          end
        end
      end
    end
  end
end
