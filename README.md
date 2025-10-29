# Pcn.rb

[![Version](https://img.shields.io/github/v/tag/sashite/pcn.rb?label=Version&logo=github)](https://github.com/sashite/pcn.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/pcn.rb/main)
![Ruby](https://github.com/sashite/pcn.rb/actions/workflows/main.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/sashite/pcn.rb?label=License&logo=github)](https://github.com/sashite/pcn.rb/raw/main/LICENSE.md)

> **PCN** (Portable Chess Notation) - Complete Ruby implementation for game record management

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Documentation](#api-documentation)
- [Format Specifications](#format-specifications)
- [Time Control Examples](#time-control-examples)
- [Draw Offers](#draw-offers)
- [Error Handling](#error-handling)
- [Complete Examples](#complete-examples)
- [JSON Interoperability](#json-interoperability)

## Overview

PCN (Portable Chess Notation) is a comprehensive, JSON-based format for representing complete chess game records across variants. This Ruby implementation provides:

- **Complete game records** with positions, moves, time tracking, and metadata
- **Draw offer tracking** for recording draw proposals between players
- **Time control support** for Fischer, Classical, Byōyomi, Canadian, and more
- **Rule-agnostic design** supporting all abstract strategy board games
- **Immutable objects** with functional transformations
- **Full validation** of all data formats
- **JSON compatibility** for easy serialization and storage

Implements [PCN Specification v1.0.0](https://sashite.dev/specs/pcn/1.0.0/).

## Installation

```ruby
# Gemfile
gem "sashite-pcn"
```

Or install directly:

```sh
gem install sashite-pcn
```

### Dependencies

PCN integrates these Sashité specifications (installed automatically):

```ruby
gem "sashite-pan"   # Portable Action Notation (moves)
gem "sashite-feen"  # Forsyth-Edwards Enhanced Notation (positions)
gem "sashite-snn"   # Style Name Notation (game variants)
gem "sashite-cgsn"  # Chess Game Status Notation (game states)
```

## Quick Start

```ruby
require "sashite/pcn"

# Parse a complete game
game = Sashite::Pcn.parse({
  "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  "moves" => [
    ["e2-e4", 2.5],  # Each move: [PAN notation, seconds spent]
    ["e7-e5", 3.1]
  ],
  "status" => "in_progress"
})

# Access game data
game.setup          # => FEEN position object
game.moves          # => [["e2-e4", 2.5], ["e7-e5", 3.1]]
game.move_count     # => 2
game.status         # => CGSN status object

# Transform immutably
new_game = game.add_move(["g1-f3", 1.8])
final_game = new_game.with_status("checkmate")

# Handle draw offers
game_with_offer = game.with_draw_offered_by("first")
game.draw_offered?  # => true
game.draw_offered_by # => "first"
```

## API Documentation

For complete API documentation, see [API Reference](https://rubydoc.info/github/sashite/pcn.rb/main/file/API.md).

The API documentation includes:
- All classes and methods
- Type signatures and parameters
- Return values and exceptions
- Code examples for every method
- Common usage patterns
- Time control formats
- Draw offer handling
- Error handling

## Format Specifications

### FEEN (Position)

```ruby
# Standard chess starting position
"+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
# └─ board ──────────────────────────────────────────────┘ └┘ └─┘
#                                                               turn styles

# Empty board
"8/8/8/8/8/8/8/8 / U/u"

# With piece attributes (+ for light, - for dark)
"+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
```

### PAN (Moves)

```ruby
# Basic movement
"e2-e4"      # Move from e2 to e4
"g1-f3"      # Knight from g1 to f3

# Special moves
"e1~g1"      # Castling (special path ~)
"e5~f6"      # En passant (special path ~)

# Captures
"d1+f3"      # Movement with capture
"+e5"        # Static capture at e5

# Promotions
"e7-e8=Q"    # Pawn promotion to Queen
"e4=+P"      # In-place transformation

# Drops (shogi-style)
"P*e4"       # Drop piece P at e4

# Pass move
"..."        # Pass (no action)
```

### CGSN (Status)

```ruby
# Inferable (can be derived from position)
"checkmate"      # King under inescapable attack
"stalemate"      # No legal moves, not in check
"insufficient"   # Neither side can force checkmate
"in_progress"    # Game continues

# Explicit only (must be declared)
"resignation"    # Player resigned
"time_limit"     # Time expired
"agreement"      # Mutual agreement (draw)
"illegal_move"   # Invalid move played
"repetition"     # Draw by repetition
"move_limit"     # Move limit reached
```

### SNN (Styles)

```ruby
# Common styles
"CHESS"          # Western Chess
"shogi"          # Japanese Chess
"xiangqi"        # Chinese Chess
"makruk"         # Thai Chess

# Case indicates piece set
"CHESS"          # Uppercase = Western pieces
"chess"          # Lowercase = alternative representation
```

## Time Control Examples

### Fischer/Increment

```ruby
# Blitz 5+3 (5 minutes + 3 seconds per move)
periods: [
  { time: 300, moves: nil, inc: 3 }
]

# Rapid 15+10
periods: [
  { time: 900, moves: nil, inc: 10 }
]

# No increment
periods: [
  { time: 600, moves: nil, inc: 0 }  # 10 minutes, no increment
]
```

### Classical (Multiple Periods)

```ruby
# Tournament time control
periods: [
  { time: 5400, moves: 40, inc: 0 },   # 90 min for first 40 moves
  { time: 1800, moves: 20, inc: 0 },   # 30 min for next 20 moves
  { time: 900, moves: nil, inc: 30 }   # 15 min + 30s/move for rest
]
```

### Byōyomi (Japanese)

```ruby
# 1 hour main + 60 seconds per move (5 periods)
periods: [
  { time: 3600, moves: nil, inc: 0 },  # Main time
  { time: 60, moves: 1, inc: 0 },      # Byōyomi period 1
  { time: 60, moves: 1, inc: 0 },      # Byōyomi period 2
  { time: 60, moves: 1, inc: 0 },      # Byōyomi period 3
  { time: 60, moves: 1, inc: 0 },      # Byōyomi period 4
  { time: 60, moves: 1, inc: 0 }       # Byōyomi period 5
]
```

### Canadian Overtime

```ruby
# 1 hour + 5 minutes for every 10 moves
periods: [
  { time: 3600, moves: nil, inc: 0 },  # Main time: 1 hour
  { time: 300, moves: 10, inc: 0 }     # Overtime: 5 min/10 moves
]
```

### No Time Control

```ruby
# Casual/correspondence game
periods: []      # Empty array
periods: nil     # Or omit entirely
```

## Draw Offers

PCN supports tracking draw offers between players using the `draw_offered_by` field.

### Basic Usage

```ruby
# Offer a draw
game = game.with_draw_offered_by("first")  # First player offers

# Check if draw offered
game.draw_offered?       # => true
game.draw_offered_by     # => "first"

# Accept the draw
game = game.with_status("agreement")

# Decline/withdraw draw offer
game = game.with_draw_offered_by(nil)
```

### Draw Offer Values

```ruby
nil        # No draw offer pending (default)
"first"    # First player has offered a draw
"second"   # Second player has offered a draw
```

### Example: Draw Offer During Game

```ruby
# Game in progress with draw offer
game = Sashite::Pcn.parse({
  "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  "moves" => [
    ["e2-e4", 8.0],
    ["e7-e5", 12.0],
    ["g1-f3", 15.0]
  ],
  "draw_offered_by" => "first",
  "status" => "in_progress"
})

# First player has offered a draw after move 3
puts "Draw offered by: #{game.draw_offered_by}"  # => "first"
```

### Example: Accepted Draw

```ruby
# Draw accepted
game = Sashite::Pcn.parse({
  "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  "moves" => [
    ["e2-e4", 15.0],
    ["e7-e5", 18.0],
    ["g1-f3", 22.0],
    ["b8-c6", 12.0]
  ],
  "draw_offered_by" => "first",
  "status" => "agreement"
})

# First player offered, second player accepted
puts "Game result: Draw by agreement"
```

## Error Handling

```ruby
# Setup validation
begin
  game = Sashite::Pcn::Game.new(setup: "invalid")
rescue ArgumentError => e
  puts e.message  # => "Invalid FEEN format"
end

# Move validation
begin
  game.add_move(["invalid", -5])
rescue ArgumentError => e
  puts e.message  # => "Invalid PAN notation"
end

# Move format validation
begin
  game.add_move("e2-e4")  # Wrong: should be array
rescue ArgumentError => e
  puts e.message  # => "Each move must be [PAN string, seconds float] tuple"
end

# Draw offer validation
begin
  Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / U/u",
    draw_offered_by: "third"  # Invalid: must be nil, "first", or "second"
  )
rescue ArgumentError => e
  puts e.message  # => "draw_offered_by must be nil, 'first', or 'second'"
end

# Metadata validation
begin
  Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / U/u",
    meta: { round: -1 }  # Invalid: must be >= 1
  )
rescue ArgumentError => e
  puts e.message  # => "round must be a positive integer (>= 1)"
end

# Time control validation
begin
  sides = {
    first: {
      periods: [
        { time: -100 }  # Invalid: negative time
      ]
    }
  }
  Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / U/u", sides: sides)
rescue ArgumentError => e
  puts e.message  # => "time must be a non-negative integer (>= 0)"
end
```

## Complete Examples

### Minimal Valid Game

```ruby
# Absolute minimum (only setup required)
game = Sashite::Pcn::Game.new(
  setup: "8/8/8/8/8/8/8/8 / U/u"
)
```

### Standard Chess Game

```ruby
game = Sashite::Pcn::Game.new(
  meta: {
    name: "Italian Game",
    event: "Online Tournament",
    round: 3,
    started_at: "2025-01-27T19:30:00Z"
  },
  sides: {
    first: {
      name: "Alice",
      elo: 2100,
      style: "CHESS",
      periods: [{ time: 300, moves: nil, inc: 3 }]  # 5+3 blitz
    },
    second: {
      name: "Bob",
      elo: 2050,
      style: "chess",
      periods: [{ time: 300, moves: nil, inc: 3 }]
    }
  },
  setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves: [
    ["e2-e4", 2.3],
    ["c7-c5", 3.1],
    ["g1-f3", 1.8],
    ["d7-d6", 2.5],
    ["d2-d4", 4.2],
    ["c5+d4", 1.0],
    ["f3+d4", 0.8]
  ],
  status: "in_progress"
)
```

### Building a Game Progressively

```ruby
# Start with minimal game
game = Sashite::Pcn::Game.new(
  setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
)

# Add metadata
game = game.with_meta(
  event: "Friendly Match",
  started_at: Time.now.utc.iso8601
)

# Play moves
game = game.add_move(["e2-e4", 5.2])
game = game.add_move(["e7-e5", 3.8])
game = game.add_move(["g1-f3", 2.1])

# Check progress
puts "Moves played: #{game.move_count}"
puts "White time: #{game.first_player_time}s"
puts "Black time: #{game.second_player_time}s"

# Offer a draw
game = game.with_draw_offered_by("first")

# Finish game
if some_condition
  game = game.with_status("checkmate")
elsif draw_accepted?
  game = game.with_status("agreement")
else
  game = game.with_status("resignation")
end
```

### Game with Draw Offer

```ruby
# Complete game with draw offer and acceptance
game = Sashite::Pcn::Game.new(
  meta: {
    event: "Club Match",
    round: 5,
    started_at: "2025-01-27T14:00:00Z"
  },
  sides: {
    first: {
      name: "Player A",
      elo: 2200,
      style: "CHESS"
    },
    second: {
      name: "Player B",
      elo: 2190,
      style: "chess"
    }
  },
  setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves: [
    ["e2-e4", 15.0],
    ["e7-e5", 18.0],
    ["g1-f3", 22.0],
    ["b8-c6", 12.0],
    ["d2-d4", 31.0],
    ["e5+d4", 25.0]
  ],
  draw_offered_by: "first",
  status: "agreement"
)

puts "Result: Draw by agreement"
puts "Initiated by: #{game.draw_offered_by}"
```

### Complex Tournament Game

```ruby
require "sashite/pcn"
require "json"

# Full tournament game with all features
game_data = {
  "meta" => {
    "name" => "Sicilian Defense, Najdorf Variation",
    "event" => "FIDE World Championship",
    "location" => "Dubai, UAE",
    "round" => 11,
    "started_at" => "2025-11-20T15:00:00+04:00",
    "href" => "https://worldchess.com/match/2025/round11",

    # Custom metadata
    "arbiter" => "John Smith",
    "opening_eco" => "B90",
    "opening_name" => "Sicilian Najdorf",
    "board_number" => 1,
    "section" => "Open",
    "live_url" => "https://chess24.com/watch/live"
  },

  "sides" => {
    "first" => {
      "name" => "Magnus Carlsen",
      "elo" => 2830,
      "style" => "CHESS",
      "title" => "GM",  # Custom field
      "federation" => "NOR",  # Custom field
      "periods" => [
        { "time" => 5400, "moves" => 40, "inc" => 0 },
        { "time" => 1800, "moves" => 20, "inc" => 0 },
        { "time" => 900, "moves" => nil, "inc" => 30 }
      ]
    },
    "second" => {
      "name" => "Fabiano Caruana",
      "elo" => 2820,
      "style" => "chess",
      "title" => "GM",
      "federation" => "USA",
      "periods" => [
        { "time" => 5400, "moves" => 40, "inc" => 0 },
        { "time" => 1800, "moves" => 20, "inc" => 0 },
        { "time" => 900, "moves" => nil, "inc" => 30 }
      ]
    }
  },

  "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",

  "moves" => [
    ["e2-e4", 32.1], ["c7-c5", 28.5],
    ["g1-f3", 45.2], ["d7-d6", 31.0],
    ["d2-d4", 38.9], ["c5+d4", 29.8],
    ["f3+d4", 15.5], ["g8-f6", 35.2],
    ["b1-c3", 62.3], ["a7-a6", 44.1],
    # ... many more moves
  ],

  "status" => "resignation"
}

# Parse and use
game = Sashite::Pcn.parse(game_data)

# Analysis
puts "Game: #{game.meta[:name]}"
puts "Duration: #{(game.first_player_time + game.second_player_time) / 60} minutes"
puts "Winner: #{game.status == 'resignation' ? 'First player (White)' : 'Unknown'}"
puts "Total moves: #{game.move_count}"

# Export to JSON file
File.write("game.json", JSON.pretty_generate(game.to_h))
```

### Draw Offer Scenario

```ruby
# Game progressing with draw offer
game = Sashite::Pcn::Game.new(
  setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
)

# Play several moves
game = game.add_move(["e2-e4", 8.0])
game = game.add_move(["e7-e5", 12.0])
game = game.add_move(["g1-f3", 15.0])
game = game.add_move(["b8-c6", 5.0])

# First player offers a draw
game = game.with_draw_offered_by("first")

# Check the offer
if game.draw_offered?
  puts "Draw offered by: #{game.draw_offered_by}"

  # Second player can accept
  if player_accepts_draw?
    game = game.with_status("agreement")
    puts "Draw accepted!"
  else
    # Or decline and continue
    game = game.with_draw_offered_by(nil)
    game = game.add_move(["f1-c4", 9.0])
    puts "Draw declined, game continues"
  end
end
```

## JSON Interoperability

### Reading PCN Files

```ruby
require "json"
require "sashite/pcn"

# From file
json_data = File.read("game.pcn.json")
hash = JSON.parse(json_data)
game = Sashite::Pcn.parse(hash)

# From URL
require "net/http"
require "uri"

uri = URI("https://api.example.com/game/123")
response = Net::HTTP.get(uri)
hash = JSON.parse(response)
game = Sashite::Pcn.parse(hash)
```

### Writing PCN Files

```ruby
# Save to file
game_hash = game.to_h
json = JSON.pretty_generate(game_hash)
File.write("game.pcn.json", json)

# Send to API
require "net/http"

uri = URI("https://api.example.com/games")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri)
request["Content-Type"] = "application/json"
request.body = JSON.generate(game.to_h)

response = http.request(request)
```

### Database Storage

```ruby
# Store in database (e.g., PostgreSQL with JSON column)
class GameRecord < ActiveRecord::Base
  # Assumes: t.json :pcn_data

  def game
    @game ||= Sashite::Pcn.parse(pcn_data)
  end

  def game=(game_object)
    self.pcn_data = game_object.to_h
    @game = game_object
  end
end

# Usage
record = GameRecord.new
record.game = Sashite::Pcn::Game.new(setup: "...")
record.save!

# Retrieve
record = GameRecord.find(id)
game = record.game
puts game.move_count
puts "Draw offered: #{game.draw_offered?}"
```

## Properties

- **Immutable**: All objects are frozen; transformations return new instances
- **Validated**: All data is validated on creation
- **Type-safe**: Strong type checking throughout
- **Rule-agnostic**: Independent of specific game rules
- **JSON-native**: Direct serialization to/from JSON
- **Comprehensive**: Complete game information including time tracking and draw offers
- **Extensible**: Custom metadata and player fields supported

## Documentation

- [Official PCN Specification v1.0.0](https://sashite.dev/specs/pcn/1.0.0/)
- [PCN Examples](https://sashite.dev/specs/pcn/1.0.0/examples/)
- [Draw Offer Examples](https://sashite.dev/specs/pcn/1.0.0/examples/draw-offers/)
- [API Documentation](https://rubydoc.info/github/sashite/pcn.rb/main)
- [PAN Specification](https://sashite.dev/specs/pan/) (moves)
- [FEEN Specification](https://sashite.dev/specs/feen/) (positions)
- [SNN Specification](https://sashite.dev/specs/snn/) (styles)
- [CGSN Specification](https://sashite.dev/specs/cgsn/) (statuses)

## Development

```sh
# Setup
git clone https://github.com/sashite/pcn.rb.git
cd pcn.rb
bundle install

# Run tests
bundle exec rake test
# or
ruby test.rb

# Run linter
bundle exec rubocop

# Generate documentation
bundle exec yard doc

# Console for experimentation
bundle exec irb -r ./lib/sashite/pcn
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Implement your feature
5. Ensure all tests pass (`ruby test.rb`)
6. Check code style (`rubocop`)
7. Commit your changes (`git commit -am 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/)

> Sashité is a community initiative promoting chess variants and sharing the beauty of traditional board game cultures from around the world.

### Contact

- Website: https://sashite.com
- GitHub: https://github.com/sashite
- Email: contact@sashite.com

### Related Projects

- [Pan.rb](https://github.com/sashite/pan.rb) - Portable Action Notation
- [Feen.rb](https://github.com/sashite/feen.rb) - Forsyth-Edwards Enhanced Notation
- [Snn.rb](https://github.com/sashite/snn.rb) - Style Name Notation
- [Cgsn.rb](https://github.com/sashite/cgsn.rb) - Chess Game Status Notation
