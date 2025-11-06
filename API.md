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
                            "status" => "in_progress",
                            "winner" => nil
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

#### `Game.new(setup:, moves: [], status: nil, draw_offered_by: nil, winner: nil, meta: {}, sides: {})`

Creates a new game instance with validation.

```ruby
# Parameters
# @param setup [String] FEEN position (required)
# @param moves [Array<Array>] array of [PAN, seconds] tuples (optional)
# @param status [String, nil] CGSN status (optional)
# @param draw_offered_by [String, nil] draw offer indicator ("first", "second", or nil) (optional)
# @param winner [String, nil] competitive outcome ("first", "second", "none", or nil) (optional)
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
  winner: nil,
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
  draw_offered_by: "first", # First player has offered a draw
  winner:          nil
)

# Finished game with winner
game = Sashite::Pcn::Game.new(
  setup:  "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves:  [["e2-e4", 8.0], ["e7-e5", 12.0], ["g1-f3", 15.0]],
  status: "resignation",
  winner: "first" # First player won (second player resigned)
)

# Draw by agreement
game = Sashite::Pcn::Game.new(
  setup:           "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves:           [["e2-e4", 8.0], ["e7-e5", 12.0]],
  status:          "agreement",
  draw_offered_by: "first",
  winner:          "none" # No winner (draw)
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

**Independence from `status` and `winner`:**

The `draw_offered_by` field is completely independent of both `status` and `winner` fields. It records communication between players (proposal state), while `status` records the observable game state (terminal condition) and `winner` records the competitive outcome.

**Common state transitions:**

1. **Offer made**: `draw_offered_by` changes from `nil` to `"first"` or `"second"`, `status` remains `"in_progress"`, `winner` remains `nil`
2. **Offer accepted**: `status` transitions to `"agreement"`, `winner` becomes `"none"`, `draw_offered_by` may remain set or be cleared (implementation choice)
3. **Offer canceled/withdrawn**: `draw_offered_by` returns to `nil`, `status` remains `"in_progress"`, `winner` remains `nil`

#### `#winner`

Returns the competitive outcome of the game.

```ruby
# @return [String, nil] "first", "second", "none", or nil

game.winner # => "first"   # First player won
game.winner # => "second"  # Second player won
game.winner # => "none"    # Draw (no winner)
game.winner # => nil       # Outcome not determined or game in progress
```

**`winner` field semantics:**

- **`nil`** (default): Outcome not determined or game in progress
- **`"first"`**: The first player won the game
- **`"second"`**: The second player won the game
- **`"none"`**: Draw (no winner)

**Purpose and benefits:**

The `winner` field explicitly records the competitive outcome, eliminating ambiguity in game status interpretation. It is particularly useful for clarifying ambiguous statuses:

**Disambiguating ambiguous statuses:**

- **Resignation**: `status: "resignation", winner: "first"` clarifies that the second player resigned
- **Time limit**: `status: "time_limit", winner: "second"` clarifies that the first player lost on time
- **Illegal move**: `status: "illegal_move", winner: "first"` clarifies that the second player made an illegal move
- **Agreement**: `status: "agreement", winner: "none"` explicitly confirms the draw

**Consistency with `status`:**

While `winner` can often be inferred from `status` and position, explicit declaration:
- Eliminates need for complex inference logic
- Supports variants with different rule interpretations
- Provides immediate clarity for analysis and display
- Allows override in special cases or tournament rules

**Recommended consistency:**

| Status | Expected Winner | Notes |
|--------|-----------------|-------|
| `"checkmate"` | `"first"` or `"second"` | Winner according to who delivered checkmate |
| `"stalemate"` | `"none"` | Typically draw in Western chess |
| `"resignation"` | `"first"` or `"second"` | Opposite of who resigned |
| `"time_limit"` | `"first"` or `"second"` | Opposite of who exceeded time |
| `"repetition"` | `"none"` or other | Depends on game rules |
| `"agreement"` | `"none"` | Generally draw by agreement |
| `"insufficient"` | `"none"` | Draw by insufficient material |
| `"in_progress"` | `null` | Game not finished |

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

#### `#event`

Returns event name.

```ruby
# @return [String, nil] event name or nil

game.event # => "World Championship"
```

#### `#round`

Returns round number.

```ruby
# @return [Integer, nil] round number or nil

game.round # => 5
```

#### `#location`

Returns location.

```ruby
# @return [String, nil] location or nil

game.location # => "Dubai"
```

#### `#started_at`

Returns start datetime.

```ruby
# @return [String, nil] ISO 8601 datetime or nil

game.started_at # => "2025-01-27T14:00:00Z"
```

#### `#href`

Returns reference URL.

```ruby
# @return [String, nil] URL or nil

game.href # => "https://example.com/game/123"
```

### Game Transformations

#### `#with_status(new_status)`

Returns new game with updated status (immutable).

```ruby
# @param new_status [String, nil] new status value
# @return [Game] new game instance with updated status
# @raise [ArgumentError] if status is invalid

# Example
updated = game.with_status("resignation")
```

#### `#with_draw_offered_by(player)`

Returns new game with updated draw offer (immutable).

```ruby
# @param player [String, nil] "first", "second", or nil
# @return [Game] new game instance with updated draw offer
# @raise [ArgumentError] if player is invalid

# Example
# First player offers a draw
game_with_offer = game.with_draw_offered_by("first")

# Withdraw draw offer
game_no_offer = game.with_draw_offered_by(nil)
```

#### `#with_winner(new_winner)`

Returns new game with updated winner (immutable).

```ruby
# @param new_winner [String, nil] "first", "second", "none", or nil
# @return [Game] new game instance with updated winner
# @raise [ArgumentError] if winner is invalid

# Examples
# First player wins
game_first_wins = game.with_winner("first")

# Second player wins
game_second_wins = game.with_winner("second")

# Draw (no winner)
game_draw = game.with_winner("none")

# Clear winner (game in progress)
game_in_progress = game.with_winner(nil)
```

#### `#with_meta(**new_meta)`

Returns new game with updated metadata (immutable).

```ruby
# @param new_meta [Hash] metadata to merge
# @return [Game] new game instance with updated metadata

# Example
updated = game.with_meta(event: "Casual Game", round: 1)
```

#### `#with_moves(new_moves)`

Returns new game with specified move sequence (immutable).

```ruby
# @param new_moves [Array<Array>] new move sequence of [PAN, seconds] tuples
# @return [Game] new game instance with new moves
# @raise [ArgumentError] if move format is invalid

# Example
updated = game.with_moves([["e2-e4", 2.0], ["e7-e5", 3.0]])
```

### Game Predicates

#### `#in_progress?`

Checks if the game is in progress.

```ruby
# @return [Boolean, nil] true if in progress, false if finished, nil if indeterminate

# Example
game.in_progress? # => true
```

#### `#finished?`

Checks if the game is finished.

```ruby
# @return [Boolean, nil] true if finished, false if in progress, nil if indeterminate

# Example
game.finished? # => false
```

#### `#draw_offered?`

Checks if a draw offer is pending.

```ruby
# @return [Boolean] true if a draw offer is pending

# Example
game.draw_offered?  # => true (if draw_offered_by is "first" or "second")
game.draw_offered?  # => false (if draw_offered_by is nil)
```

#### `#has_winner?`

Checks if a winner has been determined.

```ruby
# @return [Boolean] true if winner is determined (first, second, or none)

# Example
game.has_winner?  # => true (if winner is "first", "second", or "none")
game.has_winner?  # => false (if winner is nil)
```

#### `#decisive?`

Checks if the game had a decisive outcome (not a draw).

```ruby
# @return [Boolean, nil] true if decisive (first or second won), false if draw, nil if no winner

# Example
game.decisive?  # => true (if winner is "first" or "second")
game.decisive?  # => false (if winner is "none")
game.decisive?  # => nil (if winner is nil)
```

#### `#drawn?`

Checks if the game ended in a draw.

```ruby
# @return [Boolean] true if winner is "none" (draw)

# Example
game.drawn?  # => true (if winner is "none")
game.drawn?  # => false (if winner is nil, "first", or "second")
```

### Game Serialization

#### `#to_h`

Converts to hash representation.

```ruby
# @return [Hash] hash with string keys ready for JSON serialization

# Example
game.to_h
# => {
#   "setup" => "...",
#   "moves" => [["e2-e4", 2.5], ["e7-e5", 3.1]],
#   "status" => "in_progress",
#   "draw_offered_by" => "first",
#   "winner" => nil,
#   "meta" => {...},
#   "sides" => {...}
# }
```

#### `#to_json(*args)`

Converts to JSON string.

```ruby
# @return [String] JSON representation

# Example
game.to_json
# => '{"setup":"...","moves":[["e2-e4",2.5],["e7-e5",3.1]],...}'

require "json"
JSON.pretty_generate(game.to_h)
```

#### `#==(other)`

Compares with another game.

```ruby
# @param other [Object] object to compare
# @return [Boolean] true if equal

# Example
game1 == game2 # => true if all attributes match
```

#### `#hash`

Generates hash code.

```ruby
# @return [Integer] hash code for this game

# Example
game.hash # => 123456789
```

#### `#inspect`

Generates debug representation.

```ruby
# @return [String] debug string

# Example
game.inspect
# => "#<Game setup=\"...\" moves=[...] status=\"in_progress\" draw_offered_by=\"first\" winner=nil>"
```

---

## Class: Meta

Represents game metadata with support for both standard and custom fields.

### Meta Standard Fields

Standard fields with validation:

```ruby
meta = Sashite::Pcn::Game::Meta.new(
  name:       "Italian Game",         # String
  event:      "World Championship",   # String
  location:   "Dubai",                # String
  round:      5,                      # Integer >= 1
  started_at: "2025-01-27T14:00:00Z", # ISO 8601
  href:       "https://example.com"   # Absolute URL
)
```

### Meta Custom Fields

Custom fields pass through without validation:

```ruby
meta = Sashite::Pcn::Game::Meta.new(
  platform:    "lichess.org",
  opening_eco: "B90",
  rated:       true,
  arbiter:     "John Smith"
)
```

### Meta Access Methods

#### `#[](key)`

Access field by symbol or string key.

```ruby
# @param key [Symbol, String] field name
# @return [Object, nil] field value or nil

meta[:event]   # => "World Championship"
meta["event"]  # => "World Championship"
```

#### `#fetch(key, default = nil)`

Fetch field with optional default.

```ruby
# @param key [Symbol, String] field name
# @param default [Object] default value
# @return [Object] field value or default

meta.fetch(:event)           # => "World Championship"
meta.fetch(:missing, "N/A")  # => "N/A"
```

#### `#key?(key)`

Check if field exists.

```ruby
# @param key [Symbol, String] field name
# @return [Boolean] true if field exists

meta.key?(:event)   # => true
meta.key?(:missing) # => false
```

### Meta Iteration & Collection

#### `#each`

Iterate over fields.

```ruby
# @yield [key, value] field key and value
# @return [Enumerator] if no block given

meta.each do |key, value|
  puts "#{key}: #{value}"
end
```

#### `#keys`

Get all field keys.

```ruby
# @return [Array<Symbol>] field keys

meta.keys # => [:event, :round, :started_at]
```

#### `#values`

Get all field values.

```ruby
# @return [Array<Object>] field values

meta.values # => ["World Championship", 5, "2025-01-27T14:00:00Z"]
```

#### `#empty?`

Check if metadata is empty.

```ruby
# @return [Boolean] true if no fields

meta.empty? # => false
```

#### `#to_h`

Convert to hash.

```ruby
# @return [Hash] hash with string keys

meta.to_h
# => {
#   "event" => "World Championship",
#   "round" => 5,
#   "started_at" => "2025-01-27T14:00:00Z"
# }
```

### Meta Comparison & Equality

#### `#==(other)`

Compare with another Meta.

```ruby
# @param other [Object] object to compare
# @return [Boolean] true if equal

meta1 == meta2 # => true if all fields match
```

---

## Class: Sides

Represents player information for both sides.

### Sides Player Access

#### `#first`

Get first player information.

```ruby
# @return [Player, nil] first player or nil

sides.first
# => #<Player name="Magnus Carlsen" elo=2830 style="CHESS" ...>
```

#### `#second`

Get second player information.

```ruby
# @return [Player, nil] second player or nil

sides.second
# => #<Player name="Hikaru Nakamura" elo=2794 style="chess" ...>
```

### Sides Indexed Access

#### `#[](index)`

Access player by numeric index.

```ruby
# @param index [Integer] 0 for first, 1 for second
# @return [Player, nil] player or nil

sides[0]  # => first player
sides[1]  # => second player
sides[2]  # => nil
```

### Sides Batch Operations

#### `#names`

Get both player names.

```ruby
# @return [Array<String, nil>] array of names (may contain nils)

sides.names # => ["Magnus Carlsen", "Hikaru Nakamura"]
```

#### `#elos`

Get both player ELO ratings.

```ruby
# @return [Array<Integer, nil>] array of ratings (may contain nils)

sides.elos # => [2830, 2794]
```

#### `#styles`

Get both player styles.

```ruby
# @return [Array<String, nil>] array of styles (may contain nils)

sides.styles # => ["CHESS", "chess"]
```

#### `#periods`

Get both player time control periods.

```ruby
# @return [Array<Array<Hash>, nil>] array of period arrays (may contain nils)

sides.periods
# => [
#   [{ time: 300, moves: nil, inc: 3 }],
#   [{ time: 300, moves: nil, inc: 3 }]
# ]
```

### Sides Time Control Analysis

#### `#symmetric_time_control?`

Check if both players have identical time control.

```ruby
# @return [Boolean] true if time controls are identical

sides.symmetric_time_control? # => true
```

#### `#mixed_time_control?`

Check if players have different time controls.

```ruby
# @return [Boolean] true if time controls differ

sides.mixed_time_control? # => false
```

#### `#unlimited_game?`

Check if neither player has time control.

```ruby
# @return [Boolean] true if no time controls defined

sides.unlimited_game? # => false
```

### Sides Predicates

#### `#complete?`

Check if both players are defined.

```ruby
# @return [Boolean] true if both first and second are defined

sides.complete? # => true
```

#### `#empty?`

Check if no players are defined.

```ruby
# @return [Boolean] true if both first and second are nil

sides.empty? # => false
```

### Sides Collections & Iteration

#### `#each`

Iterate over players.

```ruby
# @yield [player] player instance
# @return [Enumerator] if no block given

sides.each do |player|
  puts player.name
end
```

#### `#to_h`

Convert to hash.

```ruby
# @return [Hash] hash with string keys

sides.to_h
# => {
#   "first" => { "name" => "...", ... },
#   "second" => { "name" => "...", ... }
# }
```

---

## Class: Player

Represents individual player information.

### Player Core Attributes

#### `#name`

Get player name.

```ruby
# @return [String, nil] player name or nil

player.name # => "Magnus Carlsen"
```

#### `#elo`

Get player ELO rating.

```ruby
# @return [Integer, nil] ELO rating or nil

player.elo # => 2830
```

#### `#style`

Get player style.

```ruby
# @return [String, nil] SNN style string or nil

player.style # => "CHESS"
```

#### `#periods`

Get time control periods.

```ruby
# @return [Array<Hash>, nil] array of period hashes or nil

player.periods
# => [
#   { time: 5400, moves: 40, inc: 0 },
#   { time: 1800, moves: nil, inc: 30 }
# ]
```

### Player Time Control

#### `#has_time_control?`

Check if player has time control defined.

```ruby
# @return [Boolean] true if periods is non-empty

player.has_time_control? # => true
```

#### `#initial_time_budget`

Calculate total initial time budget.

```ruby
# @return [Integer, nil] total seconds or nil

player.initial_time_budget # => 7200 (5400 + 1800)
```

#### `#fischer?`

Check if using Fischer/increment time control.

```ruby
# @return [Boolean] true if single period with increment and no move quota

player.fischer? # => true
```

#### `#byoyomi?`

Check if using byÅyomi time control.

```ruby
# @return [Boolean] true if multiple periods with moves=1

player.byoyomi? # => false
```

#### `#canadian?`

Check if using Canadian time control.

```ruby
# @return [Boolean] true if has period with moves>1

player.canadian? # => false
```

### Player Predicates

#### `#complete?`

Check if all fields are defined.

```ruby
# @return [Boolean] true if name, elo, style, and periods all present

player.complete? # => true
```

#### `#anonymous?`

Check if player has no name.

```ruby
# @return [Boolean] true if name is nil

player.anonymous? # => false
```

### Player Serialization

#### `#to_h`

Convert to hash.

```ruby
# @return [Hash] hash with string keys

player.to_h
# => {
#   "name" => "Magnus Carlsen",
#   "elo" => 2830,
#   "style" => "CHESS",
#   "periods" => [...]
# }
```

---

## Validation & Errors

### Error Handling

All validation errors are raised as `ArgumentError` with descriptive messages.

```ruby
begin
  game = Sashite::Pcn::Game.new(setup: invalid_setup)
rescue ArgumentError => e
  puts "Validation failed: #{e.message}"
end
```

### Common Error Scenarios

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

#### winner Errors

```ruby
Game.new(
  setup:  "8/8/8/8/8/8/8/8 / U/u",
  winner: "third"
)
# => ArgumentError: "winner must be nil, 'first', 'second', or 'none'"

Game.new(
  setup:  "8/8/8/8/8/8/8/8 / U/u",
  winner: 123
)
# => ArgumentError: "winner must be a string or nil"
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
| `winner` | String or nil | `nil` | Competitive outcome |
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

### winner Values

```ruby
nil        # Outcome not determined or game in progress (default)
"first"    # First player won
"second"   # Second player won
"none"     # Draw (no winner)
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

# Finish with result
game = game.with_status("resignation")
game = game.with_winner("first") # Second player resigned
```

### Recording Game Results

```ruby
# First player wins by checkmate
game = game.with_status("checkmate")
game = game.with_winner("first")

# Second player wins on time
game = game.with_status("time_limit")
game = game.with_winner("second")

# Draw by agreement
game = game.with_status("agreement")
game = game.with_winner("none")

# Draw by stalemate
game = game.with_status("stalemate")
game = game.with_winner("none")

# Second player resigns
game = game.with_status("resignation")
game = game.with_winner("first")
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

# ByÅyomi
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

### Managing Draw Offers and Results

```ruby
# Offer a draw
game = game.with_draw_offered_by("first")

# Check if an offer is pending
puts "Draw offer from: #{game.draw_offered_by}" if game.draw_offered?

# Accept a draw
game = game.with_status("agreement")
game = game.with_winner("none")

# Cancel a draw (withdraw the offer)
game = game.with_draw_offered_by(nil)

# Check game outcome
if game.has_winner?
  if game.drawn?
    puts "Game ended in a draw"
  elsif game.winner == "first"
    puts "First player wins!"
  else
    puts "Second player wins!"
  end
end
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

### Complete Game Example with Winner

```ruby
require "sashite/pcn"

# Full game with all features including winner
game = Sashite::Pcn::Game.new(
  meta:   {
    event:      "World Championship",
    round:      5,
    location:   "Dubai",
    started_at: "2025-01-27T14:00:00Z"
  },
  sides:  {
    first:  {
      name:    "Magnus Carlsen",
      elo:     2830,
      style:   "CHESS",
      periods: [{ time: 5400, moves: 40, inc: 0 }]
    },
    second: {
      name:    "Fabiano Caruana",
      elo:     2820,
      style:   "chess",
      periods: [{ time: 5400, moves: 40, inc: 0 }]
    }
  },
  setup:  "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves:  [
    ["e2-e4", 32.1], ["c7-c5", 28.5],
    ["g1-f3", 45.2], ["d7-d6", 31.0],
    ["d2-d4", 38.9], ["c5+d4", 29.8]
    # ... more moves
  ],
  status: "resignation",
  winner: "first" # Magnus Carlsen wins (Fabiano resigned)
)

# Display result
puts "Event: #{game.event}"
puts "Status: #{game.status}"
puts "Winner: #{game.winner == 'first' ? game.first_player.name : game.second_player.name}"
puts "Result: First player wins by resignation"
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
