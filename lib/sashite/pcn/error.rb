# frozen_string_literal: true

module Sashite
  module Pcn
    # Base error class for all PCN-related errors.
    #
    # @see https://sashite.dev/specs/pcn/1.0.0/
    class Error < ::StandardError
      # Error raised when PCN structure parsing fails.
      #
      # This occurs when the PCN hash structure is malformed or missing
      # required fields.
      #
      # @example
      #   raise Error::Parse, "Missing required field 'setup'"
      class Parse < Error; end

      # Error raised when PCN format validation fails.
      #
      # This occurs when field values do not conform to their expected
      # formats (e.g., invalid FEEN string, invalid PMN array, invalid
      # status value).
      #
      # @example
      #   raise Error::Validation, "Invalid status value: 'unknown'"
      class Validation < Error; end

      # Error raised when PCN semantic consistency validation fails.
      #
      # This occurs when field combinations violate semantic rules
      # (e.g., SNN/SIN case consistency, invalid player object structure).
      #
      # @example
      #   raise Error::Semantic, "SNN 'CHESS' does not match SIN 'c' in FEEN"
      class Semantic < Error; end
    end
  end
end
