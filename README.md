# Pcn.rb

[![Version](https://img.shields.io/github/v/tag/sashite/pcn.rb?label=Version&logo=github)](https://github.com/sashite/pcn.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/pcn.rb/main)
![Ruby](https://github.com/sashite/pcn.rb/actions/workflows/main.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/sashite/pcn.rb?label=License&logo=github)](https://github.com/sashite/pcn.rb/raw/main/LICENSE.md)

> **PCN** (Portable Chess Notation) implementation for the Ruby language.

## What is PCN?

PCN (Portable Chess Notation) is a comprehensive, JSON-based format for representing complete chess game records across variants. PCN provides unified, rule-agnostic game recording supporting both traditional single-variant games and cross-variant scenarios with complete metadata tracking.

This gem implements the [PCN Specification v1.0.0](https://sashite.dev/specs/pcn/1.0.0/).

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

PCN builds upon the Sashité ecosystem specifications:
```ruby
gem "sashite-pmn"   # Portable Move Notation
gem "sashite-feen"  # Forsyth-Edwards Enhanced Notation
gem "sashite-snn"   # Style Name Notation
gem "sashite-cgsn"  # Chess Game Status Notation
```

## Usage

### Parsing and Validation
```ruby
require "sashite/pcn"

# Parse a minimal PCN document (only setup required)
game = Sashite::Pcn.parse({
  "setup" => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c"
})

game.setup         # => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c"
game.meta          # => {} (defaults to empty hash when omitted)
game.sides         # => {} (defaults to empty hash when omitted)
game.moves         # => [] (defaults to empty array when omitted)
game.status        # => nil (defaults to nil when omitted)

# Parse with explicit moves
game = Sashite::Pcn.parse({
  "setup" => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
  "moves" => [
    ["e2", "e4"],
    ["e7", "e5"]
  ]
})

game.moves.length  # => 2

# Validate without parsing
Sashite::Pcn.valid?({
  "setup" => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c"
})  # => true (all fields except setup are optional)
```

### Creating Games
```ruby
# Minimal valid game (only setup required, all other fields optional)
game = Sashite::Pcn.parse(
  setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c"
)

# Equivalent to:
game = Sashite::Pcn.parse(
  setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
  meta: {},
  sides: {},
  moves: [],
  status: nil
)

# Chess puzzle (position without moves)
puzzle = Sashite::Pcn.parse(
  meta: { name: "Mate in 2" },
  setup: "r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR / C/c"
  # sides, moves, and status omitted (use default values)
)

# Partial player information (only first player)
game = Sashite::Pcn.parse(
  sides: {
    first: { name: "Alice", elo: 2100 }
    # second omitted (defaults to {})
  },
  setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c"
)

# Complete game with metadata
game = Sashite::Pcn.parse(
  meta: {
    event: "World Championship",
    location: "London",
    started_on: "2024-11-20"
  },
  sides: {
    first: { name: "Carlsen", elo: 2830, style: "CHESS" },
    second: { name: "Nakamura", elo: 2794, style: "chess" }
  },
  setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
  moves: [
    ["e2", "e4"],
    ["c7", "c5"]
  ],
  status: "in_progress"
)
```

### Common Use Cases
```ruby
# Position without moves (puzzle, endgame study, analysis)
puzzle = Sashite::Pcn.parse(
  meta: { name: "Lucena Position" },
  setup: "1K6/1P6/8/8/8/8/r7/2k5 / C/c"
  # moves omitted (defaults to [])
)

# Terminal position with status
terminal = Sashite::Pcn.parse(
  setup: "7k/5Q2/6K1/8/8/8/8/8 / C/c",
  status: "stalemate"
  # moves omitted (defaults to [])
)

# Game template (starting position)
template = Sashite::Pcn.parse(
  sides: {
    first: { style: "CHESS" },
    second: { style: "chess" }
  },
  setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c"
  # meta, moves, and status omitted (use default values)
)

# Position with inferable status (checkmate can be inferred from position)
game = Sashite::Pcn.parse(
  setup: "r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR / c/C",
  moves: [
    ["f1", "c4"],
    ["g8", "f6"],
    ["d1", "h5"],
    ["f6", "h5"]
  ]
  # status omitted (defaults to nil, can be inferred as "checkmate")
)

# Game with explicit-only status (must be declared)
game = Sashite::Pcn.parse(
  setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
  moves: [
    ["e2", "e4"],
    ["c7", "c5"]
  ],
  status: "resignation"  # Cannot be inferred, must be explicit
)
```

### Immutability and Transformations
```ruby
# All objects are frozen
game.frozen?  # => true
game.meta.frozen?  # => true

# Transformations return new instances
new_game = game.add_move(["g1", "f3"])
new_game.moves.length  # => 3
game.moves.length      # => 2 (unchanged)

# Update metadata
updated = game.with_status("resignation")
updated.status  # => "resignation"
game.status     # => "in_progress" (unchanged)
```

### Accessing Game Data
```ruby
# Metadata access (empty hash if omitted)
game.meta              # => {} or { event: "...", location: "...", ... }
game.meta[:event]      # => "World Championship" or nil
game.started_on        # => "2024-11-20" or nil

# Player information (empty hash if omitted)
game.sides             # => {} or { first: {...}, second: {...} }
game.first_player      # => { name: "Carlsen", elo: 2830, style: "CHESS" } or {}
game.second_player     # => { name: "Nakamura", elo: 2794, style: "chess" } or {}

# Move access (always returns array, empty if omitted)
game.moves             # => [[...], [...]] or []
game.move_at(0)        # => ["e2", "e4"] or nil
game.move_count        # => 2 or 0

# Status (nil if omitted)
game.status            # => "in_progress" or nil
game.finished?         # => false
game.in_progress?      # => true
```

### JSON Serialization
```ruby
# Convert to hash (ready for JSON)
game.to_h
# => {
#   "meta" => { "event" => "...", ... },
#   "sides" => { "first" => {...}, "second" => {...} },
#   "setup" => "...",
#   "moves" => [[...], [...]],
#   "status" => "in_progress"
# }

# Minimal game (only required field + moves array)
minimal = Sashite::Pcn.parse(setup: "8/8/8/8/8/8/8/8 / U/u")
minimal.to_h
# => {
#   "setup" => "8/8/8/8/8/8/8/8 / U/u",
#   "moves" => []  # Always included in serialization
# }
# Note: meta, sides, and status omitted when at default values

# Game with some fields at default values
partial = Sashite::Pcn.parse(
  meta: { name: "Study" },
  setup: "8/8/8/8/8/8/8/8 / U/u"
)
partial.to_h
# => {
#   "meta" => { "name" => "Study" },
#   "setup" => "8/8/8/8/8/8/8/8 / U/u",
#   "moves" => []
# }
# Note: sides and status omitted (at default values)

# Use with any JSON library
require "json"
json_string = JSON.generate(game.to_h)

# Parse from JSON
parsed = Sashite::Pcn.parse(JSON.parse(json_string))
```

### Functional Operations
```ruby
# Chain transformations (starting from minimal game)
game = Sashite::Pcn.parse(setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c")
  .add_move(["e2", "e4"])
  .add_move(["e7", "e5"])
  .with_meta(event: "Casual Game")
  .with_status("in_progress")

# Map over moves
move_notations = game.moves.map { |move| move.join("-") }

# Filter and select
queens_moves = game.moves.select { |move| move[2]&.include?("Q") }
```

## Properties

* **Rule-agnostic**: Independent of specific game mechanics
* **Comprehensive**: Complete game records with metadata
* **Minimal requirements**: Only `setup` field required
* **Smart defaults**: Optional fields (`meta`, `sides`, `moves`, `status`) have sensible defaults
* **Immutable**: All objects frozen, transformations return new instances
* **Functional**: Pure functions without side effects
* **Flexible**: Supports positions without moves (puzzles, analysis, templates)
* **Composable**: Built on PMN, FEEN, SNN, and CGSN specifications
* **Type-safe**: Strong validation at all levels
* **JSON-compatible**: Native Ruby hash structure ready for JSON serialization
* **Minimal API**: Small, focused public interface
* **Library-agnostic**: No JSON parser dependency, use your preferred library

## Default Values

When fields are omitted in initialization or parsing:

| Field | Default Value | Description |
|-------|---------------|-------------|
| `meta` | `{}` | No metadata provided |
| `sides` | `{}` | No player information |
| `sides[:first]` | `{}` | No first player information |
| `sides[:second]` | `{}` | No second player information |
| `moves` | `[]` | No moves played |
| `status` | `nil` | No explicit status declaration |
| `setup` | *required* | Must be explicitly provided |

## API Reference

### Class Methods

- `Sashite::Pcn.parse(hash)` - Parse PCN from hash structure
- `Sashite::Pcn.valid?(hash)` - Validate PCN structure

### Instance Methods

#### Core Data Access
- `#setup` - Initial position (FEEN string) **[required]**
- `#meta` - Metadata hash (defaults to `{}`)
- `#sides` - Player information hash (defaults to `{}`)
- `#moves` - Move sequence array (defaults to `[]`)
- `#status` - Game status (CGSN value or `nil`, defaults to `nil`)

#### Player Access
- `#first_player` - First player data (defaults to `{}`)
- `#second_player` - Second player data (defaults to `{}`)

#### Move Operations
- `#move_at(index)` - Get move at index
- `#move_count` - Total number of moves
- `#add_move(move)` - Return new game with added move

#### Metadata Shortcuts
- `#started_on` - Game start date
- `#finished_at` - Game completion timestamp
- `#event` - Event name
- `#location` - Event location
- `#round` - Round number

#### Transformations
- `#with_status(status)` - Return new game with status
- `#with_meta(**meta)` - Return new game with updated metadata
- `#with_moves(moves)` - Return new game with move sequence

#### Predicates
- `#finished?` - Check if game is finished
- `#in_progress?` - Check if game is in progress

#### Serialization
- `#to_h` - Convert to hash (always includes `moves` array, omits fields at default values)
- `#to_json(*args)` - Convert to JSON (if JSON library loaded)
- `#frozen?` - Always returns true

## Documentation

- [Official PCN Specification v1.0.0](https://sashite.dev/specs/pcn/1.0.0/)
- [PCN Examples](https://sashite.dev/specs/pcn/1.0.0/examples/)
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
