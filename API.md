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

#### `Game.new(setup:, moves: [], status: nil, draw_offered_by: nil, meta: {}, sides: {})`

Creates a new game instance with validation.

```ruby
# Parameters
# @param setup [String] FEEN position (required)
# @param moves [Array<Array>] array of [PAN, seconds] tuples (optional)
# @param status [String, nil] CGSN status (optional)
# @param draw_offered_by [String, nil] draw offer indicator ("first", "second", or nil) (optional)
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

# Game with draw offer
game = Sashite::Pcn::Game.new(
  setup:           "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves:           [["e2-e4", 8.0], ["e7-e5", 12.0]],
  status:          "in_progress",
  draw_offered_by: "first" # First player has offered a draw
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

#### `#draw_offered_by`

Returns the draw offer indicator.

```ruby
# @return [String, nil] "first", "second", or nil

game.draw_offered_by # => "first"  # First player has offered a draw
game.draw_offered_by # => nil      # No draw offer pending
```

**`draw_offered_by` field semantics:**

- **`nil`** (default): No draw offer is currently pending
- **`"first"`**: The first player has offered a draw to the second player
- **`"second"`**: The second player has offered a draw to the first player

**Independence from `status`:**

The `draw_offered_by` field is completely independent of the `status` field. It records communication between players (proposal state), while `status` records the observable game state (terminal condition).

**Common state transitions:**

1. **Offer made**: `draw_offered_by` changes from `nil` to `"first"` or `"second"`, `status` remains `"in_progress"`
2. **Offer accepted**: `status` transitions to `"agreement"`, `draw_offered_by` may remain set or be cleared (implementation choice)
3. **Offer canceled/withdrawn**: `draw_offered_by` returns to `nil`, `status` remains `"in_progress"`

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

#### `#with_draw_offered_by(player)`

Returns new game with updated draw offer.

```ruby
# @param player [String, nil] "first", "second", or nil
# @return [Game] new game instance

# First player offers draw
game_with_offer = game.with_draw_offered_by("first")

# Withdraw draw offer
game_no_offer = game.with_draw_offered_by(nil)
```

#### `#with_meta(**fields)`

Returns new game with merged metadata.

```ruby
# @param fields [Hash] metadata fields to merge
# @return [Game] new game instance

updated = game.with_meta(
  event:  "Tournament",
  round:  1,
  custom: "value"
)
```

#### `#with_moves(moves)`

Returns new game with specified move sequence.

```ruby
# @param moves [Array<Array>] new move sequence of [PAN, seconds] tuples
# @return [Game] new game instance with new moves
# @raise [ArgumentError] if move format is invalid

updated = game.with_moves([
                            ["e2-e4", 2.0],
                            ["e7-e5", 3.0]
                          ])
```

### Game Predicates

#### `#in_progress?`

Checks if the game is in progress.

```ruby
# @return [Boolean, nil] true if in progress, false if finished, nil if indeterminate

game.in_progress? # => true
```

#### `#finished?`

Checks if the game is finished.

```ruby
# @return [Boolean, nil] true if finished, false if in progress, nil if indeterminate

game.finished? # => false
```

#### `#draw_offered?`

Checks if a draw offer is pending.

```ruby
# @return [Boolean] true if a draw offer is pending

game.draw_offered?  # => true  (if draw_offered_by is "first" or "second")
game.draw_offered?  # => false (if draw_offered_by is nil)
```

### Game Serialization

#### `#to_h`

Converts to hash representation.

```ruby
# @return [Hash] hash with string keys ready for JSON serialization

game.to_h
# => {
#   "setup" => "...",
#   "moves" => [["e2-e4", 2.5], ["e7-e5", 3.1]],
#   "status" => "in_progress",
#   "draw_offered_by" => "first",
#   "meta" => {...},
#   "sides" => {...}
# }
```

#### `#==(other)`

Compares with another game.

```ruby
# @param other [Object] object to compare
# @return [Boolean] true if equal

game1 == game2 # => true if all attributes match
```

#### `#hash`

Returns hash code.

```ruby
# @return [Integer] hash code

game.hash # => 123456789
```

#### `#inspect`

Returns debug representation.

```ruby
# @return [String] debug string

game.inspect
# => "#<Game setup=\"...\" moves=[...] status=\"in_progress\">"
```

---

## Class: Meta

Class representing game metadata. Supports validated standard fields and custom fields.

### Meta Standard Fields

Standard fields with validation:

- `name` (String): Name of the game or opening
- `event` (String): Event name
- `location` (String): Event location
- `round` (Integer >= 1): Round number
- `started_at` (String): ISO 8601 timestamp
- `href` (String): Absolute URL (http:// or https://)

### Meta Custom Fields

Custom fields are accepted without validation. Examples:

- `platform`: Gaming platform
- `opening_eco`: ECO opening code
- `rated`: Whether the game is rated
- Any other custom field

### Meta Access Methods

#### `#[](key)`

Accesses a metadata field.

```ruby
# @param key [Symbol, String] field key
# @return [Object, nil] field value or nil

meta[:event]    # => "World Championship"
meta[:platform] # => "lichess.org"
```

#### `#key?(key)`

Checks if a field exists.

```ruby
# @param key [Symbol, String] field key
# @return [Boolean] true if field exists

meta.key?(:event)    # => true
meta.key?(:unknown)  # => false
```

### Meta Iteration & Collection

#### `#each`

Iterates over all fields.

```ruby
# @yield [key, value] passes each key-value pair
# @return [Enumerator] if no block given

meta.each do |key, value|
  puts "#{key}: #{value}"
end
```

#### `#keys`

Returns all keys.

```ruby
# @return [Array<Symbol>] array of keys

meta.keys # => [:event, :round, :started_at]
```

#### `#values`

Returns all values.

```ruby
# @return [Array] array of values

meta.values # => ["World Championship", 5, "2025-01-27T14:00:00Z"]
```

#### `#to_h`

Converts to hash (omits nil fields).

```ruby
# @return [Hash] hash with symbol keys

meta.to_h
# => {
#   event: "World Championship",
#   round: 5,
#   started_at: "2025-01-27T14:00:00Z"
# }
```

### Meta Comparison & Equality

#### `#empty?`

Checks if metadata is empty.

```ruby
# @return [Boolean] true if no fields defined

meta.empty? # => false
Meta.new.empty? # => true
```

#### `#==(other)`

Compares with other metadata.

```ruby
# @param other [Object] object to compare
# @return [Boolean] true if equal

meta1 == meta2 # => true if all fields match
```

---

## Class: Sides

Class representing information for both players.

### Sides Player Access

#### `#first`

Returns the first player.

```ruby
# @return [Player, nil] player object or nil

sides.first # => #<Player ...>
```

#### `#second`

Returns the second player.

```ruby
# @return [Player, nil] player object or nil

sides.second # => #<Player ...>
```

### Sides Indexed Access

#### `#[](index)`

Accesses player by index (0 = first, 1 = second).

```ruby
# @param index [Integer] 0 or 1
# @return [Player, nil] player object or nil

sides[0] # => first player
sides[1] # => second player
```

### Sides Batch Operations

#### `#names`

Returns names of both players.

```ruby
# @return [Array<String, nil>] array of names

sides.names # => ["Carlsen", "Nakamura"]
```

#### `#elos`

Returns Elo ratings of both players.

```ruby
# @return [Array<Integer, nil>] array of Elos

sides.elos # => [2830, 2794]
```

#### `#styles`

Returns styles of both players.

```ruby
# @return [Array<String, nil>] array of SNN styles

sides.styles # => ["CHESS", "chess"]
```

### Sides Time Control Analysis

#### `#symmetric_time_control?`

Checks if both players have the same time control.

```ruby
# @return [Boolean] true if periods are identical

sides.symmetric_time_control? # => true
```

#### `#mixed_time_control?`

Checks if players have different time controls.

```ruby
# @return [Boolean] true if one player has periods and the other doesn't

sides.mixed_time_control? # => false
```

#### `#unlimited_game?`

Checks if neither player has time control.

```ruby
# @return [Boolean] true if no periods defined

sides.unlimited_game? # => false
```

### Sides Predicates

#### `#complete?`

Checks if both players are defined.

```ruby
# @return [Boolean] true if first and second are defined

sides.complete? # => true
```

#### `#empty?`

Checks if no players are defined.

```ruby
# @return [Boolean] true if no players defined

sides.empty? # => false
```

### Sides Collections & Iteration

#### `#each`

Iterates over players.

```ruby
# @yield [player] passes each player
# @return [Enumerator] if no block given

sides.each do |player|
  puts player.name
end
```

#### `#to_h`

Converts to hash.

```ruby
# @return [Hash] hash with first/second keys

sides.to_h
# => {
#   first: { name: "Carlsen", ... },
#   second: { name: "Nakamura", ... }
# }
```

---

## Class: Player

Class representing a single player with their information and time control.

### Player Core Attributes

#### `#name`

Returns the player's name.

```ruby
# @return [String, nil] name or nil

player.name # => "Magnus Carlsen"
```

#### `#elo`

Returns the Elo rating.

```ruby
# @return [Integer, nil] Elo or nil

player.elo # => 2830
```

#### `#style`

Returns the playing style (SNN notation).

```ruby
# @return [String, nil] SNN style or nil

player.style # => "CHESS"
```

#### `#periods`

Returns the time control periods.

```ruby
# @return [Array<Hash>, nil] array of periods or nil

player.periods
# => [
#   { time: 5400, moves: 40, inc: 0 },
#   { time: 1800, moves: nil, inc: 30 }
# ]
```

### Player Time Control

#### `#has_time_control?`

Checks if the player has time control.

```ruby
# @return [Boolean] true if periods are defined

player.has_time_control? # => true
```

#### `#initial_time_budget`

Calculates the total initial time budget.

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

#### draw_offered_by Errors

```ruby
Game.new(
  setup:           "8/8/8/8/8/8/8/8 / U/u",
  draw_offered_by: "third"
)
# => ArgumentError: "draw_offered_by must be nil, 'first', or 'second'"

Game.new(
  setup:           "8/8/8/8/8/8/8/8 / U/u",
  draw_offered_by: 123
)
# => ArgumentError: "draw_offered_by must be a string or nil"
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
| `draw_offered_by` | String or nil | `nil` | Draw offer indicator |
| `meta` | Hash | `{}` | Metadata fields |
| `sides` | Hash | `{}` | Player information |

### Move Tuple Structure

```ruby
[
  "e2-e4",  # PAN notation (String)
  2.5       # Seconds spent (Float >= 0.0)
]
```

### draw_offered_by Values

```ruby
nil        # No draw offer pending (default)
"first"    # First player has offered a draw
"second"   # Second player has offered a draw
```

### Period Structure

```ruby
{
  time:  300, # Seconds (Integer >= 0, required)
  moves: nil, # Move count (Integer >= 1 or nil)
  inc:   3    # Increment (Integer >= 0, default: 0)
}
```

### Player Structure

```ruby
{
  name:    "Magnus Carlsen", # String (optional)
  elo:     2830,             # Integer >= 0 (optional)
  style:   "CHESS",          # SNN string (optional)
  periods: []                # Array<Hash> (optional)
}
```

### Meta Structure

Standard fields (validated):
```ruby
{
  name:       "Italian Game",         # String
  event:      "World Championship",   # String
  location:   "Dubai",                # String
  round:      5,                      # Integer >= 1
  started_at: "2025-01-27T14:00:00Z", # ISO 8601
  href:       "https://example.com"   # Absolute URL
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

# Offer draw
game = game.with_draw_offered_by("first")

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

### Managing Draw Offers

```ruby
# Offer a draw
game = game.with_draw_offered_by("first")

# Check if an offer is pending
puts "Draw offer from: #{game.draw_offered_by}" if game.draw_offered?

# Accept a draw
game = game.with_status("agreement")

# Cancel a draw (withdraw the offer)
game = game.with_draw_offered_by(nil)
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
  - `sashite-pan` ~> 4.0
  - `sashite-feen` ~> 0.3
  - `sashite-snn` ~> 3.1
  - `sashite-cgsn` ~> 0.1

---

## Links

- [GitHub Repository](https://github.com/sashite/pcn.rb)
- [RubyDoc Documentation](https://rubydoc.info/github/sashite/pcn.rb/main)
- [PCN Specification](https://sashite.dev/specs/pcn/1.0.0/)
- [Examples](https://sashite.dev/specs/pcn/1.0.0/examples/)
- [Draw Offer Examples](https://sashite.dev/specs/pcn/1.0.0/examples/draw-offers/)
