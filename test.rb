#!/usr/bin/env ruby
# frozen_string_literal: true

require "simplecov"

SimpleCov.command_name "Unit Tests"
SimpleCov.start

# Tests for Sashite::Pcn (Portable Chess Notation)
#
# Tests the PCN implementation for Ruby, covering game records,
# metadata, player information, and specification compliance
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
  puts "✓ Success"
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

run_test("Meta accepts no arguments (empty metadata)") do
  meta = Sashite::Pcn::Game::Meta.new

  raise "Empty meta should be valid" unless meta.is_a?(Sashite::Pcn::Game::Meta)
  raise "Empty meta to_h should return empty hash" unless meta.to_h == {}
  raise "Empty meta should be empty" unless meta.empty?
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
end

run_test("Meta validates started_on ISO 8601 date format") do
  # Valid format
  valid_meta = Sashite::Pcn::Game::Meta.new(started_on: "2024-11-20")
  raise "Valid ISO date should be accepted" unless valid_meta[:started_on] == "2024-11-20"

  # Invalid formats
  invalid_dates = ["15/01/2025", "2025-1-15", "2025/01/15", "Jan 15, 2025"]

  invalid_dates.each do |date|
    begin
      Sashite::Pcn::Game::Meta.new(started_on: date)
      raise "Invalid date format '#{date}' should be rejected"
    rescue ArgumentError => e
      raise "Error should mention started_on" unless e.message.include?("started_on")
    end
  end
end

run_test("Meta validates finished_at ISO 8601 datetime format with Z") do
  # Valid format
  valid_meta = Sashite::Pcn::Game::Meta.new(finished_at: "2024-11-20T18:45:00Z")
  raise "Valid ISO datetime should be accepted" unless valid_meta[:finished_at] == "2024-11-20T18:45:00Z"

  # Invalid: missing Z
  begin
    Sashite::Pcn::Game::Meta.new(finished_at: "2024-11-20T18:45:00")
    raise "Datetime without Z should be rejected"
  rescue ArgumentError => e
    raise "Error should mention finished_at" unless e.message.include?("finished_at")
  end

  # Invalid: wrong format
  invalid_times = ["2024-11-20 18:45:00Z", "2024-11-20T18:45Z"]

  invalid_times.each do |time|
    begin
      Sashite::Pcn::Game::Meta.new(finished_at: time)
      raise "Invalid datetime format '#{time}' should be rejected"
    rescue ArgumentError => e
      raise "Error should mention finished_at" unless e.message.include?("finished_at")
    end
  end
end

run_test("Meta validates href as absolute URL") do
  # Valid URLs
  valid_urls = ["https://example.com/game/123", "http://chess.com/games/456"]

  valid_urls.each do |url|
    meta = Sashite::Pcn::Game::Meta.new(href: url)
    raise "Valid URL '#{url}' should be accepted" unless meta[:href] == url
  end

  # Invalid: relative URL
  begin
    Sashite::Pcn::Game::Meta.new(href: "/game/123")
    raise "Relative URL should be rejected"
  rescue ArgumentError => e
    raise "Error should mention href" unless e.message.include?("href")
  end

  # Invalid: no scheme
  begin
    Sashite::Pcn::Game::Meta.new(href: "example.com/game")
    raise "URL without scheme should be rejected"
  rescue ArgumentError => e
    raise "Error should mention href" unless e.message.include?("href")
  end
end

run_test("Meta accepts custom fields without validation") do
  meta = Sashite::Pcn::Game::Meta.new(
    event: "Tournament",
    platform: "lichess.org",
    time_control: "3+2",
    rated: true,
    custom_number: 42,
    tags: ["tactical", "endgame"]
  )

  raise "Custom fields should be stored" unless meta[:platform] == "lichess.org"
  raise "Custom fields should be stored" unless meta[:time_control] == "3+2"
  raise "Custom fields should be stored" unless meta[:rated] == true
  raise "Custom fields should be stored" unless meta[:custom_number] == 42
  raise "Custom fields should be stored" unless meta[:tags] == ["tactical", "endgame"]
end

run_test("Meta is immutable") do
  meta = Sashite::Pcn::Game::Meta.new(event: "Tournament")

  raise "Meta should be frozen" unless meta.frozen?
  raise "Meta data should be frozen" unless meta.to_h.frozen?
end

# ============================================================================
# PLAYER TESTS
# ============================================================================

run_test("Player accepts no arguments (empty player)") do
  player = Sashite::Pcn::Game::Sides::Player.new

  raise "Empty player should be valid" unless player.is_a?(Sashite::Pcn::Game::Sides::Player)
  raise "Empty player should have no fields" unless player.to_h == {}
  raise "Empty player should be empty" unless player.empty?
end

run_test("Player validates style with SNN") do
  # Valid styles
  player1 = Sashite::Pcn::Game::Sides::Player.new(style: "CHESS")
  raise "Uppercase style should be accepted" unless player1.style.to_s == "CHESS"
  raise "Player with style should not be empty" if player1.empty?

  player2 = Sashite::Pcn::Game::Sides::Player.new(style: "chess")
  raise "Lowercase style should be accepted" unless player2.style.to_s == "chess"

  # Invalid: mixed case
  begin
    Sashite::Pcn::Game::Sides::Player.new(style: "Chess")
    raise "Mixed case style should be rejected"
  rescue ArgumentError
    # Expected
  end
end

run_test("Player validates name as string") do
  player = Sashite::Pcn::Game::Sides::Player.new(name: "Magnus Carlsen")
  raise "Valid name should be accepted" unless player.name == "Magnus Carlsen"

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
end

run_test("Player with all fields") do
  player = Sashite::Pcn::Game::Sides::Player.new(
    name: "Magnus Carlsen",
    elo: 2830,
    style: "CHESS"
  )

  raise "Player should have all fields" unless player.name == "Magnus Carlsen"
  raise "Player should have all fields" unless player.elo == 2830
  raise "Player should have all fields" unless player.style.to_s == "CHESS"
  raise "Player with all fields should not be empty" if player.empty?
end

run_test("Player is immutable") do
  player = Sashite::Pcn::Game::Sides::Player.new(name: "Player 1")

  raise "Player should be frozen" unless player.frozen?
end

# ============================================================================
# SIDES TESTS
# ============================================================================

run_test("Sides accepts no arguments (empty sides)") do
  sides = Sashite::Pcn::Game::Sides.new

  raise "Empty sides should be valid" unless sides.is_a?(Sashite::Pcn::Game::Sides)
  raise "Empty sides should have empty first player" unless sides.first.empty?
  raise "Empty sides should have empty second player" unless sides.second.empty?
  raise "Empty sides should be empty" unless sides.empty?
  raise "Empty sides to_h should return empty hash" unless sides.to_h == {}
end

run_test("Sides accepts first player only") do
  sides = Sashite::Pcn::Game::Sides.new(first: { name: "Player 1" })

  raise "First player should be present" unless sides.first
  raise "First player should have name" unless sides.first.name == "Player 1"
  raise "Second player should be empty" unless sides.second.empty?
  raise "Sides with one player should not be empty" if sides.empty?
end

run_test("Sides accepts second player only") do
  sides = Sashite::Pcn::Game::Sides.new(second: { name: "Player 2" })

  raise "First player should be empty" unless sides.first.empty?
  raise "Second player should be present" unless sides.second
  raise "Second player should have name" unless sides.second.name == "Player 2"
  raise "Sides with one player should not be empty" if sides.empty?
end

run_test("Sides accepts both players") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Player 1" },
    second: { name: "Player 2" }
  )

  raise "First player should be present" unless sides.first
  raise "Second player should be present" unless sides.second
  raise "First player should have correct name" unless sides.first.name == "Player 1"
  raise "Second player should have correct name" unless sides.second.name == "Player 2"
  raise "Sides with both players should not be empty" if sides.empty?
end

run_test("Sides creates Player objects") do
  sides = Sashite::Pcn::Game::Sides.new(
    first: { name: "Carlsen", elo: 2830 },
    second: { name: "Nakamura", elo: 2794 }
  )

  raise "First should be a Player" unless sides.first.is_a?(Sashite::Pcn::Game::Sides::Player)
  raise "Second should be a Player" unless sides.second.is_a?(Sashite::Pcn::Game::Sides::Player)
  raise "First player data should be correct" unless sides.first.name == "Carlsen"
  raise "Second player data should be correct" unless sides.second.name == "Nakamura"
end

run_test("Sides is immutable") do
  sides = Sashite::Pcn::Game::Sides.new(first: { name: "Player 1" })

  raise "Sides should be frozen" unless sides.frozen?
end

# ============================================================================
# GAME CREATION TESTS
# ============================================================================

run_test("Game requires setup field") do
  # Valid: minimal game
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")
  raise "Minimal game should be valid" unless game.setup

  # Invalid: missing setup
  begin
    Sashite::Pcn::Game.new(moves: [])
    raise "Game without setup should be rejected"
  rescue ArgumentError => e
    raise "Error should mention setup" unless e.message.include?("setup")
  end
end

run_test("Game setup is parsed with FEEN") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "Setup should be parsed" unless game.setup.respond_to?(:to_s)
  raise "Setup should be a FEEN object" unless game.setup.to_s.include?("/")
end

run_test("Game moves default to empty array") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "Moves should default to empty array" unless game.moves == []
  raise "Move count should be 0" unless game.move_count == 0
end

run_test("Game validates moves as array") do
  # Invalid: not an array
  begin
    Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c", moves: "invalid")
    raise "Non-array moves should be rejected"
  rescue ArgumentError => e
    raise "Error should mention moves" unless e.message.include?("moves")
  end
end

run_test("Game parses moves with PMN") do
  game = Sashite::Pcn::Game.new(
    setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
    moves: [["e2", "e4"], ["e7", "e5"]]
  )

  raise "Moves should be parsed" unless game.moves.length == 2
  raise "Move count should be correct" unless game.move_count == 2
  raise "Moves should be PMN objects" unless game.move_at(0).respond_to?(:to_a)
end

run_test("Game parses status with CGSN") do
  game = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    status: "checkmate"
  )

  raise "Status should be parsed" unless game.status
  raise "Status should be a CGSN Status object" unless game.status.to_s == "checkmate"
end

run_test("Game status defaults to nil") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "Status should be nil when not provided" unless game.status.nil?
end

run_test("Game meta defaults to empty") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "Meta should be present" unless game.meta
  raise "Meta should be empty" unless game.meta.empty?
end

run_test("Game sides defaults to empty") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "Sides should be present" unless game.sides
  raise "Sides should be empty" unless game.sides.empty?
end

run_test("Game with complete data") do
  game = Sashite::Pcn::Game.new(
    meta: { event: "World Championship", round: 5 },
    sides: {
      first: { name: "Carlsen", elo: 2830, style: "CHESS" },
      second: { name: "Nakamura", elo: 2794, style: "chess" }
    },
    setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
    moves: [["e2", "e4"], ["c7", "c5"]],
    status: "in_progress"
  )

  raise "Complete game should have all fields" unless game.meta
  raise "Complete game should have all fields" unless game.sides
  raise "Complete game should have all fields" unless game.setup
  raise "Complete game should have all fields" unless game.moves.length == 2
  raise "Complete game should have all fields" unless game.status
end

run_test("Game is immutable") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "Game should be frozen" unless game.frozen?
  raise "Moves array should be frozen" unless game.moves.frozen?
end

run_test("Game has STATUS_IN_PROGRESS constant") do
  raise "STATUS_IN_PROGRESS constant should exist" unless Sashite::Pcn::Game::STATUS_IN_PROGRESS == "in_progress"
end

# ============================================================================
# GAME ACCESSOR TESTS
# ============================================================================

run_test("Game provides player access") do
  game = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    sides: {
      first: { name: "Player 1" },
      second: { name: "Player 2" }
    }
  )

  raise "first_player should return player data" unless game.first_player
  raise "second_player should return player data" unless game.second_player
  raise "first_player should have correct name" unless game.first_player.name == "Player 1"
  raise "second_player should have correct name" unless game.second_player.name == "Player 2"
end

run_test("Game provides metadata shortcuts") do
  game = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    meta: {
      event: "Tournament",
      location: "London",
      round: 3,
      started_on: "2024-11-20",
      finished_at: "2024-11-20T18:45:00Z"
    }
  )

  raise "event shortcut should work" unless game.event == "Tournament"
  raise "location shortcut should work" unless game.location == "London"
  raise "round shortcut should work" unless game.round == 3
  raise "started_on shortcut should work" unless game.started_on == "2024-11-20"
  raise "finished_at shortcut should work" unless game.finished_at == "2024-11-20T18:45:00Z"
end

run_test("Game provides move operations") do
  game = Sashite::Pcn::Game.new(
    setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
    moves: [["e2", "e4"], ["e7", "e5"], ["g1", "f3"]]
  )

  raise "move_count should be correct" unless game.move_count == 3
  raise "move_at should return move" unless game.move_at(0)
  raise "move_at should return nil for out of bounds" unless game.move_at(10).nil?
end

# ============================================================================
# MODULE METHOD TESTS
# ============================================================================

run_test("Pcn.parse creates Game from hash") do
  game = Sashite::Pcn.parse(
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => [["e2", "e4"]]
  )

  raise "parse should return Game instance" unless game.is_a?(Sashite::Pcn::Game)
  raise "Parsed game should have setup" unless game.setup
  raise "Parsed game should have moves" unless game.moves.length == 1
end

run_test("Pcn.valid? validates structure") do
  # Valid: minimal
  raise "Minimal PCN should be valid" unless Sashite::Pcn.valid?("setup" => "8/8/8/8/8/8/8/8 / C/c")

  # Valid: with moves
  raise "PCN with moves should be valid" unless Sashite::Pcn.valid?(
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => []
  )

  # Invalid: missing setup
  raise "PCN without setup should be invalid" if Sashite::Pcn.valid?("moves" => [])

  # Invalid: wrong types
  raise "PCN with wrong types should be invalid" if Sashite::Pcn.valid?(
    "setup" => "8/8/8/8/8/8/8/8 / C/c",
    "moves" => "invalid"
  )
end

# ============================================================================
# TRANSFORMATION TESTS
# ============================================================================

run_test("Game.add_move returns new instance") do
  game1 = Sashite::Pcn::Game.new(
    setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
    moves: [["e2", "e4"]]
  )

  game2 = game1.add_move(["e7", "e5"])

  raise "add_move should return new instance" unless game2.object_id != game1.object_id
  raise "Original game should be unchanged" unless game1.move_count == 1
  raise "New game should have added move" unless game2.move_count == 2
end

run_test("Game.with_status returns new instance") do
  game1 = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")
  game2 = game1.with_status("checkmate")

  raise "with_status should return new instance" unless game2.object_id != game1.object_id
  raise "Original game should be unchanged" unless game1.status.nil?
  raise "New game should have status" unless game2.status.to_s == "checkmate"
end

run_test("Game.with_meta returns new instance") do
  game1 = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")
  game2 = game1.with_meta(event: "Tournament", round: 5)

  raise "with_meta should return new instance" unless game2.object_id != game1.object_id
  raise "Original game should be unchanged" unless game1.event.nil?
  raise "New game should have metadata" unless game2.event == "Tournament"
  raise "New game should have metadata" unless game2.round == 5
end

run_test("Game.with_moves returns new instance") do
  game1 = Sashite::Pcn::Game.new(setup: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c")
  game2 = game1.with_moves([["e2", "e4"], ["e7", "e5"]])

  raise "with_moves should return new instance" unless game2.object_id != game1.object_id
  raise "Original game should be unchanged" unless game1.move_count == 0
  raise "New game should have moves" unless game2.move_count == 2
end

# ============================================================================
# PREDICATE TESTS
# ============================================================================

run_test("Game.in_progress? checks for in_progress status") do
  game1 = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    status: "in_progress"
  )

  game2 = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    status: "checkmate"
  )

  game3 = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "In progress should return true" unless game1.in_progress?
  raise "Checkmate should return false" if game2.in_progress?
  raise "No status should return nil" unless game3.in_progress?.nil?
end

run_test("Game.finished? is opposite of in_progress?") do
  game1 = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    status: "in_progress"
  )

  game2 = Sashite::Pcn::Game.new(
    setup: "8/8/8/8/8/8/8/8 / C/c",
    status: "checkmate"
  )

  game3 = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")

  raise "In progress should not be finished" if game1.finished?
  raise "Checkmate should be finished" unless game2.finished?
  raise "No status should return nil" unless game3.finished?.nil?
end

run_test("Game.finished? works with all terminal statuses") do
  terminal_statuses = %w[
    checkmate stalemate bare_king mare_king insufficient
    resignation agreement illegal_move time_limit move_limit repetition
  ]

  terminal_statuses.each do |status|
    game = Sashite::Pcn::Game.new(
      setup: "8/8/8/8/8/8/8/8 / C/c",
      status: status
    )
    raise "Status '#{status}' should be finished" unless game.finished?
  end
end

# ============================================================================
# SERIALIZATION TESTS
# ============================================================================

run_test("Game.to_h converts to hash") do
  game = Sashite::Pcn::Game.new(
    meta: { event: "Tournament" },
    sides: { first: { name: "Player 1" } },
    setup: "8/8/8/8/8/8/8/8 / C/c",
    moves: [["e2", "e4"]],
    status: "in_progress"
  )

  hash = game.to_h

  raise "to_h should return hash" unless hash.is_a?(Hash)
  raise "Hash should have setup" unless hash["setup"]
  raise "Hash should have moves" unless hash["moves"]
  raise "Hash should have status" unless hash["status"]
  raise "Hash should have meta" unless hash["meta"]
  raise "Hash should have sides" unless hash["sides"]
end

run_test("Game.to_h always includes moves array") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")
  hash = game.to_h

  raise "to_h should always include moves key" unless hash.key?("moves")
  raise "Empty moves should be empty array" unless hash["moves"] == []
end

run_test("Game.to_h omits empty meta and sides") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")
  hash = game.to_h

  raise "to_h should omit empty meta" if hash.key?("meta")
  raise "to_h should omit empty sides" if hash.key?("sides")
end

run_test("Game.to_h omits nil status") do
  game = Sashite::Pcn::Game.new(setup: "8/8/8/8/8/8/8/8 / C/c")
  hash = game.to_h

  raise "to_h should omit nil status" if hash.key?("status")
end

# ============================================================================
# SPECIFICATION EXAMPLES
# ============================================================================

run_test("Minimal valid PCN") do
  # From specification examples
  game = Sashite::Pcn.parse("setup" => "8/8/8/8/8/8/8/8 / U/u")

  raise "Setup should be present" unless game.setup
  raise "Moves should default to empty" unless game.moves == []
  raise "Meta should be empty" unless game.meta.empty?
  raise "Sides should be empty" unless game.sides.empty?
end

run_test("Complete game record") do
  # From specification examples
  game = Sashite::Pcn.parse(
    "meta" => {
      "event" => "World Championship",
      "round" => 5,
      "started_on" => "2025-11-15",
      "finished_at" => "2025-11-15T18:45:00Z"
    },
    "sides" => {
      "first" => { "name" => "Magnus Carlsen", "elo" => 2830, "style" => "CHESS" },
      "second" => { "name" => "Fabiano Caruana", "elo" => 2820, "style" => "chess" }
    },
    "setup" => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c",
    "moves" => [["e2", "e4"], ["e7", "e5"]],
    "status" => "in_progress"
  )

  raise "Complete game should have metadata" unless game.event == "World Championship"
  raise "Complete game should have players" unless game.first_player.name == "Magnus Carlsen"
  raise "Complete game should have moves" unless game.move_count == 2
  raise "Complete game should have status" unless game.status.to_s == "in_progress"
end

run_test("Position without moves (puzzle)") do
  # From specification examples
  game = Sashite::Pcn.parse(
    "meta" => { "name" => "Mate in 2" },
    "setup" => "r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR / C/c"
  )

  raise "Puzzle should have no moves" unless game.moves == []
  raise "Puzzle should have name" unless game.meta[:name] == "Mate in 2"
end

run_test("Empty sides object is valid") do
  # From specification examples
  game = Sashite::Pcn.parse(
    "sides" => {},
    "setup" => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c"
  )

  raise "Empty sides should be valid" unless game.sides.empty?
end

run_test("Only first player with information") do
  # From specification examples
  game = Sashite::Pcn.parse(
    "sides" => {
      "first" => { "name" => "Alice", "elo" => 2100 }
    },
    "setup" => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR / C/c"
  )

  raise "First player should have info" unless game.first_player.name == "Alice"
  raise "Second player should be empty" unless game.second_player.empty?
end

puts
puts "All PCN tests passed!"
puts
