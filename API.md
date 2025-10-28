# PCN Ruby API Reference

Complete API documentation for the `sashite-pcn` Ruby gem implementing PCN (Portable Chess Notation) v1.0.0.

## Table of Contents

- [Module Sashite::Pcn](#module-sashitepcn)
- [Class: Game](#class-game)
  - [Initialization](#game-initialization)
  - [Core Data Access](#game-core-data-access)
  - [Move Operations](#game-move-operations)
  - [Player Access](#game-player-access)
  - [Metadata Shortcuts](#game-metadata-shortcuts)
  - [Transformations](#game-transformations)
  - [Predicates](#game-predicates)
  - [Serialization](#game-serialization)
- [Class: Meta](#class-meta)
  - [Standard Fields](#meta-standard-fields)
  - [Custom Fields](#meta-custom-fields)
  - [Access Methods](#meta-access-methods)
  - [Iteration & Collection](#meta-iteration--collection)
  - [Comparison & Equality](#meta-comparison--equality)
- [Class: Sides](#class-sides)
  - [Player Access](#sides-player-access)
  - [Indexed Access](#sides-indexed-access)
  - [Batch Operations](#sides-batch-operations)
  - [Time Control Analysis](#sides-time-control-analysis)
  - [Predicates](#sides-predicates)
  - [Collections & Iteration](#sides-collections--iteration)
- [Class: Player](#class-player)
  - [Core Attributes](#player-core-attributes)
  - [Time Control](#player-time-control)
  - [Predicates](#player-predicates)
  - [Serialization](#player-serialization)
- [Validation & Errors](#validation--errors)
- [Type Reference](#type-reference)

---

## Module Sashite::Pcn

Top-level module providing parsing and validation methods.

### Methods

#### `Sashite::Pcn.parse(hash)`

Parses a PCN document from a hash structure.

```ruby
# Parameters
# @param hash [Hash] PCN document with string keys
# @return [Sashite::Pcn::Game] parsed game instance
# @raise [ArgumentError] if structure is invalid

# Example
game = Sashite::Pcn.parse({
                            "setup"  => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
                            "moves"  => [["e2-e4", 2.5], ["e7-e5", 3.1]],
                            "status" => "in_progress"
                          })

# From JSON
require "json"
json_string = File.read("game.pcn.json")
game = Sashite::Pcn.parse(JSON.parse(json_string))
```

#### `Sashite::Pcn.valid?(hash)`

Validates a PCN structure without parsing.

```ruby
# Parameters
# @param hash [Hash] PCN document to validate
# @return [Boolean] true if valid, false otherwise

# Example
valid = Sashite::Pcn.valid?({
                              "setup" => "8/8/8/8/8/8/8/8 / U/u"
                            }) # => true

invalid = Sashite::Pcn.valid?({
                                "moves" => [["e2-e4", 2.5]] # Missing required 'setup'
                              }) # => false
```

---

## Class: Game

Main class representing a complete PCN game record. All instances are immutable.

### Game Initialization

#### `Game.new(setup:, moves: [], status: nil, meta: {}, sides: {})`

Creates a new game instance with validation.

```ruby
# Parameters
# @param setup [String] FEEN position (required)
# @param moves [Array<Array>] array of [PAN, seconds] tuples (optional)
# @param status [String, nil] CGSN status (optional)
# @param meta [Hash] metadata with symbols or strings as keys (optional)
# @param sides [Hash] player information (optional)
# @raise [ArgumentError] if any field is invalid

# Minimal game
game = Sashite::Pcn::Game.new(
  setup: "8/8/8/8/8/8/8/8 / U/u"
)

# Complete game
game = Sashite::Pcn::Game.new(
  setup:  "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves:  [
    ["e2-e4", 2.5],
    ["c7-c5", 3.1]
  ],
  status: "in_progress",
  meta:   {
    event:      "World Championship",
    round:      5,
    started_at: "2025-01-27T14:00:00Z"
  },
  sides:  {
    first:  {
      name:    "Magnus Carlsen",
      elo:     2830,
      style:   "CHESS",
      periods: [{ time: 300, moves: nil, inc: 3 }]
    },
    second: {
      name:    "Hikaru Nakamura",
      elo:     2794,
      style:   "chess",
      periods: [{ time: 300, moves: nil, inc: 3 }]
    }
  }
)
```

### Game Core Data Access

#### `#setup`

Returns the initial position.

```ruby
# @return [Sashite::Feen::Position] FEEN position object

game.setup         # => #<Sashite::Feen::Position ...>
game.setup.to_s    # => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
```

#### `#moves`

Returns the move sequence.

```ruby
# @return [Array<Array>] frozen array of [PAN, seconds] tuples

game.moves # => [["e2-e4", 2.5], ["e7-e5", 3.1]]
```

#### `#status`

Returns the game status.

```ruby
# @return [Sashite::Cgsn::Status, nil] status object or nil

game.status          # => #<Sashite::Cgsn::Status ...>
game.status.to_s     # => "checkmate"
game.status.inferable? # => true
```

#### `#meta`

Returns the metadata object.

```ruby
# @return [Meta] metadata object (never nil, may be empty)

game.meta           # => #<Meta ...>
game.meta[:event]   # => "World Championship"
game.meta.empty?    # => false
```

#### `#sides`

Returns the sides object.

```ruby
# @return [Sides] sides object (never nil, may be empty)

game.sides          # => #<Sides ...>
game.sides.first    # => #<Player ...>
game.sides.second   # => #<Player ...>
```

### Game Move Operations

#### `#move_count`

Returns the number of moves.

```ruby
# @return [Integer] number of moves in the game

game.move_count # => 10
```

#### `#move_at(index)`

Returns move at specified index.

```ruby
# @param index [Integer] 0-based index
# @return [Array, nil] [PAN, seconds] tuple or nil if out of bounds

game.move_at(0)   # => ["e2-e4", 2.5]
game.move_at(1)   # => ["e7-e5", 3.1]
game.move_at(99)  # => nil
```

#### `#pan_at(index)`

Returns just the PAN notation at index.

```ruby
# @param index [Integer] 0-based index
# @return [String, nil] PAN string or nil

game.pan_at(0)  # => "e2-e4"
game.pan_at(1)  # => "e7-e5"
```

#### `#seconds_at(index)`

Returns just the seconds at index.

```ruby
# @param index [Integer] 0-based index
# @return [Float, nil] seconds or nil

game.seconds_at(0)  # => 2.5
game.seconds_at(1)  # => 3.1
```

#### `#first_player_time`

Calculates total time spent by first player.

```ruby
# @return [Float] sum of seconds at even indices (0, 2, 4, ...)

game.first_player_time # => 125.7
```

#### `#second_player_time`

Calculates total time spent by second player.

```ruby
# @return [Float] sum of seconds at odd indices (1, 3, 5, ...)

game.second_player_time # => 132.3
```

#### `#add_move(move)`

Returns new game with added move (immutable).

```ruby
# @param move [Array] [PAN, seconds] tuple
# @return [Game] new game instance with added move
# @raise [ArgumentError] if move format is invalid

new_game = game.add_move(["g1-f3", 1.8])

# Validation enforced
game.add_move(["invalid", -5]) # raises ArgumentError
game.add_move("e2-e4") # raises ArgumentError (not array)
```

### Game Player Access

#### `#first_player`

Returns first player data.

```ruby
# @return [Hash, nil] first player hash or nil

game.first_player
# => {
#   name: "Magnus Carlsen",
#   elo: 2830,
#   style: "CHESS",
#   periods: [{ time: 300, moves: nil, inc: 3 }]
# }
```

#### `#second_player`

Returns second player data.

```ruby
# @return [Hash, nil] second player hash or nil

game.second_player
# => {
#   name: "Hikaru Nakamura",
#   elo: 2794,
#   style: "chess",
#   periods: [{ time: 300, moves: nil, inc: 3 }]
# }
```

### Game Metadata Shortcuts

#### `#started_at`

Returns game start timestamp.

```ruby
# @return [String, nil] ISO 8601 datetime or nil

game.started_at # => "2025-01-27T14:00:00Z"
```

#### `#event`

Returns event name.

```ruby
# @return [String, nil] event name or nil

game.event # => "World Championship"
```

#### `#location`

Returns event location.

```ruby
# @return [String, nil] location or nil

game.location # => "Dubai, UAE"
```

#### `#round`

Returns round number.

```ruby
# @return [Integer, nil] round number or nil

game.round # => 5
```

### Game Transformations

All transformations return new instances (immutable pattern).

#### `#with_status(status)`

Returns new game with updated status.

```ruby
# @param status [String, nil] new CGSN status
# @return [Game] new game instance

finished = game.with_status("checkmate")
resigned = game.with_status("resignation")
```

#### `#with_meta(**fields)`

Returns new game with merged metadata.

```ruby
# @param fields [Hash] metadata fields to merge
# @return [Game] new game instance

updated = game.with_meta(
  round:    6,
  location: "London"
)
```

#### `#with_moves(moves)`

Returns new game with replaced move sequence.

```ruby
# @param moves [Array<Array>] new move sequence
# @return [Game] new game instance

replayed = game.with_moves([
                             ["d2-d4", 1.0],
                             ["d7-d5", 1.5]
                           ])
```

### Game Predicates

#### `#in_progress?`

Checks if game is in progress.

```ruby
# @return [Boolean, nil] true if in progress, nil if no status

game.in_progress?  # => true (if status == "in_progress")
                   # => false (if finished)
                   # => nil (if no status)
```

#### `#finished?`

Checks if game is finished.

```ruby
# @return [Boolean, nil] true if finished, nil if no status

game.finished?  # => true (if status != "in_progress")
                # => false (if in progress)
                # => nil (if no status)
```

#### `#frozen?`

Always returns true (all games are immutable).

```ruby
# @return [Boolean] always true

game.frozen? # => true
```

### Game Serialization

#### `#to_h`

Converts to hash representation.

```ruby
# @return [Hash] hash with string keys

hash = game.to_h
# => {
#   "setup" => "+rnbq+kbn+r/...",
#   "moves" => [["e2-e4", 2.5], ...],
#   "status" => "in_progress",
#   "meta" => { "event" => "..." },
#   "sides" => { "first" => {...}, "second" => {...} }
# }

# Note: empty optional fields are omitted
minimal_game.to_h
# => { "setup" => "8/8/8/8/8/8/8/8 / U/u", "moves" => [] }
```

---

## Class: Meta

Manages game metadata with validation for standard fields and support for custom fields.

### Meta Standard Fields

| Field | Type | Validation | Example |
|-------|------|------------|---------|
| `name` | String | Any non-empty string | `"Italian Game"` |
| `event` | String | Any non-empty string | `"World Championship"` |
| `location` | String | Any non-empty string | `"Dubai, UAE"` |
| `round` | Integer | Must be ≥ 1 | `5` |
| `started_at` | String | ISO 8601 datetime format | `"2025-01-27T14:00:00Z"` |
| `href` | String | Absolute URL (http/https) | `"https://example.com/game/123"` |

### Meta Custom Fields

Any fields not in the standard list are accepted without validation:

```ruby
meta = Meta.new(
  # Standard fields (validated)
  event:        "Tournament",
  round:        5,
  started_at:   "2025-01-27T14:00:00Z",

  # Custom fields (not validated)
  platform:     "lichess.org",
  opening_eco:  "B90",
  opening_name: "Sicilian Najdorf",
  arbiter:      "John Smith",
  rated:        true,
  time_control: "5+3"
)
```

### Meta Access Methods

#### `#[](key)`

Accesses metadata value by key.

```ruby
# @param key [Symbol, String] field key
# @return [Object, nil] value or nil

meta[:event]       # => "World Championship"
meta["round"]      # => 5
meta[:custom]      # => "value" or nil
```

#### `#empty?`

Checks if metadata is empty.

```ruby
# @return [Boolean] true if no fields defined

meta.empty? # => false
Meta.new.empty? # => true
```

#### `#key?(key)`

Checks if field exists.

```ruby
# @param key [Symbol, String] field key
# @return [Boolean] true if field exists

meta.key?(:event)     # => true
meta.key?("round")    # => true
meta.key?(:missing)   # => false
```

#### `#keys`

Returns all field keys.

```ruby
# @return [Array<Symbol>] array of keys

meta.keys # => [:event, :round, :started_at, :platform]
```

### Meta Iteration & Collection

#### `#each(&block)`

Iterates over fields.

```ruby
# @yield [key, value] yields each field
# @return [Enumerator] if no block given

meta.each do |key, value|
  puts "#{key}: #{value}"
end

# With Enumerable methods
meta.each.select { |k, v| v.is_a?(String) }
```

#### `#to_h`

Converts to hash.

```ruby
# @return [Hash] hash with all fields

meta.to_h
# => {
#   event: "Tournament",
#   round: 5,
#   platform: "lichess.org"
# }
```

### Meta Comparison & Equality

#### `#==(other)`

Compares with another Meta object.

```ruby
# @param other [Object] object to compare
# @return [Boolean] true if equal

meta1 == meta2 # => true if all fields match
```

#### `#hash`

Returns hash code.

```ruby
# @return [Integer] hash code for collections

meta.hash # => 123456789
```

#### `#inspect`

Returns debug representation.

```ruby
# @return [String] debug string

meta.inspect
# => "#<Meta event=\"Tournament\" round=5>"
```

---

## Class: Sides

Manages player information for both sides of the game.

### Sides Player Access

#### `#first`

Returns first player.

```ruby
# @return [Player] first player object

player = sides.first
player.name # => "Magnus Carlsen"
```

#### `#second`

Returns second player.

```ruby
# @return [Player] second player object

player = sides.second
player.name # => "Hikaru Nakamura"
```

#### `#player(side)`

Returns player by side name.

```ruby
# @param side [Symbol, String] :first or :second
# @return [Player, nil] player or nil

sides.player(:first)   # => #<Player ...>
sides.player("second") # => #<Player ...>
sides.player(:invalid) # => nil
```

#### `#has_player?(side)`

Checks if side has player data.

```ruby
# @param side [Symbol, String] :first or :second
# @return [Boolean] true if player has data

sides.has_player?(:first)   # => true
sides.has_player?(:second)  # => false (if empty)
```

### Sides Indexed Access

#### `#[](index)`

Accesses player by index.

```ruby
# @param index [Integer] 0 or 1
# @return [Player, nil] player or nil

sides[0]  # => first player
sides[1]  # => second player
sides[2]  # => nil
```

### Sides Batch Operations

#### `#names`

Returns both players' names.

```ruby
# @return [Array<String>] [first_name, second_name]

sides.names  # => ["Magnus Carlsen", "Hikaru Nakamura"]
             # => [nil, "Anonymous"] (if first empty)
```

#### `#elos`

Returns both players' Elo ratings.

```ruby
# @return [Array<Integer>] [first_elo, second_elo]

sides.elos  # => [2830, 2794]
            # => [nil, 2000] (if first has no Elo)
```

#### `#styles`

Returns both players' styles.

```ruby
# @return [Array<String>] [first_style, second_style]

sides.styles  # => ["CHESS", "chess"]
              # => [nil, "shogi"] (if first has no style)
```

#### `#time_budgets`

Returns both players' initial time budgets.

```ruby
# @return [Array<Integer>] [first_seconds, second_seconds]

sides.time_budgets  # => [300, 300] (5 minutes each)
                    # => [7200, nil] (first has 2 hours, second unlimited)
```

### Sides Time Control Analysis

#### `#symmetric_time_control?`

Checks if both players have identical time control.

```ruby
# @return [Boolean] true if periods match exactly

sides.symmetric_time_control? # => true (same periods)
                                # => false (different)
```

#### `#both_have_time_control?`

Checks if both players have time control defined.

```ruby
# @return [Boolean] true if both have periods

sides.both_have_time_control? # => true
                                # => false (if one missing)
```

#### `#unlimited_game?`

Checks if neither player has time control.

```ruby
# @return [Boolean] true if both have unlimited time

sides.unlimited_game?  # => true (casual game)
                       # => false (if any has time control)
```

#### `#mixed_time_control?`

Checks if one player has time control and the other doesn't.

```ruby
# @return [Boolean] true if mixed

sides.mixed_time_control? # => true (handicap game)
                            # => false (both or neither)
```

#### `#time_control_description`

Returns human-readable time control description.

```ruby
# @return [String] descriptive string

sides.time_control_description
# => "5+3 (symmetric)"
# => "Classical 3 periods (symmetric)"
# => "Mixed: first 5+3, second unlimited"
# => "First: 90+30, Second: Byōyomi"
# => "Unlimited time"
```

### Sides Predicates

#### `#empty?`

Checks if no player information exists.

```ruby
# @return [Boolean] true if both players empty

sides.empty? # => false (has players)
Sides.new.empty? # => true
```

#### `#complete?`

Checks if both players have information.

```ruby
# @return [Boolean] true if both players have data

sides.complete?  # => true (both present)
                 # => false (one or both empty)
```

### Sides Collections & Iteration

#### `#each(&block)`

Iterates over both players.

```ruby
# @yield [player] yields each player
# @return [Enumerator] if no block

sides.each do |player|
  puts player.name
end

sides.each.with_index do |player, i|
  puts "Player #{i + 1}: #{player.name}"
end
```

#### `#map(&block)`

Maps over both players.

```ruby
# @yield [player] yields each player
# @return [Array] results

sides.map(&:name)  # => ["Alice", "Bob"]
sides.map(&:elo)   # => [2100, 2050]
sides.map { |p| p.elo || 0 } # => [2100, 0]
```

#### `#to_a`

Converts to array.

```ruby
# @return [Array<Player>] [first, second]

players = sides.to_a
players[0]  # => first player
players[1]  # => second player
```

#### `#to_h`

Converts to hash (omits empty players).

```ruby
# @return [Hash] hash representation

sides.to_h
# => {
#   first: { name: "Alice", elo: 2100, ... },
#   second: { name: "Bob", elo: 2050, ... }
# }

# With one empty player
partial_sides.to_h
# => { first: { name: "Solo" } }

# Both empty
empty_sides.to_h
# => {}
```

---

## Class: Player

Represents individual player information with metadata and time control.

### Player Core Attributes

#### `#name`

Returns player name.

```ruby
# @return [String, nil] name or nil

player.name # => "Magnus Carlsen"
```

#### `#elo`

Returns Elo rating.

```ruby
# @return [Integer, nil] rating >= 0 or nil

player.elo # => 2830
```

#### `#style`

Returns playing style.

```ruby
# @return [Sashite::Snn::Name, nil] style object or nil

player.style      # => #<Sashite::Snn::Name ...>
player.style.to_s # => "CHESS"
```

### Player Time Control

#### `#periods`

Returns time control periods.

```ruby
# @return [Array<Hash>, nil] period array or nil

player.periods
# => [
#   { time: 5400, moves: 40, inc: 0 },
#   { time: 1800, moves: nil, inc: 30 }
# ]
```

Period structure:
- `time`: Integer ≥ 0 (seconds, required)
- `moves`: Integer ≥ 1 or nil (number of moves)
- `inc`: Integer ≥ 0 (increment seconds, default: 0)

#### `#has_time_control?`

Checks if player has time control.

```ruby
# @return [Boolean] true if periods defined

player.has_time_control?  # => true
                          # => false (if periods nil)
```

#### `#unlimited_time?`

Checks if player has unlimited time.

```ruby
# @return [Boolean] true if no time control

player.unlimited_time?  # => false (has periods)
                        # => true (no periods or [])
```

#### `#initial_time_budget`

Calculates total initial time.

```ruby
# @return [Integer, nil] total seconds or nil

player.initial_time_budget  # => 7200 (2 hours)
                            # => nil (if no periods)

# Examples:
# Fischer 5+3: 300
# Classical 90+30: 7200 (5400+1800)
# Byōyomi 60min + 5x60s: 3900
```

### Player Predicates

#### `#empty?`

Checks if player has no data.

```ruby
# @return [Boolean] true if all fields nil

player.empty? # => false (has data)
Player.new.empty? # => true
```

### Player Serialization

#### `#to_h`

Converts to hash (omits nil fields).

```ruby
# @return [Hash] hash with non-nil fields

player.to_h
# => {
#   name: "Magnus Carlsen",
#   elo: 2830,
#   style: "CHESS",
#   periods: [{ time: 300, moves: nil, inc: 3 }]
# }

# Partial player
partial.to_h
# => { name: "Anonymous" }

# Empty player
empty.to_h
# => {}
```

#### `#==(other)`

Compares with another player.

```ruby
# @param other [Object] object to compare
# @return [Boolean] true if equal

player1 == player2 # => true if all attributes match
```

#### `#hash`

Returns hash code.

```ruby
# @return [Integer] hash code

player.hash # => 987654321
```

#### `#inspect`

Returns debug representation.

```ruby
# @return [String] debug string

player.inspect
# => "#<Player name=\"Magnus Carlsen\" elo=2830 style=\"CHESS\" periods=[...]>"
```

---

## Validation & Errors

### Error Types

All validation errors raise `ArgumentError` with descriptive messages.

#### Setup Errors

```ruby
Game.new(setup: nil)
# => ArgumentError: "setup is required"

Game.new(setup: "invalid")
# => ArgumentError: "Invalid FEEN format"
```

#### Move Errors

```ruby
game.add_move("e2-e4")
# => ArgumentError: "Each move must be [PAN string, seconds float] tuple"

game.add_move(["invalid", 2.5])
# => ArgumentError: "Invalid PAN notation: ..."

game.add_move(["e2-e4", -5])
# => ArgumentError: "seconds must be a non-negative number"
```

#### Metadata Errors

```ruby
Meta.new(round: 0)
# => ArgumentError: "round must be a positive integer (>= 1)"

Meta.new(started_at: "2025-01-27")
# => ArgumentError: "started_at must be in ISO 8601 datetime format"

Meta.new(href: "not-a-url")
# => ArgumentError: "href must be an absolute URL (http:// or https://)"
```

#### Player Errors

```ruby
Player.new(elo: -100)
# => ArgumentError: "elo must be a non-negative integer (>= 0)"

Player.new(style: 123)
# => ArgumentError: "style must be a valid SNN string"

Player.new(periods: [{ moves: 1 }])
# => ArgumentError: "period must have 'time' field at index 0"

Player.new(periods: [{ time: -60 }])
# => ArgumentError: "time must be a non-negative integer (>= 0)"
```

### Validation Methods

```ruby
# Check if PCN structure is valid
Sashite::Pcn.valid?(hash) # => true/false

# Validate individual components
begin
  game = Sashite::Pcn::Game.new(setup: data[:setup])
rescue ArgumentError => e
  puts "Invalid: #{e.message}"
end
```

---

## Type Reference

### Required Types

| Field | Type | Description |
|-------|------|-------------|
| `setup` | String | FEEN position (required) |

### Optional Types

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `moves` | Array<[String, Float]> | `[]` | PAN moves with seconds |
| `status` | String or nil | `nil` | CGSN status |
| `meta` | Hash | `{}` | Metadata fields |
| `sides` | Hash | `{}` | Player information |

### Move Tuple Structure

```ruby
[
  "e2-e4",  # PAN notation (String)
  2.5       # Seconds spent (Float >= 0.0)
]
```

### Period Structure

```ruby
{
  time:  300, # Seconds (Integer >= 0, required)
  moves: nil, # Move count (Integer >= 1 or nil)
  inc:   3 # Increment (Integer >= 0, default: 0)
}
```

### Player Structure

```ruby
{
  name:    "Magnus Carlsen", # String (optional)
  elo:     2830, # Integer >= 0 (optional)
  style:   "CHESS", # SNN string (optional)
  periods: [] # Array<Hash> (optional)
}
```

### Meta Structure

Standard fields (validated):
```ruby
{
  name:       "Italian Game", # String
  event:      "World Championship", # String
  location:   "Dubai", # String
  round:      5, # Integer >= 1
  started_at: "2025-01-27T14:00:00Z", # ISO 8601
  href:       "https://example.com" # Absolute URL
}
```

Custom fields (unvalidated):
```ruby
{
  platform:    "lichess.org",
  opening_eco: "B90",
  rated:       true,
  anything:    "accepted"
}
```

---

## Common Patterns

### Building a Game Progressively

```ruby
# Start minimal
game = Sashite::Pcn::Game.new(
  setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
)

# Add metadata
game = game.with_meta(
  event:      "Tournament",
  started_at: Time.now.utc.iso8601
)

# Play moves
game = game.add_move(["e2-e4", 2.3])
game = game.add_move(["e7-e5", 3.1])

# Finish
game = game.with_status("checkmate")
```

### Time Control Patterns

```ruby
# Fischer/Increment
periods = [{ time: 300, moves: nil, inc: 3 }]

# Classical Tournament
periods = [
  { time: 5400, moves: 40, inc: 0 },
  { time: 1800, moves: 20, inc: 0 },
  { time: 900, moves: nil, inc: 30 }
]

# Byōyomi
periods = [
  { time: 3600, moves: nil, inc: 0 },
  { time: 60, moves: 1, inc: 0 },
  { time: 60, moves: 1, inc: 0 },
  { time: 60, moves: 1, inc: 0 },
  { time: 60, moves: 1, inc: 0 },
  { time: 60, moves: 1, inc: 0 }
]

# Canadian
periods = [
  { time: 3600, moves: nil, inc: 0 },
  { time: 300, moves: 10, inc: 0 }
]
```

### Working with Metadata

```ruby
# Check for fields
puts "Playing on #{game.meta[:platform]}" if game.meta.key?(:platform)

# Iterate metadata
game.meta.each do |key, value|
  next if %i[event round].include?(key) # Skip standard

  puts "Custom: #{key} = #{value}"
end

# Update metadata
game = game.with_meta(
  round:      game.meta[:round] + 1,
  updated_at: Time.now.iso8601
)
```

### Analyzing Players

```ruby
# Compare players
sides = game.sides

if sides.complete?
  rating_diff = sides.elos[0] - sides.elos[1]
  puts "Rating difference: #{rating_diff}"
end

# Check time control fairness
if sides.symmetric_time_control?
  puts "Fair match"
elsif sides.mixed_time_control?
  puts "Handicap game"
elsif sides.unlimited_game?
  puts "Casual game"
end

# Process each player
sides.each.with_index do |player, i|
  color = i == 0 ? "White" : "Black"
  puts "#{color}: #{player.name || 'Anonymous'}"

  puts "  Time: #{player.initial_time_budget / 60} minutes" if player.has_time_control?
end
```

### JSON Import/Export

```ruby
# Import
require "json"

# From file
json = File.read("game.pcn.json")
game = Sashite::Pcn.parse(JSON.parse(json))

# From API
require "net/http"
response = Net::HTTP.get(URI("https://api.example.com/game/123"))
game = Sashite::Pcn.parse(JSON.parse(response))

# Export
File.write("output.pcn.json", JSON.pretty_generate(game.to_h))

# To API
uri = URI("https://api.example.com/games")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri)
request["Content-Type"] = "application/json"
request.body = JSON.generate(game.to_h)
response = http.request(request)
```

---

## Version Information

- **Gem Version**: See `sashite-pcn` gem version
- **PCN Specification**: v1.0.0
- **Ruby Required**: >= 3.2.0
- **Dependencies**:
  - `sashite-pan` ~> 1.1
  - `sashite-feen` ~> 0.3
  - `sashite-snn` ~> 3.1
  - `sashite-cgsn` ~> 0.1

---

## Links

- [GitHub Repository](https://github.com/sashite/pcn.rb)
- [RubyDoc Documentation](https://rubydoc.info/github/sashite/pcn.rb/main)
- [PCN Specification](https://sashite.dev/specs/pcn/1.0.0/)
- [Examples](https://sashite.dev/specs/pcn/1.0.0/examples/)
