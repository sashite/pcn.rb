# Pcn.rb

[![Version](https://img.shields.io/github/v/tag/sashite/pcn.rb?label=Version&logo=github)](https://github.com/sashite/pcn.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/pcn.rb/main)
![Ruby](https://github.com/sashite/pcn.rb/actions/workflows/main.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/sashite/pcn.rb?label=License&logo=github)](https://github.com/sashite/pcn.rb/raw/main/LICENSE.md)

> **PCN** (Portable Chess Notation) implementation for the Ruby language.

## What is PCN?

PCN (Portable Chess Notation) is a comprehensive, JSON-based format for representing complete chess game records across variants. PCN integrates the Sashité ecosystem specifications (PMN, FEEN, and SNN) to create a unified, rule-agnostic game recording system that supports both traditional single-variant games and cross-variant scenarios.

This gem implements the [PCN Specification v1.0.0](https://sashite.dev/specs/pcn/1.0.0/) as a pure functional library with immutable data structures, providing a clean Ruby interface for parsing, validating, and generating PCN game records.

## Installation

```ruby
# In your Gemfile
gem "sashite-pcn"
```

Or install manually:

```sh
gem install sashite-pcn
```

## Dependencies

PCN builds upon three foundational Sashité specifications:

```ruby
gem "sashite-pmn"   # Portable Move Notation
gem "sashite-feen"  # Forsyth-Edwards Enhanced Notation
gem "sashite-snn"   # Style Name Notation
```

## Quick Start

```ruby
require "sashite/pcn"

# Parse a PCN hash
game = Sashite::Pcn.parse({
  "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  "moves" => [
    ["e2", "e4", "C:P"],
    ["e7", "e5", "c:p"]
  ],
  "status" => "in_progress"
})

# Access game components
game.setup                    # => #<Sashite::Feen::Position ...>
game.moves                    # => [#<Sashite::Pmn::Move ...>, ...]
game.status                   # => "in_progress"
game.valid?                   # => true

# Convert back to hash
game.to_h                     # => { "setup" => "...", "moves" => [...], ... }
```

## JSON Integration

This gem focuses on the core PCN data structures and does not include JSON parsing/dumping. Use your preferred JSON library:

```ruby
require "json"
require "sashite/pcn"

# Load from JSON file
json_string = File.read("game.json")
pcn_hash = JSON.parse(json_string)
game = Sashite::Pcn.parse(pcn_hash)

# Save to JSON file
File.write("game.json", JSON.pretty_generate(game.to_h))

# Or with Oj for better performance
require "oj"
game = Sashite::Pcn.parse(Oj.load_file("game.json"))
Oj.to_file("game.json", game.to_h)
```

## PCN Format

A PCN document is a hash with five fields:

```ruby
{
  "meta" => {                               # Optional metadata
    "name" => String,
    "event" => String,
    "location" => String,
    "round" => Integer,
    "started_on" => "YYYY-MM-DD",
    "finished_at" => "YYYY-MM-DDTHH:MM:SSZ",
    "href" => String
  },
  "sides" => {                              # Optional player information
    "first" => {
      "style" => String,                    # SNN format
      "name" => String,
      "elo" => Integer
    },
    "second" => {
      "style" => String,
      "name" => String,
      "elo" => Integer
    }
  },
  "setup" => String,                        # Required: FEEN position
  "moves" => Array,                         # Required: PMN arrays
  "status" => String                        # Optional: game status
}
```

Only `setup` and `moves` are required. See the [PCN Specification](https://sashite.dev/specs/pcn/1.0.0/) for complete format details.

## Usage

### Parsing Game Records

```ruby
# From hash
game_hash = {
  "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  "moves" => [["e2", "e4", "C:P"]],
  "status" => "in_progress"
}
game = Sashite::Pcn.parse(game_hash)

# Validation without exception
Sashite::Pcn.valid?(game_hash)              # => true
Sashite::Pcn.valid?({ "setup" => "" })      # => false
```

### Creating Game Records

```ruby
# Create a new game from components
game = Sashite::Pcn.new(
  setup: Sashite::Feen.parse("+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"),
  moves: [
    Sashite::Pmn.parse(["e2", "e4", "C:P"]),
    Sashite::Pmn.parse(["e7", "e5", "c:p"])
  ],
  status: "in_progress",
  meta: Sashite::Pcn::Meta.new(
    event: "World Championship",
    round: 5
  ),
  sides: Sashite::Pcn::Sides.new(
    first: Sashite::Pcn::Player.new(name: "Alice", elo: 2800, style: "CHESS"),
    second: Sashite::Pcn::Player.new(name: "Bob", elo: 2750, style: "chess")
  )
)
```

### Accessing Game Data

```ruby
game = Sashite::Pcn.parse(pcn_hash)

# Required fields
game.setup                                   # => Feen::Position
game.setup.to_s                              # => FEEN string
game.moves                                   # => Array of Pmn::Move
game.moves.size                              # => Number of moves
game.moves.first.to_a                        # => PMN array

# Optional fields (may be nil)
game.status                                  # => "in_progress" or nil
game.meta                                    # => Meta object or nil
game.sides                                   # => Sides object or nil

# Metadata access (when present)
game.meta&.event                             # => "World Championship"
game.meta&.round                             # => 5
game.meta&.started_on                        # => "2025-11-15"
game.meta&.finished_at                       # => "2025-11-15T18:45:00Z"

# Player information (when present)
game.sides&.first&.name                      # => "Alice"
game.sides&.first&.elo                       # => 2800
game.sides&.first&.style                     # => "CHESS"
game.sides&.second&.name                     # => "Bob"
```

### Validation

```ruby
# Structural validation
game.valid?                                  # => true/false

# Detailed validation with errors
begin
  Sashite::Pcn.parse(invalid_hash)
rescue Sashite::Pcn::Error => e
  puts e.message
  puts e.class  # Specific error type
end

# Validate individual components
Sashite::Pcn::Meta.valid?(meta_hash)        # => true/false
Sashite::Pcn::Sides.valid?(sides_hash)      # => true/false
Sashite::Pcn::Player.valid?(player_hash)    # => true/false
```

### Working with Moves

```ruby
# Add moves to a game (returns new game)
game = Sashite::Pcn.parse(pcn_hash)
new_move = Sashite::Pmn.parse(["g1", "f3", "C:N"])
updated_game = game.add_move(new_move)

# Iterate over moves
game.moves.each_with_index do |move, index|
  player = index.even? ? "First player" : "Second player"
  puts "#{player}: #{move.to_a.inspect}"
end

# Get move count
game.move_count                              # => 2
game.empty?                                  # => false
```

### Immutable Transformations

```ruby
# All transformations return new instances
original = Sashite::Pcn.parse(pcn_hash)

# Update status
finished = original.with_status("checkmate")
finished.status                              # => "checkmate"
original.status                              # => "in_progress" (unchanged)

# Update metadata
with_meta = original.with_meta(
  Sashite::Pcn::Meta.new(event: "Tournament")
)

# Chain transformations
result = original
  .with_status("checkmate")
  .add_move(new_move)
  .with_meta(updated_meta)
```

## Format Specification

### Document Structure

```ruby
{
  "meta" => {                               # Optional metadata
    "name" => String,
    "event" => String,
    "location" => String,
    "round" => Integer,
    "started_on" => "YYYY-MM-DD",
    "finished_at" => "YYYY-MM-DDTHH:MM:SSZ",
    "href" => String
  },
  "sides" => {                              # Optional player information
    "first" => {
      "style" => String,                    # SNN format
      "name" => String,
      "elo" => Integer
    },
    "second" => {
      "style" => String,
      "name" => String,
      "elo" => Integer
    }
  },
  "setup" => String,                        # Required: FEEN position
  "moves" => Array,                         # Required: PMN arrays
  "status" => String                        # Optional: game status
}
```

### Valid Status Values

- `"in_progress"` - Game ongoing
- `"checkmate"` - Terminal piece checkmated
- `"stalemate"` - No legal moves available
- `"bare_king"` - Only terminal piece remains
- `"mare_king"` - Terminal piece captured
- `"resignation"` - Player resigned
- `"illegal_move"` - Illegal move performed
- `"time_limit"` - Time exceeded
- `"move_limit"` - Move limit reached
- `"repetition"` - Position repetition
- `"mutual_agreement"` - Players agreed to end

## API Reference

### Main Module Methods

- `Sashite::Pcn.parse(hash)` - Parse hash into Game object
- `Sashite::Pcn.valid?(hash)` - Validate without raising exceptions
- `Sashite::Pcn.new(**attributes)` - Create game from components

### Game Class

#### Creation
- `Sashite::Pcn::Game.new(setup:, moves:, status: nil, meta: nil, sides: nil)`

#### Attributes (read-only)
- `#setup` - Feen::Position object (required)
- `#moves` - Array of Pmn::Move objects (required)
- `#status` - String or nil (optional)
- `#meta` - Meta object or nil (optional)
- `#sides` - Sides object or nil (optional)

#### Queries
- `#valid?` - Check overall validity
- `#move_count` / `#size` - Number of moves
- `#empty?` - No moves played
- `#has_status?` - Status field present
- `#has_meta?` - Metadata present
- `#has_sides?` - Player information present

#### Transformations (immutable)
- `#add_move(pmn_move)` - Add move (returns new game)
- `#with_status(status)` - Update status (returns new game)
- `#with_meta(meta)` - Update metadata (returns new game)
- `#with_sides(sides)` - Update player info (returns new game)

#### Conversion
- `#to_h` - Convert to hash
- `#to_s` - Alias for pretty-printed hash representation

### Meta Class

- `Sashite::Pcn::Meta.new(**attributes)`
- `#name`, `#event`, `#location`, `#round`
- `#started_on`, `#finished_at`, `#href`
- `#to_h` - Convert to hash
- `Meta.valid?(hash)` - Validate metadata

### Sides Class

- `Sashite::Pcn::Sides.new(first:, second:)`
- `#first` - First player (Player object or nil)
- `#second` - Second player (Player object or nil)
- `#to_h` - Convert to hash
- `Sides.valid?(hash)` - Validate sides

### Player Class

- `Sashite::Pcn::Player.new(style: nil, name: nil, elo: nil)`
- `#style` - SNN style name or nil
- `#name` - Player name or nil
- `#elo` - Elo rating or nil
- `#to_h` - Convert to hash
- `Player.valid?(hash)` - Validate player

### Exceptions

- `Sashite::Pcn::Error` - Base error class
- `Sashite::Pcn::ParseError` - Structure parsing failed
- `Sashite::Pcn::ValidationError` - Format validation failed
- `Sashite::Pcn::SemanticError` - Semantic consistency violation

## Examples

### Traditional Chess Game

```ruby
chess_game = Sashite::Pcn.parse({
  "meta" => {
    "event" => "World Championship",
    "round" => 5,
    "started_on" => "2025-11-15"
  },
  "sides" => {
    "first" => {
      "name" => "Magnus Carlsen",
      "elo" => 2830,
      "style" => "CHESS"
    },
    "second" => {
      "name" => "Fabiano Caruana",
      "elo" => 2820,
      "style" => "chess"
    }
  },
  "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  "moves" => [
    ["e2", "e4", "C:P"],
    ["e7", "e5", "c:p"],
    ["g1", "f3", "C:N"],
    ["b8", "c6", "c:n"]
  ],
  "status" => "in_progress"
})

chess_game.move_count                        # => 4
chess_game.sides.first.name                  # => "Magnus Carlsen"
```

### Cross-Style Game

```ruby
hybrid_game = Sashite::Pcn.parse({
  "sides" => {
    "first" => { "style" => "CHESS" },
    "second" => { "style" => "makruk" }
  },
  "setup" => "rnsmksnr/8/pppppppp/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/m",
  "moves" => [
    ["e2", "e4", "C:P"],
    ["d6", "d5", "m:p"]
  ],
  "status" => "in_progress"
})
```

### Shōgi Game

```ruby
shogi_game = Sashite::Pcn.parse({
  "setup" => "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL / S/s",
  "moves" => [
    ["e1", "e2", "S:P"],
    ["*", "e5", "s:p"]  # Drop from hand
  ],
  "status" => "in_progress"
})
```

### Minimal Valid Game

```ruby
minimal = Sashite::Pcn.parse({
  "setup" => "8/8/8/8/8/8/8/8 / C/c",
  "moves" => []
})

minimal.valid?                               # => true
minimal.empty?                               # => true
minimal.has_status?                          # => false
```

## Design Properties

- **Rule-agnostic**: Independent of specific game mechanics
- **Comprehensive**: Complete game records with metadata
- **Immutable**: All objects frozen, transformations return new instances
- **Functional**: Pure functions without side effects
- **Composable**: Built on PMN, FEEN, and SNN specifications
- **Type-safe**: Strong validation at all levels
- **JSON-compatible**: Native Ruby hash structure ready for JSON serialization
- **Minimal API**: Small, focused public interface
- **Library-agnostic**: No JSON parser dependency, use your preferred library

## Related Specifications

- [PCN Specification v1.0.0](https://sashite.dev/specs/pcn/1.0.0/) - Complete technical specification
- [PCN Examples](https://sashite.dev/specs/pcn/1.0.0/examples/) - Comprehensive examples
- [PMN](https://sashite.dev/specs/pmn/) - Portable Move Notation
- [FEEN](https://sashite.dev/specs/feen/) - Forsyth-Edwards Enhanced Notation
- [SNN](https://sashite.dev/specs/snn/) - Style Name Notation

## Documentation

- [Official PCN Specification v1.0.0](https://sashite.dev/specs/pcn/1.0.0/)
- [PCN Examples Documentation](https://sashite.dev/specs/pcn/1.0.0/examples/)
- [API Documentation](https://rubydoc.info/github/sashite/pcn.rb/main)

## Development

```sh
# Clone the repository
git clone https://github.com/sashite/pcn.rb.git
cd pcn.rb

# Install dependencies
bundle install

# Run tests
ruby test.rb

# Generate documentation
yard doc
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Add tests for your changes
4. Ensure all tests pass (`ruby test.rb`)
5. Commit your changes (`git commit -am 'Add new feature'`)
6. Push to the branch (`git push origin feature/new-feature`)
7. Create a Pull Request

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/) — promoting chess variants and sharing the beauty of board game cultures.
