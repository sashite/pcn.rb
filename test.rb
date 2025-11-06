#!/usr/bin/env ruby
# frozen_string_literal: true

require "simplecov"

SimpleCov.command_name "Unit Tests"
SimpleCov.start

# Tests for Sashite::Pcn (Portable Chess Notation)
#
# Tests the PCN implementation for Ruby, covering game records,
# metadata, player information, time control, and specification compliance
# according to the PCN Specification v1.0.0.
#
# @see https://sashite.dev/specs/pcn/1.0.0/ PCN Specification v1.0.0
#
# This test suite validates strict compliance with the official specification.

require_relative "lib/sashite-pcn"

# Helper function to run a test and report errors
def run_test(name)
  print "  #{name}... "
  yield
  puts "✔ Success"
rescue StandardError => e
  warn "✗ Failure: #{e.message}"
  warn "    #{e.backtrace.first}"
  exit(1)
end

puts
puts "Tests for Sashite::Pcn (Portable Chess Notation)"
puts "Validating compliance with PCN Specification v1.0.0"
puts "Specification: https://sashite.dev/specs/pcn/1.0.0/"
puts

# ============================================================================
# META TESTS
# ============================================================================

puts "META TESTS:"

run_test("Meta accepts no arguments (empty metadata)") do
  meta = Sashite::Pcn::Game::Meta.new

  raise "Empty meta should be valid" unless meta.is_a?(Sashite::Pcn::Game::Meta)
  raise "Empty meta to_h should return empty hash" unless meta.to_h == {}
  raise "Empty meta should be empty" unless meta.empty?
  raise "Empty meta should have no keys" unless meta.keys == []
end

run_test("Meta validates standard string fields") do
  meta = Sashite::Pcn::Game::Meta.new(
    name: "Sicilian Defense",
    event: "World Championship",
    location: "London, UK"
  )

  raise "Valid string fields should be accepted" unless meta[:name] == "Sicilian Defense"
  raise "Valid string fields should be accepted" unless meta[:event] == "World Championship"
  raise "Valid string fields should be accepted" unless meta[:location] == "London, UK"
  raise "Meta with fields should not be empty" if meta.empty?
  raise "Meta should have 3 keys" unless meta.keys.sort == [:event, :location, :name]
end

run_test("Meta validates round must be positive integer") do
  # Valid round
  valid_meta = Sashite::Pcn::Game::Meta.new(round: 5)
  raise "Valid round should be accepted" unless valid_meta[:round] == 5

  # Invalid: zero
  begin
    Sashite::Pcn::Game::Meta.new(round: 0)
    raise "Round 0 should be rejected"
  rescue ArgumentError => e
    raise "Error should mention round" unless e.message.include?("round")
  end

  # Invalid: negative
  begin
    Sashite::Pcn::Game::Meta.new(round: -1)
    raise "Negative round should be rejected"
  rescue ArgumentError => e
    raise "Error should mention round" unless e.message.include?("round")
  end

  # Invalid: not an integer
  begin
    Sashite::Pcn::Game::Meta.new(round: 1.5)
    raise "Non-integer round should be rejected"
  rescue ArgumentError => e
    raise "Error should mention round" unless e.message.include?("round")
  end
end

run_test("Meta validates started_at ISO 8601 datetime format") do
  # Valid formats
  valid_datetimes = [
    "2025-01-27T14:00:00Z",          # UTC
    "2025-01-27T14:00:00+02:00",     # With timezone
    "2025-01-27T14:00:00.123Z",      # With milliseconds
    "2025-01-27T14:00:00"            # Local time
  ]

  valid_datetimes.each do |dt|
    meta = Sashite::Pcn::Game::Meta.new(started_at: dt)
    raise "Valid datetime '#{dt}' should be accepted" unless meta[:started_at] == dt
  end

  # Invalid formats (date only, wrong format)
  invalid_datetimes = [
    "2025-01-27",                    # Date only
    "15/01/2025",                    # Wrong format
    "2025-1-27T14:00:00Z",          # Wrong date format
    "Jan 27, 2025 14:00",           # Text format
    "2025-01-27 14:00:00Z"          # Space instead of T
  ]

  invalid_datetimes.each do |dt|
    begin
      Sashite::Pcn::Game::Meta.new(started_at: dt)
      raise "Invalid datetime format '#{dt}' should be rejected"
    rescue ArgumentError => e
      raise "Error should mention started_at" unless e.message.include?("started_at")
    end
  end
end

run_test("Meta validates href as absolute URL") do
  # Valid URLs
  valid_urls = [
    "https://example.com/game/123",
    "http://chess.com/games/456",
    "https://example.com",
    "http://localhost:3000/game"
  ]

  valid_urls.each do |url|
    meta = Sashite::Pcn::Game::Meta.new(href: url)
    raise "Valid URL '#{url}' should be accepted" unless meta[:href] == url
  end

  # Invalid URLs
  invalid_urls = [
    "/game/123",                     # Relative URL
    "example.com/game",              # No scheme
    "ftp://example.com",            # Wrong scheme
    "https://",                     # Incomplete
    ""                              # Empty
  ]

  invalid_urls.each do |url|
    begin
      Sashite::Pcn::Game::Meta.new(href: url)
      raise "Invalid URL '#{url}' should be rejected"
    rescue ArgumentError => e
      raise "Error should mention href" unless e.message.include?("href")
    end
  end
end

run_test("Meta accepts custom fields without validation") do
  meta = Sashite::Pcn::Game::Meta.new(
    event: "Tournament",
    platform: "lichess.org",
    time_control: "3+2",
    rated: true,
    custom_number: 42,
    tags: ["tactical", "endgame"],
    nested: { key: "value" }
  )

  raise "Custom fields should be stored" unless meta[:platform] == "lichess.org"
  raise "Custom fields should be stored" unless meta[:time_control] == "3+2"
  raise "Custom fields should be stored" unless meta[:rated] == true
  raise "Custom fields should be stored" unless meta[:custom_number] == 42
  raise "Custom fields should be stored" unless meta[:tags] == ["tactical", "endgame"]
  raise "Custom fields should be stored" unless meta[:nested] == { key: "value" }
end

run_test("Meta key? method works correctly") do
  meta = Sashite::Pcn::Game::Meta.new(event: "Tournament", round: 5)

  raise "key?(:event) should return true" unless meta.key?(:event)
  raise "key?('event') should return true" unless meta.key?("event")
  raise "key?(:round) should return true" unless meta.key?(:round)
  raise "key?(:missing) should return false" if meta.key?(:missing)
end

run_test("Meta each iterates over fields") do
  meta = Sashite::Pcn::Game::Meta.new(event: "Tournament", round: 5, platform: "lichess")

  count = 0
  keys = []
  values = []

  meta.each do |k, v|
    count += 1
    keys << k
    values << v
  end

  raise "Should iterate 3 times" unless count == 3
  raise "Should iterate over all keys" unless keys.sort == [:event, :platform, :round]
  raise "Should have correct values" unless values == ["Tournament", 5, "lichess"]
end

run_test("Meta equality comparison") do
  meta1 = Sashite::Pcn::Game::Meta.new(event: "Tournament", round: 5)
  meta2 = Sashite::Pcn::Game::Meta.new(event: "Tournament", round: 5)
  meta3 = Sashite::Pcn::Game::Meta.new(event: "Tournament", round: 6)

  raise "Equal meta should be equal" unless meta1 == meta2
  raise "Different meta should not be equal" if meta1 == meta3
end

run_test("Meta is immutable") do
  meta = Sashite::Pcn::Game::Meta.new(event: "Tournament")

  raise "Meta should be frozen" unless meta.frozen?
  raise "Meta data should be frozen" unless meta.to_h.frozen?
end

# ============================================================================
# PLAYER TESTS
# ============================================================================

puts "\nPLAYER TESTS:"

run_test("Player accepts no arguments (empty player)") do
  player = Sashite::Pcn::Game::Sides::Player.new

  raise "Empty player should be valid" unless player.is_a?(Sashite::Pcn::Game::Sides::Player)
  raise "Empty player should have no fields" unless player.to_h == {}
  raise "Empty player should be empty" unless player.empty?
  raise "Empty player should have no time control" if player.has_time_control?
  raise "Empty player should have unlimited time" unless player.unlimited_time?
end

run_test("Player validates style with SNN") do
  # Valid styles
  player1 = Sashite::Pcn::Game::Sides::Player.new(style: "CHESS")
  raise "Uppercase style should be accepted" unless player1.style.to_s == "CHESS"
  raise "Player with style should not be empty" if player1.empty?

  player2 = Sashite::Pcn::Game::Sides::Player.new(style: "chess")
  raise "Lowercase style should be accepted" unless player2.style.to_s == "chess"

  player3 = Sashite::Pcn::Game::Sides::Player.new(style: "shogi")
  raise "Other game style should be accepted" unless player3.style.to_s == "shogi"

  # Invalid: mixed case (SNN doesn't allow)
  begin
    Sashite::Pcn::Game::Sides::Player.new(style: "Chess")
    raise "Mixed case style should be rejected"
  rescue ArgumentError
    # Expected
  end

  # Invalid: not a string
  begin
    Sashite::Pcn::Game::Sides::Player.new(style: 123)
    raise "Non-string style should be rejected"
  rescue ArgumentError => e
    raise "Error should mention style" unless e.message.include?("style")
  end
end

run_test("Player validates name as string") do
  player = Sashite::Pcn::Game::Sides::Player.new(name: "Magnus Carlsen")
  raise "Valid name should be accepted" unless player.name == "Magnus Carlsen"

  # Empty string is valid
  player_empty = Sashite::Pcn::Game::Sides::Player.new(name: "")
  raise "Empty string name should be accepted" unless player_empty.name == ""

  # Invalid: not a string
  begin
    Sashite::Pcn::Game::Sides::Player.new(name: 123)
    raise "Non-string name should be rejected"
  rescue ArgumentError => e
    raise "Error should mention name" unless e.message.include?("name")
  end
end

run_test("Player validates elo as non-negative integer") do
  # Valid elo
  player = Sashite::Pcn::Game::Sides::Player.new(elo: 2830)
  raise "Valid elo should be accepted" unless player.elo == 2830

  # Valid: zero
  player_zero = Sashite::Pcn::Game::Sides::Player.new(elo: 0)
  raise "Elo 0 should be accepted" unless player_zero.elo == 0

  # Invalid: negative
  begin
    Sashite::Pcn::Game::Sides::Player.new(elo: -100)
    raise "Negative elo should be rejected"
  rescue ArgumentError => e
    raise "Error should mention elo" unless e.message.include?("elo")
  end

  # Invalid: not an integer
  begin
    Sashite::Pcn::Game::Sides::Player.new(elo: 2830.5)
    raise "Float elo should be rejected"
  rescue ArgumentError => e
    raise "Error should mention elo" unless e.message.include?("elo")
  end
end

run_test("Player accepts periods for time control") do
  # Fischer time control
  player = Sashite::Pcn::Game::Sides::Player.new(
    periods: [{ time: 300, moves: nil, inc: 3 }]
  )

  raise "Should have time control" unless player.has_time_control?
  raise "Should not have unlimited time" if player.unlimited_time?
  raise "Should have 300 seconds budget" unless player.initial_time_budget == 300
  raise "Periods should be stored" unless player.periods == [{ time: 300, moves: nil, inc: 3 }]
end

run_test("Player validates period structure") do
  # Valid: minimal period (only time)
  player = Sashite::Pcn::Game::Sides::Player.new(
    periods: [{ time: 600 }]
  )
  raise "Minimal period should work" unless player.periods == [{ time: 600, moves: nil, inc: 0 }]

  # Valid: complete period
  player2 = Sashite::Pcn::Game::Sides::Player.new(
    periods: [{ time: 5400, moves: 40, inc: 0 }]
  )
  raise "Complete period should work" unless player2.periods.first[:moves] == 40

  # Invalid: missing time
  begin
    Sashite::Pcn::Game::Sides::Player.new(
      periods: [{ moves: 40, inc: 0 }]
    )
    raise "Period without time should be rejected"
  rescue ArgumentError => e
    raise "Error should mention time" unless e.message.include?("time")
  end

  # Invalid: negative time
  begin
    Sashite::Pcn::Game::Sides::Player.new(
      periods: [{ time: -60 }]
    )
    raise "Negative time should be rejected"
  rescue ArgumentError => e
    raise "Error should mention time" unless e.message.include?("time")
  end

  # Invalid: moves = 0
  begin
    Sashite::Pcn::Game::Sides::Player.new(
      periods: [{ time: 300, moves: 0 }]
    )
    raise "moves=0 should be rejected"
  rescue ArgumentError => e
    raise "Error should mention moves" unless e.message.include?("moves")
  end

  # Invalid: negative increment
  begin
    Sashite::Pcn::Game::Sides::Player.new(
      periods: [{ time: 300, inc: -5 }]
    )
    raise "Negative increment should be rejected"
  rescue ArgumentError => e
    raise "Error should mention inc" unless e.message.include?("inc")
  end
end

run_test("Player handles multiple periods (classical)") do
  player = Sashite::Pcn::Game::Sides::Player.new(
    periods: [
      { time: 5400, moves: 40, inc: 0 },
      { time: 1800, moves: 20, inc: 0 },
      { time: 900, moves: nil, inc: 30 }
    ]
  )

  raise "Should have 3 periods" unless player.periods.length == 3
  raise "Total budget should be 8100" unless player.initial_time_budget == 8100
end

run_test("Player handles byoyomi time control") do
  player = Sashite::Pcn::Game::Sides::Player.new(
    periods: [
      { time: 3600, moves: nil, inc: 0 },  # Main time
      { time: 60, moves: 1, inc: 0 },      # Byoyomi
      { time: 60, moves: 1, inc: 0 },
      { time: 60, moves: 1, inc: 0 },
      { time: 60, moves: 1, inc: 0 },
      { time: 60, moves: 1, inc: 0 }
    ]
  )

  raise "Should have 6 periods" unless player.periods.length == 6
  raise "Total budget should be 3900" unless player.initial_time_budget == 3900
end

run_test("Player handles empty periods array (unlimited)") do
  player = Sashite::Pcn::Game::Sides::Player.new(periods: [])

  raise "Should not have time control defined" if player.has_time_control?
  raise "Should have unlimited time" unless player.unlimited_time?
  raise "Budget should be nil" unless player.initial_time_budget == nil
end

run_test("Player equality comparison") do
  player1 = Sashite::Pcn::Game::Sides::Player.new(name: "Alice", elo: 2100)
  player2 = Sashite::Pcn::Game::Sides::Player.new(name: "Alice", elo: 2100)
  player3 = Sashite::Pcn::Game::Sides::Player.new(name: "Alice", elo: 2000)

  raise "Equal players should be equal" unless player1 == player2
  raise "Different players should not be equal" if player1 == player3
end

run_test("Player to_h omits nil fields") do
  player = Sashite::Pcn::Game::Sides::Player.new(name: "Alice")
  hash = player.to_h

  raise "Should have name" unless hash[:name] == "Alice"
  raise "Should not have elo" if hash.key?(:elo)
  raise "Should not have style" if hash.key?(:style)
  raise "Should not have periods" if hash.key?(:periods)
end

run_test("Player is immutable") do
  player = Sashite::Pcn::Game::Sides::Player.new(name: "Alice")

  raise "Player should be frozen" unless player.frozen?
end

# ============================================================================
# SIDES TESTS
# ============================================================================

puts "\nSIDES TESTS:"

run_test("Sides accepts no arguments (empty sides)") do
  sides = Sashite::Pcn::Game::Sides.new

  raise "Empty sides should be valid" unless sides.is_a?(Sashite::Pcn::Game::Sides)
  raise "Empty sides should have empty hash" unless sides.to_h == {}
  raise "Empty sides should be empty" unless sides.empty?
  raise "Empty sides should not be complete" if sides.complete?
end

run_test("Sides accepts both players") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice", elo: 2100 },
    second: { name: "Bob", elo: 2050 }
  )

  raise "First player should be set" unless sides.first.name == "Alice"
  raise "Second player should be set" unless sides.second.name == "Bob"
  raise "Sides should not be empty" if sides.empty?
  raise "Sides should be complete" unless sides.complete?
end

run_test("Sides indexed access") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice" },
    second: { name: "Bob" }
  )

  raise "sides[0] should return first player" unless sides[0].name == "Alice"
  raise "sides[1] should return second player" unless sides[1].name == "Bob"
  raise "sides[2] should return nil" unless sides[2].nil?
  raise "sides[-1] should return nil" unless sides[-1].nil?
end

run_test("Sides player method") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice" },
    second: { name: "Bob" }
  )

  raise "player(:first) should work" unless sides.player(:first).name == "Alice"
  raise "player('second') should work" unless sides.player("second").name == "Bob"
  raise "player(:invalid) should return nil" unless sides.player(:invalid).nil?
end

run_test("Sides has_player? method") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice" }
  )

  raise "has_player?(:first) should be true" unless sides.has_player?(:first)
  raise "has_player?(:second) should be false" if sides.has_player?(:second)
end

run_test("Sides batch accessors") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice", elo: 2100, style: "CHESS" },
    second: { name: "Bob", elo: 2050, style: "chess" }
  )

  raise "names should return both names" unless sides.names == ["Alice", "Bob"]
  raise "elos should return both elos" unless sides.elos == [2100, 2050]
  raise "styles should return both styles" unless sides.styles == ["CHESS", "chess"]
end

run_test("Sides batch accessors with missing data") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice" },
    second: { elo: 2050 }
  )

  raise "names with missing should include nil" unless sides.names == ["Alice", nil]
  raise "elos with missing should include nil" unless sides.elos == [nil, 2050]
  raise "styles with no data should be [nil, nil]" unless sides.styles == [nil, nil]
end

run_test("Sides time control analysis") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { periods: [{ time: 300, moves: nil, inc: 3 }] },
    second: { periods: [{ time: 300, moves: nil, inc: 3 }] }
  )

  raise "Should have symmetric time control" unless sides.symmetric_time_control?
  raise "Both should have time control" unless sides.both_have_time_control?
  raise "Should not be unlimited" if sides.unlimited_game?
  raise "Should not be mixed" if sides.mixed_time_control?
end

run_test("Sides mixed time control") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { periods: [{ time: 300, moves: nil, inc: 3 }] },
    second: { periods: [] }
  )

  raise "Should not have symmetric time control" if sides.symmetric_time_control?
  raise "Should be mixed time control" unless sides.mixed_time_control?
end

run_test("Sides unlimited game") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { periods: [] },
    second: { periods: nil }
  )

  raise "Should be unlimited game" unless sides.unlimited_game?
  raise "Should not have mixed time control" if sides.mixed_time_control?
end

run_test("Sides time budgets") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { periods: [{ time: 300, moves: nil, inc: 3 }] },
    second: { periods: [{ time: 600, moves: nil, inc: 0 }] }
  )

  raise "Time budgets should be [300, 600]" unless sides.time_budgets == [300, 600]
end

run_test("Sides each iteration") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice" },
    second: { name: "Bob" }
  )

  names = []
  sides.each { |player| names << player.name }

  raise "Should iterate over both players" unless names == ["Alice", "Bob"]
end

run_test("Sides map") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice", elo: 2100 },
    second: { name: "Bob", elo: 2050 }
  )

  names = sides.map(&:name)
  elos = sides.map(&:elo)

  raise "map should work for names" unless names == ["Alice", "Bob"]
  raise "map should work for elos" unless elos == [2100, 2050]
end

run_test("Sides to_a") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice" },
    second: { name: "Bob" }
  )

  array = sides.to_a
  raise "to_a should return 2 players" unless array.length == 2
  raise "First element should be first player" unless array[0].name == "Alice"
  raise "Second element should be second player" unless array[1].name == "Bob"
end

run_test("Sides equality") do
  sides1 = Sashite::Pcn::Game::Sides.new(first: { name: "Alice" })
  sides2 = Sashite::Pcn::Game::Sides.new(first: { name: "Alice" })
  sides3 = Sashite::Pcn::Game::Sides.new(first: { name: "Bob" })

  raise "Equal sides should be equal" unless sides1 == sides2
  raise "Different sides should not be equal" if sides1 == sides3
end

run_test("Sides to_h omits empty players") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Alice" }
  )

  hash = sides.to_h
  raise "Should have first player" unless hash[:first]
  raise "Should not have second player" if hash.key?(:second)
end

run_test("Sides is immutable") do
  sides = Sashite::Pcn::Game::Sides.new
  raise "Sides should be frozen" unless sides.frozen?
end

# ============================================================================
# DRAW_OFFERED_BY TESTS
# ============================================================================

puts "\nDRAW_OFFERED_BY TESTS:"

run_test("Game accepts draw_offered_by as nil") do
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    draw_offered_by: nil
  )

  raise "draw_offered_by should be nil" unless game.draw_offered_by.nil?
  raise "draw_offered? should return false" if game.draw_offered?
end

run_test("Game accepts draw_offered_by as 'first'") do
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 8.0]],
    draw_offered_by: "first"
  )

  raise "draw_offered_by should be 'first'" unless game.draw_offered_by == "first"
  raise "draw_offered? should return true" unless game.draw_offered?
end

run_test("Game accepts draw_offered_by as 'second'") do
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 8.0], ["e7-e5", 12.0]],
    draw_offered_by: "second"
  )

  raise "draw_offered_by should be 'second'" unless game.draw_offered_by == "second"
  raise "draw_offered? should return true" unless game.draw_offered?
end

run_test("Game rejects invalid draw_offered_by values") do
  # Invalid string
  begin
    Sashite::Pcn::Game.new(
      setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
      draw_offered_by: "invalid"
    )
    raise "Invalid draw_offered_by should be rejected"
  rescue ArgumentError => e
    raise "Error should mention draw_offered_by" unless e.message.include?("draw_offered_by")
  end

  # Integer
  begin
    Sashite::Pcn::Game.new(
      setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
      draw_offered_by: 1
    )
    raise "Integer draw_offered_by should be rejected"
  rescue ArgumentError => e
    raise "Error should mention draw_offered_by" unless e.message.include?("draw_offered_by")
  end

  # Empty string
  begin
    Sashite::Pcn::Game.new(
      setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
      draw_offered_by: ""
    )
    raise "Empty string draw_offered_by should be rejected"
  rescue ArgumentError => e
    raise "Error should mention draw_offered_by" unless e.message.include?("draw_offered_by")
  end
end

run_test("Game defaults draw_offered_by to nil when not provided") do
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
  )

  raise "draw_offered_by should default to nil" unless game.draw_offered_by.nil?
  raise "draw_offered? should return false by default" if game.draw_offered?
end

run_test("Game with_draw_offered_by creates new game with updated offer") do
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 5.0]]
  )

  # Add draw offer
  game_with_offer = game.with_draw_offered_by("first")
  raise "Original game should not change" unless game.draw_offered_by.nil?
  raise "New game should have draw offer" unless game_with_offer.draw_offered_by == "first"
  raise "Other fields should be preserved" unless game_with_offer.moves == game.moves

  # Change draw offer
  game_other_offer = game_with_offer.with_draw_offered_by("second")
  raise "New game should have different offer" unless game_other_offer.draw_offered_by == "second"

  # Withdraw draw offer
  game_no_offer = game_with_offer.with_draw_offered_by(nil)
  raise "New game should have no offer" unless game_no_offer.draw_offered_by.nil?
  raise "draw_offered? should return false" if game_no_offer.draw_offered?
end

run_test("Game with_draw_offered_by validates value") do
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
  )

  begin
    game.with_draw_offered_by("invalid")
    raise "Invalid draw_offered_by should be rejected"
  rescue ArgumentError => e
    raise "Error should mention draw_offered_by" unless e.message.include?("draw_offered_by")
  end
end

run_test("Game to_h includes draw_offered_by when present") do
  # With draw offer
  game_with = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 5.0]],
    draw_offered_by: "first"
  )
  hash_with = game_with.to_h
  raise "to_h should include draw_offered_by" unless hash_with["draw_offered_by"] == "first"

  # Without draw offer
  game_without = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
  )
  hash_without = game_without.to_h
  raise "to_h should not include draw_offered_by when nil" if hash_without.key?("draw_offered_by")
end

run_test("Game equality considers draw_offered_by") do
  game1 = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 5.0]],
    draw_offered_by: "first"
  )

  game2 = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 5.0]],
    draw_offered_by: "first"
  )

  game3 = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 5.0]],
    draw_offered_by: "second"
  )

  game4 = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 5.0]]
  )

  raise "Games with same draw_offered_by should be equal" unless game1 == game2
  raise "Games with different draw_offered_by should not be equal" if game1 == game3
  raise "Game with draw offer should not equal game without" if game1 == game4
end

run_test("Game inspect includes draw_offered_by when present") do
  game_with = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    draw_offered_by: "first"
  )
  inspect_str = game_with.inspect

  raise "inspect should include draw_offered_by" unless inspect_str.include?("draw_offered_by")
  raise "inspect should show value" unless inspect_str.include?('"first"')

  game_without = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
  )
  inspect_str_without = game_without.inspect

  raise "inspect should not include draw_offered_by when nil" if inspect_str_without.include?("draw_offered_by")
end

# ============================================================================
# GAME TESTS
# ============================================================================

puts "\nGAME TESTS:"

run_test("Game requires setup") do
  begin
    Sashite::Pcn::Game.new(moves: [])
    raise "Game without setup should be rejected"
  rescue ArgumentError => e
    raise "Error should mention setup" unless e.message.include?("setup")
  end
end

run_test("Game accepts minimal valid setup") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / U/u")

  raise "Game should be created" unless game.is_a?(Sashite::Pcn::Game)
  raise "Setup should be stored" unless game.setup.to_s == "8/8/8/8/8/8/8/8 / U/u"
  raise "Moves should default to empty" unless game.moves == []
  raise "Status should default to nil" unless game.status.nil?
  raise "Meta should be empty" unless game.meta.empty?
  raise "Sides should be empty" unless game.sides.empty?
end

run_test("Game validates moves format [PAN, seconds]") do
  # Valid moves
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [
      ["e2-e4", 2.5],
      ["e7-e5", 3.0]
    ]
  )

  raise "Valid moves should be accepted" unless game.moves.length == 2
  raise "First move should be correct" unless game.moves[0] == ["e2-e4", 2.5]
  raise "Second move should be correct" unless game.moves[1] == ["e7-e5", 3.0]
end

run_test("Game rejects invalid move formats") do
  # Not an array
  begin
    Sashite::Pcn::Game.new(
      setup: "8/8/8/8/8/8/8/8 / U/u",
      moves: ["e2-e4", 2.5]
    )
    raise "Non-array moves should be rejected"
  rescue ArgumentError => e
    raise "Error should mention moves" unless e.message.include?("move")
  end

  # Move not a tuple
  begin
    Sashite::Pcn::Game.new(
      setup: "8/8/8/8/8/8/8/8 / U/u",
      moves: ["e2-e4"]
    )
    raise "Non-tuple move should be rejected"
  rescue ArgumentError => e
    raise "Error should mention move format" unless e.message.include?("move")
  end

  # Wrong tuple length
  begin
    Sashite::Pcn::Game.new(
      setup: "8/8/8/8/8/8/8/8 / U/u",
      moves: [["e2-e4", 2.5, "extra"]]
    )
    raise "3-element tuple should be rejected"
  rescue ArgumentError => e
    raise "Error should mention tuple" unless e.message.include?("tuple")
  end

  # Invalid PAN
  begin
    Sashite::Pcn::Game.new(
      setup: "8/8/8/8/8/8/8/8 / U/u",
      moves: [["invalid", 2.5]]
    )
    raise "Invalid PAN should be rejected"
  rescue ArgumentError => e
    raise "Error should mention PAN" unless e.message.include?("PAN")
  end

  # Negative seconds
  begin
    Sashite::Pcn::Game.new(
      setup: "8/8/8/8/8/8/8/8 / U/u",
      moves: [["e2-e4", -2.5]]
    )
    raise "Negative seconds should be rejected"
  rescue ArgumentError => e
    raise "Error should mention seconds" unless e.message.include?("seconds")
  end
end

run_test("Game accepts integer seconds (converts to float)") do
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 2]]
  )

  raise "Integer seconds should be converted to float" unless game.moves[0][1] == 2.0
  raise "Should be a Float" unless game.moves[0][1].is_a?(Float)
end

run_test("Game move operations") do
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [
      ["e2-e4", 2.5],
      ["e7-e5", 3.0],
      ["g1-f3", 1.8]
    ]
  )

  raise "move_count should be 3" unless game.move_count == 3
  raise "move_at(0) should work" unless game.move_at(0) == ["e2-e4", 2.5]
  raise "move_at(2) should work" unless game.move_at(2) == ["g1-f3", 1.8]
  raise "move_at(99) should return nil" unless game.move_at(99).nil?

  raise "pan_at(0) should return PAN" unless game.pan_at(0) == "e2-e4"
  raise "seconds_at(0) should return seconds" unless game.seconds_at(0) == 2.5

  raise "first_player_time should sum even indices" unless game.first_player_time == 4.3
  raise "second_player_time should sum odd indices" unless game.second_player_time == 3.0
end

run_test("Game player shortcuts") do
  game = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / U/u",
    sides: {
      first: { name: "Alice", elo: 2100 },
      second: { name: "Bob", elo: 2050 }
    }
  )

  raise "first_player should work" unless game.first_player.is_a?(Sashite::Pcn::Game::Sides::Player)
  raise "first_player name should be Alice" unless game.first_player.name == "Alice"
  raise "second_player should work" unless game.second_player.is_a?(Sashite::Pcn::Game::Sides::Player)
  raise "second_player name should be Bob" unless game.second_player.name == "Bob"
end

run_test("Game metadata shortcuts") do
  game = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / U/u",
    meta: {
      event: "Tournament",
      location: "Paris",
      round: 5,
      started_at: "2025-01-27T14:00:00Z"
    }
  )

  raise "event shortcut should work" unless game.event == "Tournament"
  raise "location shortcut should work" unless game.location == "Paris"
  raise "round shortcut should work" unless game.round == 5
  raise "started_at shortcut should work" unless game.started_at == "2025-01-27T14:00:00Z"
end

run_test("Game.add_move returns new instance") do
  game1 = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 2.5]]
  )

  game2 = game1.add_move(["e7-e5", 3.0])

  raise "add_move should return new instance" unless game2.object_id != game1.object_id
  raise "Original game should be unchanged" unless game1.move_count == 1
  raise "New game should have added move" unless game2.move_count == 2
  raise "New game should have correct move" unless game2.move_at(1) == ["e7-e5", 3.0]
end

run_test("Game.add_move validates move") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / U/u")

  begin
    game.add_move(["invalid", 2.5])
    raise "Invalid PAN in add_move should be rejected"
  rescue ArgumentError => e
    raise "Error should mention PAN" unless e.message.include?("PAN")
  end

  begin
    game.add_move(["e2-e4", -1])
    raise "Negative seconds in add_move should be rejected"
  rescue ArgumentError => e
    raise "Error should mention seconds" unless e.message.include?("seconds")
  end
end

run_test("Game.with_status returns new instance") do
  game1 = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")
  game2 = game1.with_status("checkmate")

  raise "with_status should return new instance" unless game2.object_id != game1.object_id
  raise "Original game should be unchanged" unless game1.status.nil?
  raise "New game should have status" unless game2.status.to_s == "checkmate"
end

run_test("Game.with_meta returns new instance") do
  game1 = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    meta: { event: "Tournament" }
  )
  game2 = game1.with_meta(round: 5, location: "Paris")

  raise "with_meta should return new instance" unless game2.object_id != game1.object_id
  raise "Original game should be unchanged" unless game1.round.nil?
  raise "New game should merge metadata" unless game2.event == "Tournament"
  raise "New game should have new fields" unless game2.round == 5
  raise "New game should have new fields" unless game2.location == "Paris"
end

run_test("Game.with_moves returns new instance") do
  game1 = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 2.5]]
  )
  game2 = game1.with_moves([["d2-d4", 1.0], ["d7-d5", 1.5]])

  raise "with_moves should return new instance" unless game2.object_id != game1.object_id
  raise "Original game should be unchanged" unless game1.move_count == 1
  raise "New game should have replaced moves" unless game2.move_count == 2
  raise "New game should have different moves" unless game2.pan_at(0) == "d2-d4"
end

run_test("Game predicates") do
  game_progress = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    status: "in_progress"
  )

  game_finished = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    status: "checkmate"
  )

  game_nil = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "In progress should return true" unless game_progress.in_progress? == true
  raise "In progress finished should be false" unless game_progress.finished? == false

  raise "Checkmate in_progress should be false" unless game_finished.in_progress? == false
  raise "Checkmate finished should be true" unless game_finished.finished? == true

  raise "No status in_progress should be nil" unless game_nil.in_progress?.nil?
  raise "No status finished should be nil" unless game_nil.finished?.nil?
end

run_test("Game.to_h serialization") do
  game = Sashite::Pcn::Game.new(
    meta: { event: "Tournament" },
    sides: { first: { name: "Player 1" } },
    setup: "8/8/8/8/8/8/8/8 / C/c",
    moves: [["e2-e4", 2.5]],
    status: "in_progress"
  )

  hash = game.to_h

  raise "to_h should return hash" unless hash.is_a?(Hash)
  raise "Hash should have setup" unless hash["setup"] == "8/8/8/8/8/8/8/8 / C/c"
  raise "Hash should have moves" unless hash["moves"] == [["e2-e4", 2.5]]
  raise "Hash should have status" unless hash["status"] == "in_progress"
  raise "Hash should have meta" unless hash["meta"][:event] == "Tournament"
  raise "Hash should have sides" unless hash["sides"][:first][:name] == "Player 1"
end

run_test("Game.to_h always includes moves") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")
  hash = game.to_h

  raise "to_h should always include moves key" unless hash.key?("moves")
  raise "Empty moves should be empty array" unless hash["moves"] == []
end

run_test("Game.to_h omits empty optional fields") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")
  hash = game.to_h

  raise "to_h should omit empty meta" if hash.key?("meta")
  raise "to_h should omit empty sides" if hash.key?("sides")
  raise "to_h should omit nil status" if hash.key?("status")
end

run_test("From hash to JSON") do
  require "json"

  game = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    moves: [["e2-e4", 2.5]]
  )

  require "json"
  json = JSON.generate(game.to_h)
  parsed = JSON.parse(json)

  raise "JSON should parse back" unless parsed["setup"] == "8/8/8/8/8/8/8/8 / C/c"
  raise "JSON should have moves" unless parsed["moves"] == [["e2-e4", 2.5]]
end

run_test("Game is immutable") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "Game should be frozen" unless game.frozen?
  raise "Moves should be frozen" unless game.moves.frozen?
end

# ============================================================================
# PARSING TESTS
# ============================================================================

puts "\nPARSING TESTS:"

run_test("Parse minimal valid PCN") do
  game = Sashite::Pcn.parse("setup" => "8/8/8/8/8/8/8/8 / U/u")

  raise "Should parse minimal PCN" unless game.is_a?(Sashite::Pcn::Game)
  raise "Setup should be present" unless game.setup.to_s == "8/8/8/8/8/8/8/8 / U/u"
  raise "Moves should default to empty" unless game.moves == []
  raise "Meta should be empty" unless game.meta.empty?
  raise "Sides should be empty" unless game.sides.empty?
end

run_test("Parse complete PCN document") do
  game = Sashite::Pcn.parse(
    "meta" => {
      "event" => "World Championship",
      "round" => 5,
      "started_at" => "2025-01-27T14:00:00Z"
    },
    "sides" => {
      "first" => {
        "name" => "Magnus Carlsen",
        "elo" => 2830,
        "style" => "CHESS",
        "periods" => [
          { "time" => 300, "moves" => nil, "inc" => 3 }
        ]
      },
      "second" => {
        "name" => "Fabiano Caruana",
        "elo" => 2820,
        "style" => "chess",
        "periods" => [
          { "time" => 300, "moves" => nil, "inc" => 3 }
        ]
      }
    },
    "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    "moves" => [["e2-e4", 2.5], ["e7-e5", 3.0]],
    "status" => "in_progress"
  )

  raise "Should parse complete PCN" unless game.event == "World Championship"
  raise "Should have players" unless game.first_player.name == "Magnus Carlsen"
  raise "Should have moves" unless game.move_count == 2
  raise "Should have status" unless game.status.to_s == "in_progress"
  raise "Should have time control" unless game.first_player.periods.first[:time] == 300
end

run_test("Parse rejects invalid PCN") do
  # Missing setup
  begin
    Sashite::Pcn.parse("moves" => [])
    raise "Should reject PCN without setup"
  rescue ArgumentError => e
    raise "Error should mention setup" unless e.message.include?("setup")
  end

  # Invalid move format
  begin
    Sashite::Pcn.parse(
      "setup" => "8/8/8/8/8/8/8/8 / U/u",
      "moves" => ["e2-e4"]  # Missing seconds
    )
    raise "Should reject invalid move format"
  rescue ArgumentError => e
    raise "Error should mention move" unless e.message.include?("move")
  end
end

# ============================================================================
# VALIDATION TESTS
# ============================================================================

puts "\nVALIDATION TESTS:"

run_test("Valid? accepts valid PCN") do
  valid = Sashite::Pcn.valid?(
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => [["e2-e4", 2.5]]
  )

  raise "Valid PCN should be valid" unless valid == true
end

run_test("Valid? rejects invalid PCN") do
  # Missing setup
  raise "PCN without setup should be invalid" if Sashite::Pcn.valid?("moves" => [])

  # Wrong types
  raise "PCN with wrong types should be invalid" if Sashite::Pcn.valid?(
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => "invalid"
  )

  # Invalid move format
  raise "PCN with invalid moves should be invalid" if Sashite::Pcn.valid?(
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => [["e2-e4"]]  # Missing seconds
  )
end

# ============================================================================
# EDGE CASES
# ============================================================================

puts "\nEDGE CASES:"

run_test("Handle zero seconds in moves") do
  game = Sashite::Pcn::Game.new(
    setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    moves: [["e2-e4", 0.0], ["e7-e5", 0]]
  )

  raise "Zero seconds should be valid" unless game.moves[0][1] == 0.0
  raise "Zero integer should convert to float" unless game.moves[1][1] == 0.0
end

run_test("Handle very long PAN notation") do
  # Complex PAN with multiple captures/promotions
  complex_pan = "a7+b8=Q"
  game = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / U/u",
    moves: [[complex_pan, 5.0]]
  )

  raise "Complex PAN should be accepted" unless game.pan_at(0) == complex_pan
end

run_test("Handle special PAN operators") do
  # Test all PAN operators
  moves = [
    ["e2-e4", 1.0],      # Basic move
    ["d1+f3", 2.0],      # Capture
    ["e1~g1", 3.0],      # Special (castling)
    ["e7-e8=Q", 4.0],    # Promotion
    ["P*e4", 5.0],       # Drop
    ["+e5", 6.0],        # Static capture
    ["...", 7.0]         # Pass
  ]

  game = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / U/u",
    moves: moves
  )

  raise "All PAN operators should work" unless game.moves.length == 7
end

run_test("Handle empty string values where allowed") do
  # Empty name is valid
  player = Sashite::Pcn::Game::Sides::Player.new(name: "")
  raise "Empty string name should be valid" unless player.name == ""
end

run_test("Handle maximum values") do
  # Very large Elo
  player = Sashite::Pcn::Game::Sides::Player.new(elo: 999999)
  raise "Large Elo should be accepted" unless player.elo == 999999

  # Very large round
  meta = Sashite::Pcn::Game::Meta.new(round: 10000)
  raise "Large round should be accepted" unless meta[:round] == 10000

  # Very large time
  player2 = Sashite::Pcn::Game::Sides::Player.new(
    periods: [{ time: 86400 }]  # 24 hours
  )
  raise "Large time should be accepted" unless player2.initial_time_budget == 86400
end

run_test("Handle deeply nested custom metadata") do
  meta = Sashite::Pcn::Game::Meta.new(
    event: "Tournament",
    custom: {
      level1: {
        level2: {
          level3: {
            value: "deep"
          }
        }
      }
    }
  )

  raise "Deeply nested metadata should work" unless meta[:custom][:level1][:level2][:level3][:value] == "deep"
end

run_test("Round-trip parse and serialize") do
  original = {
    "meta" => { "event" => "Test" },
    "sides" => {
      "first" => { "name" => "Alice", "periods" => [{ "time" => 300, "moves" => nil, "inc" => 3 }] }
    },
    "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    "moves" => [["e2-e4", 2.5]],
    "status" => "in_progress"
  }

  game = Sashite::Pcn.parse(original)
  serialized = game.to_h

  # Note: internal representation uses symbols for keys
  raise "Setup should round-trip" unless serialized["setup"] == original["setup"]
  raise "Moves should round-trip" unless serialized["moves"] == original["moves"]
  raise "Status should round-trip" unless serialized["status"] == original["status"]
  raise "Meta event should round-trip" unless serialized["meta"][:event] == original["meta"]["event"]
end

run_test("Round-trip with winner field") do
  original = {
    "setup" => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
    "moves" => [["e2-e4", 2.5]],
    "status" => "resignation",
    "winner" => "first"
  }

  game = Sashite::Pcn.parse(original)
  serialized = game.to_h

  raise "Winner should round-trip" unless serialized["winner"] == original["winner"]
  raise "Status should round-trip" unless serialized["status"] == original["status"]
end

puts
puts "All PCN tests passed!"
puts
