# frozen_string_literal: true

require "simplecov"

SimpleCov.command_name "Unit Tests"
SimpleCov.start

# Tests for Sashite::Pcn (Portable Chess Notation)
#
# Tests the PCN implementation for Ruby, focusing on the functional API
# with immutable Game, Meta, Player, and Sides objects.

require_relative "lib/sashite/pcn"

# Helper function to run a test and report errors
def run_test(name)
  print "  #{name}... "
  yield
  puts "✓ Success"
rescue StandardError => e
  warn "✗ Failure: #{e.message}"
  warn "    #{e.backtrace.first}"
  exit(1)
end

puts
puts "Tests for Sashite::Pcn (Portable Chess Notation) v1.0.0"
puts

# ============================================================================
# 1. MODULE API TESTS
# ============================================================================

puts "Module API Tests"
puts "-" * 80

run_test("parse returns immutable Game object") do
  pcn = {
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  }
  game = Sashite::Pcn.parse(pcn)

  raise "Should return Game" unless game.is_a?(Sashite::Pcn::Game)
  raise "Game should be frozen" unless game.frozen?
end

run_test("valid? returns true for valid PCN") do
  pcn = {
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  }

  raise "Should be valid" unless Sashite::Pcn.valid?(pcn)
end

run_test("valid? returns false for invalid PCN") do
  invalid = { "setup" => "" }

  raise "Should be invalid" if Sashite::Pcn.valid?(invalid)
end

run_test("new creates game from components") do
  game = Sashite::Pcn.new(
    setup: Sashite::Feen.parse("8/8/8/8/8/8/8/8 / C/c"),
    moves: []
  )

  raise "Should return Game" unless game.is_a?(Sashite::Pcn::Game)
  raise "Should be frozen" unless game.frozen?
end

run_test("parse and to_h round-trip correctly") do
  original = {
    "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    "moves" => [["e2", "e4", "C:P"]],
    "status" => "in_progress"
  }

  game = Sashite::Pcn.parse(original)
  result = game.to_h

  raise "setup should match" unless result["setup"] == original["setup"]
  raise "moves should match" unless result["moves"] == original["moves"]
  raise "status should match" unless result["status"] == original["status"]
end

puts

# ============================================================================
# 2. GAME OBJECT TESTS
# ============================================================================

puts "Game Object Tests"
puts "-" * 80

run_test("Game provides required field access") do
  pcn = {
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  }
  game = Sashite::Pcn.parse(pcn)

  raise "Should have setup" unless game.setup.is_a?(Sashite::Feen::Position)
  raise "Should have moves" unless game.moves.is_a?(Array)
end

run_test("Game provides optional field access") do
  pcn = {
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => [],
    "status" => "in_progress",
    "meta" => { "event" => "Tournament" },
    "sides" => {
      "first" => { "name" => "Alice" },
      "second" => { "name" => "Bob" }
    }
  }
  game = Sashite::Pcn.parse(pcn)

  raise "Should have status" unless game.status == "in_progress"
  raise "Should have meta" unless game.meta.is_a?(Sashite::Pcn::Meta)
  raise "Should have sides" unless game.sides.is_a?(Sashite::Pcn::Sides)
end

run_test("Game equality works correctly") do
  pcn1 = { "setup" => "8/8/8/8/8/8/8/8 / C/c", "moves" => [] }
  pcn2 = { "setup" => "8/8/8/8/8/8/8/8 / C/c", "moves" => [] }
  pcn3 = { "setup" => "8/8/8/8/8/8/8/8 / c/C", "moves" => [] }

  game1 = Sashite::Pcn.parse(pcn1)
  game2 = Sashite::Pcn.parse(pcn2)
  game3 = Sashite::Pcn.parse(pcn3)

  raise "Equal games should be ==" unless game1 == game2
  raise "Different games should not be ==" if game1 == game3
end

run_test("Game hash is consistent") do
  pcn = { "setup" => "8/8/8/8/8/8/8/8 / C/c", "moves" => [] }
  game1 = Sashite::Pcn.parse(pcn)
  game2 = Sashite::Pcn.parse(pcn)

  raise "Equal games have same hash" unless game1.hash == game2.hash
end

run_test("Game provides move_count") do
  game = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => [["e2", "e4", "C:P"], ["e7", "e5", "c:p"]]
  })

  raise "Should have 2 moves" unless game.move_count == 2
  raise "size alias" unless game.size == 2
  raise "length alias" unless game.length == 2
end

run_test("Game provides empty?") do
  empty = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })
  with_moves = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => [["e2", "e4", "C:P"]]
  })

  raise "Empty game returns true" unless empty.empty?
  raise "Non-empty game returns false" if with_moves.empty?
end

run_test("Game provides has_status?") do
  with_status = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => [],
    "status" => "in_progress"
  })
  without_status = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })

  raise "With status returns true" unless with_status.has_status?
  raise "Without status returns false" if without_status.has_status?
end

run_test("Game provides has_meta?") do
  with_meta = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => [],
    "meta" => { "event" => "Tournament" }
  })
  without_meta = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })

  raise "With meta returns true" unless with_meta.has_meta?
  raise "Without meta returns false" if without_meta.has_meta?
end

run_test("Game provides has_sides?") do
  with_sides = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => [],
    "sides" => {
      "first" => { "name" => "Alice" }
    }
  })
  without_sides = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })

  raise "With sides returns true" unless with_sides.has_sides?
  raise "Without sides returns false" if without_sides.has_sides?
end

puts

# ============================================================================
# 3. GAME TRANSFORMATIONS
# ============================================================================

puts "Game Transformation Tests"
puts "-" * 80

run_test("add_move returns new game") do
  original = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })

  new_game = original.add_move(["e2", "e4", "C:P"])

  raise "Should return new game" unless new_game.is_a?(Sashite::Pcn::Game)
  raise "Original unchanged" unless original.move_count == 0
  raise "New has move" unless new_game.move_count == 1
  raise "Different objects" unless original.object_id != new_game.object_id
end

run_test("add_move accepts Move object") do
  game = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })

  move = Sashite::Pmn.parse(["e2", "e4", "C:P"])
  new_game = game.add_move(move)

  raise "Should have 1 move" unless new_game.move_count == 1
end

run_test("with_status returns new game") do
  original = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })

  new_game = original.with_status("checkmate")

  raise "Should return new game" unless new_game.is_a?(Sashite::Pcn::Game)
  raise "Original status nil" unless original.status.nil?
  raise "New has status" unless new_game.status == "checkmate"
  raise "Different objects" unless original.object_id != new_game.object_id
end

run_test("with_meta returns new game") do
  original = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })

  meta = Sashite::Pcn::Meta.new(event: "Tournament")
  new_game = original.with_meta(meta)

  raise "Should return new game" unless new_game.is_a?(Sashite::Pcn::Game)
  raise "Original meta nil" unless original.meta.nil?
  raise "New has meta" unless new_game.meta.event == "Tournament"
  raise "Different objects" unless original.object_id != new_game.object_id
end

run_test("with_sides returns new game") do
  original = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })

  sides = Sashite::Pcn::Sides.new(
    first: Sashite::Pcn::Player.new(name: "Alice")
  )
  new_game = original.with_sides(sides)

  raise "Should return new game" unless new_game.is_a?(Sashite::Pcn::Game)
  raise "Original sides nil" unless original.sides.nil?
  raise "New has sides" unless new_game.sides.first.name == "Alice"
  raise "Different objects" unless original.object_id != new_game.object_id
end

run_test("transformations can be chained") do
  game = Sashite::Pcn.parse({
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  })

  result = game
    .add_move(["e2", "e4", "C:P"])
    .with_status("in_progress")
    .add_move(["e7", "e5", "c:p"])

  raise "Should have 2 moves" unless result.move_count == 2
  raise "Should have status" unless result.status == "in_progress"
  raise "Original unchanged" unless game.move_count == 0
end

puts

# ============================================================================
# 4. META OBJECT TESTS
# ============================================================================

puts "Meta Object Tests"
puts "-" * 80

run_test("Meta parses hash correctly") do
  meta = Sashite::Pcn::Meta.parse({
    "event" => "World Championship",
    "round" => 5
  })

  raise "Should have event" unless meta.event == "World Championship"
  raise "Should have round" unless meta.round == 5
end

run_test("Meta.valid? works") do
  valid = { "event" => "Tournament" }
  invalid = { "round" => "not an integer" }

  raise "Valid should return true" unless Sashite::Pcn::Meta.valid?(valid)
  raise "Invalid should return false" if Sashite::Pcn::Meta.valid?(invalid)
end

run_test("Meta all fields optional") do
  meta = Sashite::Pcn::Meta.new

  raise "Should be valid" unless meta.valid?
  raise "Should be empty" unless meta.empty?
end

run_test("Meta provides all field access") do
  meta = Sashite::Pcn::Meta.new(
    name: "Italian Game",
    event: "Tournament",
    location: "London",
    round: 5,
    started_on: "2025-11-15",
    finished_at: "2025-11-15T18:45:00Z",
    href: "https://example.com/game"
  )

  raise "name" unless meta.name == "Italian Game"
  raise "event" unless meta.event == "Tournament"
  raise "location" unless meta.location == "London"
  raise "round" unless meta.round == 5
  raise "started_on" unless meta.started_on == "2025-11-15"
  raise "finished_at" unless meta.finished_at == "2025-11-15T18:45:00Z"
  raise "href" unless meta.href == "https://example.com/game"
end

run_test("Meta validates round >= 1") do
  begin
    Sashite::Pcn::Meta.new(round: 0)
    raise "Should raise error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention >= 1" unless e.message.include?(">= 1")
  end
end

run_test("Meta validates started_on format") do
  valid = Sashite::Pcn::Meta.new(started_on: "2025-11-15")
  raise "Valid date accepted" unless valid.valid?

  begin
    Sashite::Pcn::Meta.new(started_on: "11/15/2025")
    raise "Should raise error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention format" unless e.message.include?("YYYY-MM-DD")
  end
end

run_test("Meta validates finished_at format") do
  valid = Sashite::Pcn::Meta.new(finished_at: "2025-11-15T18:45:00Z")
  raise "Valid datetime accepted" unless valid.valid?

  begin
    Sashite::Pcn::Meta.new(finished_at: "2025-11-15 18:45:00")
    raise "Should raise error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention format" unless e.message.include?("YYYY-MM-DDTHH:MM:SSZ")
  end
end

run_test("Meta validates href is absolute URL") do
  valid_http = Sashite::Pcn::Meta.new(href: "http://example.com")
  valid_https = Sashite::Pcn::Meta.new(href: "https://example.com")

  raise "http accepted" unless valid_http.valid?
  raise "https accepted" unless valid_https.valid?

  begin
    Sashite::Pcn::Meta.new(href: "example.com")
    raise "Should raise error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention absolute URL" unless e.message.include?("absolute URL")
  end
end

run_test("Meta to_h excludes nil values") do
  meta = Sashite::Pcn::Meta.new(event: "Tournament")
  hash = meta.to_h

  raise "Should have event" unless hash["event"] == "Tournament"
  raise "Should not have name" if hash.key?("name")
  raise "Should not have round" if hash.key?("round")
end

run_test("Meta is immutable") do
  meta = Sashite::Pcn::Meta.new(event: "Tournament")

  raise "Should be frozen" unless meta.frozen?
end

puts

# ============================================================================
# 5. PLAYER OBJECT TESTS
# ============================================================================

puts "Player Object Tests"
puts "-" * 80

run_test("Player parses hash correctly") do
  player = Sashite::Pcn::Player.parse({
    "name" => "Alice",
    "elo" => 2800,
    "style" => "CHESS"
  })

  raise "Should have name" unless player.name == "Alice"
  raise "Should have elo" unless player.elo == 2800
  raise "Should have style" unless player.style == "CHESS"
end

run_test("Player.valid? works") do
  valid = { "name" => "Alice" }
  invalid = { "elo" => "not an integer" }

  raise "Valid should return true" unless Sashite::Pcn::Player.valid?(valid)
  raise "Invalid should return false" if Sashite::Pcn::Player.valid?(invalid)
end

run_test("Player all fields optional") do
  player = Sashite::Pcn::Player.new

  raise "Should be valid" unless player.valid?
  raise "Should be empty" unless player.empty?
end

run_test("Player validates style is SNN") do
  valid_upper = Sashite::Pcn::Player.new(style: "CHESS")
  valid_lower = Sashite::Pcn::Player.new(style: "chess")

  raise "Uppercase accepted" unless valid_upper.valid?
  raise "Lowercase accepted" unless valid_lower.valid?

  begin
    Sashite::Pcn::Player.new(style: "123")
    raise "Should raise error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention SNN" unless e.message.include?("SNN")
  end
end

run_test("Player validates elo >= 0") do
  valid = Sashite::Pcn::Player.new(elo: 0)
  raise "Zero accepted" unless valid.valid?

  begin
    Sashite::Pcn::Player.new(elo: -100)
    raise "Should raise error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention >= 0" unless e.message.include?(">= 0")
  end
end

run_test("Player to_h excludes nil values") do
  player = Sashite::Pcn::Player.new(name: "Alice")
  hash = player.to_h

  raise "Should have name" unless hash["name"] == "Alice"
  raise "Should not have elo" if hash.key?("elo")
  raise "Should not have style" if hash.key?("style")
end

run_test("Player is immutable") do
  player = Sashite::Pcn::Player.new(name: "Alice")

  raise "Should be frozen" unless player.frozen?
end

puts

# ============================================================================
# 6. SIDES OBJECT TESTS
# ============================================================================

puts "Sides Object Tests"
puts "-" * 80

run_test("Sides parses hash correctly") do
  sides = Sashite::Pcn::Sides.parse({
    "first" => { "name" => "Alice" },
    "second" => { "name" => "Bob" }
  })

  raise "Should have first" unless sides.first.name == "Alice"
  raise "Should have second" unless sides.second.name == "Bob"
end

run_test("Sides.valid? works") do
  valid = { "first" => { "name" => "Alice" } }
  invalid = { "first" => { "elo" => "not an integer" } }

  raise "Valid should return true" unless Sashite::Pcn::Sides.valid?(valid)
  raise "Invalid should return false" if Sashite::Pcn::Sides.valid?(invalid)
end

run_test("Sides requires at least one player") do
  begin
    Sashite::Pcn::Sides.new
    raise "Should raise error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention at least one" unless e.message.include?("at least one")
  end
end

run_test("Sides accepts only first player") do
  sides = Sashite::Pcn::Sides.new(
    first: Sashite::Pcn::Player.new(name: "Alice")
  )

  raise "Should be valid" unless sides.valid?
  raise "Should have first" unless sides.first.name == "Alice"
  raise "Should not have second" unless sides.second.nil?
end

run_test("Sides accepts only second player") do
  sides = Sashite::Pcn::Sides.new(
    second: Sashite::Pcn::Player.new(name: "Bob")
  )

  raise "Should be valid" unless sides.valid?
  raise "Should have second" unless sides.second.name == "Bob"
  raise "Should not have first" unless sides.first.nil?
end

run_test("Sides normalizes hash to Player") do
  sides = Sashite::Pcn::Sides.new(
    first: { "name" => "Alice" }
  )

  raise "Should convert to Player" unless sides.first.is_a?(Sashite::Pcn::Player)
  raise "Should have name" unless sides.first.name == "Alice"
end

run_test("Sides to_h excludes nil values") do
  sides = Sashite::Pcn::Sides.new(
    first: Sashite::Pcn::Player.new(name: "Alice")
  )
  hash = sides.to_h

  raise "Should have first" unless hash["first"]["name"] == "Alice"
  raise "Should not have second" if hash.key?("second")
end

run_test("Sides is immutable") do
  sides = Sashite::Pcn::Sides.new(
    first: Sashite::Pcn::Player.new(name: "Alice")
  )

  raise "Should be frozen" unless sides.frozen?
end

puts

# ============================================================================
# 7. STATUS VALIDATION TESTS
# ============================================================================

puts "Status Validation Tests"
puts "-" * 80

run_test("Valid status values accepted") do
  valid_statuses = %w[
    in_progress checkmate stalemate bare_king mare_king
    resignation illegal_move time_limit move_limit
    repetition mutual_agreement
  ]

  valid_statuses.each do |status|
    game = Sashite::Pcn.parse({
      "setup" => "8/8/8/8/8/8/8/8 / C/c",
      "moves" => [],
      "status" => status
    })
    raise "#{status} should be valid" unless game.status == status
  end
end

run_test("Invalid status value rejected") do
  begin
    Sashite::Pcn.parse({
      "setup" => "8/8/8/8/8/8/8/8 / C/c",
      "moves" => [],
      "status" => "unknown_status"
    })
    raise "Should raise error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention invalid status" unless e.message.include?("Invalid status")
  end
end

puts

# ============================================================================
# 8. ERROR HANDLING TESTS
# ============================================================================

puts "Error Handling Tests"
puts "-" * 80

run_test("Error::Parse for missing setup") do
  begin
    Sashite::Pcn.parse({ "moves" => [] })
    raise "Should raise Parse error"
  rescue Sashite::Pcn::Error::Parse => e
    raise "Should mention setup" unless e.message.include?("setup")
  end
end

run_test("Error::Parse for missing moves") do
  begin
    Sashite::Pcn.parse({ "setup" => "8/8/8/8/8/8/8/8 / C/c" })
    raise "Should raise Parse error"
  rescue Sashite::Pcn::Error::Parse => e
    raise "Should mention moves" unless e.message.include?("moves")
  end
end

run_test("Error::Parse for non-hash input") do
  begin
    Sashite::Pcn.parse("not a hash")
    raise "Should raise Parse error"
  rescue Sashite::Pcn::Error::Parse => e
    raise "Should mention Hash" unless e.message.include?("Hash")
  end
end

run_test("Error::Parse for moves not array") do
  begin
    Sashite::Pcn.parse({
      "setup" => "8/8/8/8/8/8/8/8 / C/c",
      "moves" => "not an array"
    })
    raise "Should raise Parse error"
  rescue Sashite::Pcn::Error::Parse => e
    raise "Should mention Array" unless e.message.include?("Array")
  end
end

run_test("Error::Validation for invalid FEEN") do
  begin
    Sashite::Pcn.parse({
      "setup" => "invalid feen",
      "moves" => []
    })
    raise "Should raise Validation error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention setup" unless e.message.include?("setup")
  end
end

run_test("Error::Validation for invalid PMN") do
  begin
    Sashite::Pcn.parse({
      "setup" => "8/8/8/8/8/8/8/8 / C/c",
      "moves" => [["e2"]]
    })
    raise "Should raise Validation error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention move" unless e.message.include?("move")
  end
end

run_test("Error::Validation for invalid meta") do
  begin
    Sashite::Pcn.parse({
      "setup" => "8/8/8/8/8/8/8/8 / C/c",
      "moves" => [],
      "meta" => { "round" => -1 }
    })
    raise "Should raise Validation error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention meta" unless e.message.include?("meta")
  end
end

run_test("Error::Validation for invalid sides") do
  begin
    Sashite::Pcn.parse({
      "setup" => "8/8/8/8/8/8/8/8 / C/c",
      "moves" => [],
      "sides" => {}
    })
    raise "Should raise Validation error"
  rescue Sashite::Pcn::Error::Validation => e
    raise "Should mention at least one" unless e.message.include?("at least one")
  end
end

run_test("All errors inherit from base Error") do
  raise "Parse < Error" unless Sashite::Pcn::Error::Parse < Sashite::Pcn::Error
  raise "Validation < Error" unless Sashite::Pcn::Error::Validation < Sashite::Pcn::Error
  raise "Semantic < Error" unless Sashite::Pcn::Error::Semantic < Sashite::Pcn::Error
end

puts

# ============================================================================
# 9. EXAMPLES FROM README
# ============================================================================

puts "Examples from README"
puts "-" * 80

run_test("Minimal valid game") do
  pcn = {
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  }
  game = Sashite::Pcn.parse(pcn)

  raise "Should be valid" unless game.valid?
  raise "Should be empty" unless game.empty?
  raise "No status" unless !game.has_status?
end

run_test("Traditional chess game") do
  pcn = {
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
  }
  game = Sashite::Pcn.parse(pcn)

  raise "Should have 4 moves" unless game.move_count == 4
  raise "Should have meta" unless game.meta.event == "World Championship"
  raise "Should have sides" unless game.sides.first.name == "Magnus Carlsen"
end

run_test("Cross-style game (Chess vs Makruk)") do
  pcn = {
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
  }
  game = Sashite::Pcn.parse(pcn)

  raise "Should parse" unless game.valid?
  raise "Should have 2 moves" unless game.move_count == 2
end

run_test("Shōgi game with drops") do
  pcn = {
    "setup" => "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL / S/s",
    "moves" => [
      ["e1", "e2", "S:P"],
      ["*", "e5", "s:p"]
    ],
    "status" => "in_progress"
  }
  game = Sashite::Pcn.parse(pcn)

  raise "Should parse" unless game.valid?
  raise "Should have 2 moves" unless game.move_count == 2
end

puts

# ============================================================================
# 10. INTEGRATION TESTS
# ============================================================================

puts "Integration Tests"
puts "-" * 80

run_test("Complete game workflow") do
  # Start with minimal game
  game = Sashite::Pcn.new(
    setup: Sashite::Feen.parse("8/8/8/8/8/8/8/8 / C/c"),
    moves: []
  )

  # Add metadata
  game = game.with_meta(
    Sashite::Pcn::Meta.new(
      event: "Tournament",
      round: 1,
      started_on: "2025-11-15"
    )
  )

  # Add players
  game = game.with_sides(
    Sashite::Pcn::Sides.new(
      first: Sashite::Pcn::Player.new(name: "Alice", elo: 2800),
      second: Sashite::Pcn::Player.new(name: "Bob", elo: 2750)
    )
  )

  # Add moves
  game = game.add_move(["e2", "e4", "C:P"])
  game = game.add_move(["e7", "e5", "c:p"])

  # Set status
  game = game.with_status("in_progress")

  # Verify final state
  raise "Should have 2 moves" unless game.move_count == 2
  raise "Should have meta" unless game.meta.event == "Tournament"
  raise "Should have sides" unless game.sides.first.name == "Alice"
  raise "Should have status" unless game.status == "in_progress"

  # Round-trip
  hash = game.to_h
  restored = Sashite::Pcn.parse(hash)
  raise "Should round-trip" unless restored == game
end

run_test("Parse multiple games in sequence") do
  games_data = [
    {
      "setup" => "8/8/8/8/8/8/8/8 / C/c",
      "moves" => []
    },
    {
      "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
      "moves" => [["e2", "e4", "C:P"]]
    },
    {
      "setup" => "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL / S/s",
      "moves" => []
    }
  ]

  games = games_data.map { |data| Sashite::Pcn.parse(data) }

  raise "Should parse all" unless games.size == 3
  raise "All Game objects" unless games.all? { |g| g.is_a?(Sashite::Pcn::Game) }
  raise "All valid" unless games.all?(&:valid?)
end

run_test("Complex game with all features") do
  pcn = {
    "meta" => {
      "name" => "Italian Game",
      "event" => "World Championship",
      "location" => "London, UK",
      "round" => 5,
      "started_on" => "2025-11-15",
      "finished_at" => "2025-11-15T18:45:00Z",
      "href" => "https://example.com/game/12345"
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
      ["b8", "c6", "c:n"],
      ["f1", "c4", "C:B"],
      ["f8", "c5", "c:b"]
    ],
    "status" => "in_progress"
  }

  game = Sashite::Pcn.parse(pcn)

  # Verify all components
  raise "Valid game" unless game.valid?
  raise "Has meta" unless game.meta.name == "Italian Game"
  raise "Has sides" unless game.sides.first.name == "Magnus Carlsen"
  raise "Has 6 moves" unless game.move_count == 6
  raise "Has status" unless game.status == "in_progress"

  # Round-trip
  hash = game.to_h
  restored = Sashite::Pcn.parse(hash)
  raise "Should equal" unless restored == game
end

puts

# ============================================================================
# SUMMARY
# ============================================================================

puts
puts "All PCN tests passed!"
puts
