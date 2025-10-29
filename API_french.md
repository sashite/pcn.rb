# PCN Ruby API Reference

Documentation complète de l'API pour le gem Ruby `sashite-pcn` implémentant PCN (Portable Chess Notation) v1.0.0.

## Table des matières

- [Module Sashite::Pcn](#module-sashitepcn)
- [Classe : Game](#classe-game)
  - [Initialisation](#game-initialisation)
  - [Accès aux données principales](#game-accès-aux-données-principales)
  - [Opérations sur les coups](#game-opérations-sur-les-coups)
  - [Accès aux joueurs](#game-accès-aux-joueurs)
  - [Raccourcis métadonnées](#game-raccourcis-métadonnées)
  - [Transformations](#game-transformations)
  - [Prédicats](#game-prédicats)
  - [Sérialisation](#game-sérialisation)
- [Classe : Meta](#classe-meta)
  - [Champs standards](#meta-champs-standards)
  - [Champs personnalisés](#meta-champs-personnalisés)
  - [Méthodes d'accès](#meta-méthodes-daccès)
  - [Itération et collection](#meta-itération-et-collection)
  - [Comparaison et égalité](#meta-comparaison-et-égalité)
- [Classe : Sides](#classe-sides)
  - [Accès aux joueurs](#sides-accès-aux-joueurs)
  - [Accès indexé](#sides-accès-indexé)
  - [Opérations par lot](#sides-opérations-par-lot)
  - [Analyse du contrôle du temps](#sides-analyse-du-contrôle-du-temps)
  - [Prédicats](#sides-prédicats)
  - [Collections et itération](#sides-collections-et-itération)
- [Classe : Player](#classe-player)
  - [Attributs principaux](#player-attributs-principaux)
  - [Contrôle du temps](#player-contrôle-du-temps)
  - [Prédicats](#player-prédicats)
  - [Sérialisation](#player-sérialisation)
- [Validation et erreurs](#validation-et-erreurs)
- [Référence des types](#référence-des-types)

---

## Module Sashite::Pcn

Module de niveau supérieur fournissant les méthodes de parsing et de validation.

### Méthodes

#### `Sashite::Pcn.parse(hash)`

Parse un document PCN à partir d'une structure hash.

```ruby
# Paramètres
# @param hash [Hash] document PCN avec des clés string
# @return [Sashite::Pcn::Game] instance de partie parsée
# @raise [ArgumentError] si la structure est invalide

# Exemple
game = Sashite::Pcn.parse({
                            "setup"  => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
                            "moves"  => [["e2-e4", 2.5], ["e7-e5", 3.1]],
                            "status" => "in_progress"
                          })

# À partir de JSON
require "json"
json_string = File.read("game.pcn.json")
game = Sashite::Pcn.parse(JSON.parse(json_string))
```

#### `Sashite::Pcn.valid?(hash)`

Valide une structure PCN sans la parser.

```ruby
# Paramètres
# @param hash [Hash] document PCN à valider
# @return [Boolean] true si valide, false sinon

# Exemple
valid = Sashite::Pcn.valid?({
                              "setup" => "8/8/8/8/8/8/8/8 / U/u"
                            }) # => true

invalid = Sashite::Pcn.valid?({
                                "moves" => [["e2-e4", 2.5]] # 'setup' requis manquant
                              }) # => false
```

---

## Classe: Game

Classe principale représentant un enregistrement complet de partie PCN. Toutes les instances sont immuables.

### Game Initialisation

#### `Game.new(setup:, moves: [], status: nil, draw_offered_by: nil, meta: {}, sides: {})`

Crée une nouvelle instance de partie avec validation.

```ruby
# Paramètres
# @param setup [String] position FEEN (requis)
# @param moves [Array<Array>] tableau de tuples [PAN, secondes] (optionnel)
# @param status [String, nil] statut CGSN (optionnel)
# @param draw_offered_by [String, nil] proposition de nulle ("first", "second", ou nil) (optionnel)
# @param meta [Hash] métadonnées avec symboles ou strings comme clés (optionnel)
# @param sides [Hash] informations sur les joueurs (optionnel)
# @raise [ArgumentError] si un champ est invalide

# Partie minimale
game = Sashite::Pcn::Game.new(
  setup: "8/8/8/8/8/8/8/8 / U/u"
)

# Partie complète
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

# Partie avec proposition de nulle
game = Sashite::Pcn::Game.new(
  setup:           "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves:           [["e2-e4", 8.0], ["e7-e5", 12.0]],
  status:          "in_progress",
  draw_offered_by: "first" # Le premier joueur a proposé une nulle
)
```

### Game Accès aux données principales

#### `#setup`

Retourne la position initiale.

```ruby
# @return [Sashite::Feen::Position] objet position FEEN

game.setup         # => #<Sashite::Feen::Position ...>
game.setup.to_s    # => "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
```

#### `#moves`

Retourne la séquence de coups.

```ruby
# @return [Array<Array>] tableau gelé de tuples [PAN, secondes]

game.moves # => [["e2-e4", 2.5], ["e7-e5", 3.1]]
```

#### `#status`

Retourne le statut de la partie.

```ruby
# @return [Sashite::Cgsn::Status, nil] objet statut ou nil

game.status          # => #<Sashite::Cgsn::Status ...>
game.status.to_s     # => "checkmate"
game.status.inferable? # => true
```

#### `#draw_offered_by`

Retourne l'indicateur de proposition de nulle.

```ruby
# @return [String, nil] "first", "second", ou nil

game.draw_offered_by # => "first"  # Le premier joueur a proposé une nulle
game.draw_offered_by # => nil      # Aucune proposition de nulle en attente
```

**Sémantique du champ `draw_offered_by` :**

- **`nil`** (défaut) : Aucune proposition de nulle en attente
- **`"first"`** : Le premier joueur a proposé une nulle au second joueur
- **`"second"`** : Le second joueur a proposé une nulle au premier joueur

**Indépendance avec `status` :**

Le champ `draw_offered_by` est complètement indépendant du champ `status`. Il enregistre la communication entre les joueurs (état de proposition), tandis que `status` enregistre l'état observable de la partie (condition terminale).

**Transitions d'état courantes :**

1. **Proposition faite** : `draw_offered_by` passe de `nil` à `"first"` ou `"second"`, `status` reste `"in_progress"`
2. **Proposition acceptée** : `status` passe à `"agreement"`, `draw_offered_by` peut rester défini ou être effacé (choix d'implémentation)
3. **Proposition annulée/retirée** : `draw_offered_by` retourne à `nil`, `status` reste `"in_progress"`

#### `#meta`

Retourne l'objet métadonnées.

```ruby
# @return [Meta] objet métadonnées (jamais nil, peut être vide)

game.meta           # => #<Meta ...>
game.meta[:event]   # => "World Championship"
game.meta.empty?    # => false
```

#### `#sides`

Retourne l'objet sides.

```ruby
# @return [Sides] objet sides (jamais nil, peut être vide)

game.sides          # => #<Sides ...>
game.sides.first    # => #<Player ...>
game.sides.second   # => #<Player ...>
```

### Game Opérations sur les coups

#### `#move_count`

Retourne le nombre de coups.

```ruby
# @return [Integer] nombre de coups dans la partie

game.move_count # => 10
```

#### `#move_at(index)`

Retourne le coup à l'index spécifié.

```ruby
# @param index [Integer] index base 0
# @return [Array, nil] tuple [PAN, secondes] ou nil si hors limites

game.move_at(0)   # => ["e2-e4", 2.5]
game.move_at(1)   # => ["e7-e5", 3.1]
game.move_at(99)  # => nil
```

#### `#pan_at(index)`

Retourne juste la notation PAN à l'index.

```ruby
# @param index [Integer] index base 0
# @return [String, nil] string PAN ou nil

game.pan_at(0)  # => "e2-e4"
game.pan_at(1)  # => "e7-e5"
```

#### `#seconds_at(index)`

Retourne juste les secondes à l'index.

```ruby
# @param index [Integer] index base 0
# @return [Float, nil] secondes ou nil

game.seconds_at(0)  # => 2.5
game.seconds_at(1)  # => 3.1
```

#### `#first_player_time`

Calcule le temps total passé par le premier joueur.

```ruby
# @return [Float] somme des secondes aux indices pairs (0, 2, 4, ...)

game.first_player_time # => 125.7
```

#### `#second_player_time`

Calcule le temps total passé par le second joueur.

```ruby
# @return [Float] somme des secondes aux indices impairs (1, 3, 5, ...)

game.second_player_time # => 132.3
```

#### `#add_move(move)`

Retourne une nouvelle partie avec le coup ajouté (immuable).

```ruby
# @param move [Array] tuple [PAN, secondes]
# @return [Game] nouvelle instance de partie avec le coup ajouté
# @raise [ArgumentError] si le format du coup est invalide

new_game = game.add_move(["g1-f3", 1.8])

# Validation appliquée
game.add_move(["invalid", -5]) # lève ArgumentError
game.add_move("e2-e4") # lève ArgumentError (pas un tableau)
```

### Game Accès aux joueurs

#### `#first_player`

Retourne les données du premier joueur.

```ruby
# @return [Hash, nil] hash du premier joueur ou nil

game.first_player
# => {
#   name: "Magnus Carlsen",
#   elo: 2830,
#   style: "CHESS",
#   periods: [{ time: 300, moves: nil, inc: 3 }]
# }
```

#### `#second_player`

Retourne les données du second joueur.

```ruby
# @return [Hash, nil] hash du second joueur ou nil

game.second_player
# => {
#   name: "Hikaru Nakamura",
#   elo: 2794,
#   style: "chess",
#   periods: [{ time: 300, moves: nil, inc: 3 }]
# }
```

### Game Raccourcis métadonnées

#### `#started_at`

Retourne le timestamp de début de partie.

```ruby
# @return [String, nil] datetime ISO 8601 ou nil

game.started_at # => "2025-01-27T14:00:00Z"
```

#### `#event`

Retourne le nom de l'événement.

```ruby
# @return [String, nil] nom de l'événement ou nil

game.event # => "World Championship"
```

#### `#location`

Retourne le lieu de l'événement.

```ruby
# @return [String, nil] lieu ou nil

game.location # => "Dubai, UAE"
```

#### `#round`

Retourne le numéro de ronde.

```ruby
# @return [Integer, nil] numéro de ronde ou nil

game.round # => 5
```

### Game Transformations

Toutes les transformations retournent de nouvelles instances (pattern immuable).

#### `#with_status(status)`

Retourne une nouvelle partie avec le statut mis à jour.

```ruby
# @param status [String, nil] nouveau statut CGSN
# @return [Game] nouvelle instance de partie

finished = game.with_status("checkmate")
resigned = game.with_status("resignation")
```

#### `#with_draw_offered_by(player)`

Retourne une nouvelle partie avec la proposition de nulle mise à jour.

```ruby
# @param player [String, nil] "first", "second", ou nil
# @return [Game] nouvelle instance de partie

# Proposition de nulle du premier joueur
game_with_offer = game.with_draw_offered_by("first")

# Retrait de la proposition de nulle
game_no_offer = game.with_draw_offered_by(nil)
```

#### `#with_meta(**fields)`

Retourne une nouvelle partie avec les métadonnées fusionnées.

```ruby
# @param fields [Hash] champs de métadonnées à fusionner
# @return [Game] nouvelle instance de partie

updated = game.with_meta(
  event:  "Tournament",
  round:  1,
  custom: "value"
)
```

#### `#with_moves(moves)`

Retourne une nouvelle partie avec une séquence de coups spécifiée.

```ruby
# @param moves [Array<Array>] nouvelle séquence de tuples [PAN, secondes]
# @return [Game] nouvelle instance de partie avec les nouveaux coups
# @raise [ArgumentError] si le format des coups est invalide

updated = game.with_moves([
                            ["e2-e4", 2.0],
                            ["e7-e5", 3.0]
                          ])
```

### Game Prédicats

#### `#in_progress?`

Vérifie si la partie est en cours.

```ruby
# @return [Boolean, nil] true si en cours, false si terminée, nil si indéterminé

game.in_progress? # => true
```

#### `#finished?`

Vérifie si la partie est terminée.

```ruby
# @return [Boolean, nil] true si terminée, false si en cours, nil si indéterminé

game.finished? # => false
```

#### `#draw_offered?`

Vérifie si une proposition de nulle est en attente.

```ruby
# @return [Boolean] true si une proposition est en attente

game.draw_offered?  # => true  (si draw_offered_by est "first" ou "second")
game.draw_offered?  # => false (si draw_offered_by est nil)
```

### Game Sérialisation

#### `#to_h`

Convertit en représentation hash.

```ruby
# @return [Hash] hash avec des clés string prêt pour la sérialisation JSON

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

Compare avec une autre partie.

```ruby
# @param other [Object] objet à comparer
# @return [Boolean] true si égaux

game1 == game2 # => true si tous les attributs correspondent
```

#### `#hash`

Retourne le code de hachage.

```ruby
# @return [Integer] code de hachage

game.hash # => 123456789
```

#### `#inspect`

Retourne une représentation de débogage.

```ruby
# @return [String] string de débogage

game.inspect
# => "#<Game setup=\"...\" moves=[...] status=\"in_progress\">"
```

---

## Classe: Meta

Classe représentant les métadonnées de la partie. Supporte les champs standards validés et les champs personnalisés.

### Meta Champs standards

Champs standards avec validation :

- `name` (String) : Nom de la partie ou de l'ouverture
- `event` (String) : Nom de l'événement
- `location` (String) : Lieu de l'événement
- `round` (Integer >= 1) : Numéro de ronde
- `started_at` (String) : Timestamp ISO 8601
- `href` (String) : URL absolue (http:// ou https://)

### Meta Champs personnalisés

Les champs personnalisés sont acceptés sans validation. Exemples :

- `platform` : Plateforme de jeu
- `opening_eco` : Code ECO d'ouverture
- `rated` : Partie classée ou non
- Tout autre champ personnalisé

### Meta Méthodes d'accès

#### `#[](key)`

Accède à un champ de métadonnées.

```ruby
# @param key [Symbol, String] clé du champ
# @return [Object, nil] valeur du champ ou nil

meta[:event]    # => "World Championship"
meta[:platform] # => "lichess.org"
```

#### `#key?(key)`

Vérifie si un champ existe.

```ruby
# @param key [Symbol, String] clé du champ
# @return [Boolean] true si le champ existe

meta.key?(:event)    # => true
meta.key?(:unknown)  # => false
```

### Meta Itération et collection

#### `#each`

Itère sur tous les champs.

```ruby
# @yield [key, value] passe chaque paire clé-valeur
# @return [Enumerator] si aucun bloc donné

meta.each do |key, value|
  puts "#{key}: #{value}"
end
```

#### `#keys`

Retourne toutes les clés.

```ruby
# @return [Array<Symbol>] tableau des clés

meta.keys # => [:event, :round, :started_at]
```

#### `#values`

Retourne toutes les valeurs.

```ruby
# @return [Array] tableau des valeurs

meta.values # => ["World Championship", 5, "2025-01-27T14:00:00Z"]
```

#### `#to_h`

Convertit en hash (omet les champs nil).

```ruby
# @return [Hash] hash avec des clés symbole

meta.to_h
# => {
#   event: "World Championship",
#   round: 5,
#   started_at: "2025-01-27T14:00:00Z"
# }
```

### Meta Comparaison et égalité

#### `#empty?`

Vérifie si les métadonnées sont vides.

```ruby
# @return [Boolean] true si aucun champ défini

meta.empty? # => false
Meta.new.empty? # => true
```

#### `#==(other)`

Compare avec d'autres métadonnées.

```ruby
# @param other [Object] objet à comparer
# @return [Boolean] true si égaux

meta1 == meta2 # => true si tous les champs correspondent
```

---

## Classe: Sides

Classe représentant les informations des deux joueurs.

### Sides Accès aux joueurs

#### `#first`

Retourne le premier joueur.

```ruby
# @return [Player, nil] objet joueur ou nil

sides.first # => #<Player ...>
```

#### `#second`

Retourne le second joueur.

```ruby
# @return [Player, nil] objet joueur ou nil

sides.second # => #<Player ...>
```

### Sides Accès indexé

#### `#[](index)`

Accède au joueur par index (0 = first, 1 = second).

```ruby
# @param index [Integer] 0 ou 1
# @return [Player, nil] objet joueur ou nil

sides[0] # => premier joueur
sides[1] # => second joueur
```

### Sides Opérations par lot

#### `#names`

Retourne les noms des deux joueurs.

```ruby
# @return [Array<String, nil>] tableau des noms

sides.names # => ["Carlsen", "Nakamura"]
```

#### `#elos`

Retourne les classements Elo des deux joueurs.

```ruby
# @return [Array<Integer, nil>] tableau des Elo

sides.elos # => [2830, 2794]
```

#### `#styles`

Retourne les styles des deux joueurs.

```ruby
# @return [Array<String, nil>] tableau des styles SNN

sides.styles # => ["CHESS", "chess"]
```

### Sides Analyse du contrôle du temps

#### `#symmetric_time_control?`

Vérifie si les deux joueurs ont le même contrôle du temps.

```ruby
# @return [Boolean] true si les périodes sont identiques

sides.symmetric_time_control? # => true
```

#### `#mixed_time_control?`

Vérifie si les joueurs ont des contrôles du temps différents.

```ruby
# @return [Boolean] true si un joueur a des périodes et l'autre non

sides.mixed_time_control? # => false
```

#### `#unlimited_game?`

Vérifie si aucun joueur n'a de contrôle du temps.

```ruby
# @return [Boolean] true si aucune période définie

sides.unlimited_game? # => false
```

### Sides Prédicats

#### `#complete?`

Vérifie si les deux joueurs sont définis.

```ruby
# @return [Boolean] true si first et second sont définis

sides.complete? # => true
```

#### `#empty?`

Vérifie si aucun joueur n'est défini.

```ruby
# @return [Boolean] true si aucun joueur défini

sides.empty? # => false
```

### Sides Collections et itération

#### `#each`

Itère sur les joueurs.

```ruby
# @yield [player] passe chaque joueur
# @return [Enumerator] si aucun bloc donné

sides.each do |player|
  puts player.name
end
```

#### `#to_h`

Convertit en hash.

```ruby
# @return [Hash] hash avec clés first/second

sides.to_h
# => {
#   first: { name: "Carlsen", ... },
#   second: { name: "Nakamura", ... }
# }
```

---

## Classe: Player

Classe représentant un seul joueur avec ses informations et son contrôle du temps.

### Player Attributs principaux

#### `#name`

Retourne le nom du joueur.

```ruby
# @return [String, nil] nom ou nil

player.name # => "Magnus Carlsen"
```

#### `#elo`

Retourne le classement Elo.

```ruby
# @return [Integer, nil] Elo ou nil

player.elo # => 2830
```

#### `#style`

Retourne le style de jeu (notation SNN).

```ruby
# @return [String, nil] style SNN ou nil

player.style # => "CHESS"
```

#### `#periods`

Retourne les périodes de contrôle du temps.

```ruby
# @return [Array<Hash>, nil] tableau de périodes ou nil

player.periods
# => [
#   { time: 5400, moves: 40, inc: 0 },
#   { time: 1800, moves: nil, inc: 30 }
# ]
```

### Player Contrôle du temps

#### `#has_time_control?`

Vérifie si le joueur a un contrôle du temps.

```ruby
# @return [Boolean] true si des périodes sont définies

player.has_time_control? # => true
```

#### `#initial_time_budget`

Calcule le budget temps initial total.

```ruby
# @return [Integer, nil] secondes totales ou nil

player.initial_time_budget  # => 7200 (2 heures)
                            # => nil (si pas de périodes)

# Exemples :
# Fischer 5+3: 300
# Classique 90+30: 7200 (5400+1800)
# Byōyomi 60min + 5x60s: 3900
```

### Player Prédicats

#### `#empty?`

Vérifie si le joueur n'a aucune donnée.

```ruby
# @return [Boolean] true si tous les champs sont nil

player.empty? # => false (a des données)
Player.new.empty? # => true
```

### Player Sérialisation

#### `#to_h`

Convertit en hash (omet les champs nil).

```ruby
# @return [Hash] hash avec champs non-nil

player.to_h
# => {
#   name: "Magnus Carlsen",
#   elo: 2830,
#   style: "CHESS",
#   periods: [{ time: 300, moves: nil, inc: 3 }]
# }

# Joueur partiel
partial.to_h
# => { name: "Anonymous" }

# Joueur vide
empty.to_h
# => {}
```

#### `#==(other)`

Compare avec un autre joueur.

```ruby
# @param other [Object] objet à comparer
# @return [Boolean] true si égaux

player1 == player2 # => true si tous les attributs correspondent
```

#### `#hash`

Retourne le code de hachage.

```ruby
# @return [Integer] code de hachage

player.hash # => 987654321
```

#### `#inspect`

Retourne une représentation de débogage.

```ruby
# @return [String] string de débogage

player.inspect
# => "#<Player name=\"Magnus Carlsen\" elo=2830 style=\"CHESS\" periods=[...]>"
```

---

## Validation et erreurs

### Types d'erreurs

Toutes les erreurs de validation lèvent `ArgumentError` avec des messages descriptifs.

#### Erreurs de setup

```ruby
Game.new(setup: nil)
# => ArgumentError: "setup is required"

Game.new(setup: "invalid")
# => ArgumentError: "Invalid FEEN format"
```

#### Erreurs de coups

```ruby
game.add_move("e2-e4")
# => ArgumentError: "Each move must be [PAN string, seconds float] tuple"

game.add_move(["invalid", 2.5])
# => ArgumentError: "Invalid PAN notation: ..."

game.add_move(["e2-e4", -5])
# => ArgumentError: "seconds must be a non-negative number"
```

#### Erreurs de draw_offered_by

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

#### Erreurs de métadonnées

```ruby
Meta.new(round: 0)
# => ArgumentError: "round must be a positive integer (>= 1)"

Meta.new(started_at: "2025-01-27")
# => ArgumentError: "started_at must be in ISO 8601 datetime format"

Meta.new(href: "not-a-url")
# => ArgumentError: "href must be an absolute URL (http:// or https://)"
```

#### Erreurs de joueur

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

### Méthodes de validation

```ruby
# Vérifier si la structure PCN est valide
Sashite::Pcn.valid?(hash) # => true/false

# Valider des composants individuels
begin
  game = Sashite::Pcn::Game.new(setup: data[:setup])
rescue ArgumentError => e
  puts "Invalid: #{e.message}"
end
```

---

## Référence des types

### Types requis

| Champ | Type | Description |
|-------|------|-------------|
| `setup` | String | Position FEEN (requis) |

### Types optionnels

| Champ | Type | Défaut | Description |
|-------|------|---------|-------------|
| `moves` | Array<[String, Float]> | `[]` | Coups PAN avec secondes |
| `status` | String ou nil | `nil` | Statut CGSN |
| `draw_offered_by` | String ou nil | `nil` | Proposition de nulle |
| `meta` | Hash | `{}` | Champs de métadonnées |
| `sides` | Hash | `{}` | Informations sur les joueurs |

### Structure d'un tuple de coup

```ruby
[
  "e2-e4",  # Notation PAN (String)
  2.5       # Secondes passées (Float >= 0.0)
]
```

### Valeurs de draw_offered_by

```ruby
nil        # Aucune proposition de nulle en attente (défaut)
"first"    # Le premier joueur a proposé une nulle
"second"   # Le second joueur a proposé une nulle
```

### Structure d'une période

```ruby
{
  time:  300, # Secondes (Integer >= 0, requis)
  moves: nil, # Nombre de coups (Integer >= 1 ou nil)
  inc:   3    # Incrément (Integer >= 0, défaut: 0)
}
```

### Structure d'un joueur

```ruby
{
  name:    "Magnus Carlsen", # String (optionnel)
  elo:     2830,              # Integer >= 0 (optionnel)
  style:   "CHESS",           # String SNN (optionnel)
  periods: []                 # Array<Hash> (optionnel)
}
```

### Structure de Meta

Champs standards (validés) :
```ruby
{
  name:       "Italian Game",          # String
  event:      "World Championship",    # String
  location:   "Dubai",                 # String
  round:      5,                       # Integer >= 1
  started_at: "2025-01-27T14:00:00Z", # ISO 8601
  href:       "https://example.com" # URL absolue
}
```

Champs personnalisés (non validés) :
```ruby
{
  platform:    "lichess.org",
  opening_eco: "B90",
  rated:       true,
  anything:    "accepted"
}
```

---

## Patterns courants

### Construire une partie progressivement

```ruby
# Commencer minimal
game = Sashite::Pcn::Game.new(
  setup: "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c"
)

# Ajouter des métadonnées
game = game.with_meta(
  event:      "Tournament",
  started_at: Time.now.utc.iso8601
)

# Jouer des coups
game = game.add_move(["e2-e4", 2.3])
game = game.add_move(["e7-e5", 3.1])

# Proposer une nulle
game = game.with_draw_offered_by("first")

# Terminer
game = game.with_status("checkmate")
```

### Patterns de contrôle du temps

```ruby
# Fischer/Incrément
periods = [{ time: 300, moves: nil, inc: 3 }]

# Tournoi classique
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

# Canadien
periods = [
  { time: 3600, moves: nil, inc: 0 },
  { time: 300, moves: 10, inc: 0 }
]
```

### Travailler avec les métadonnées

```ruby
# Vérifier les champs
puts "Playing on #{game.meta[:platform]}" if game.meta.key?(:platform)

# Itérer sur les métadonnées
game.meta.each do |key, value|
  next if %i[event round].include?(key) # Ignorer les standards

  puts "Custom: #{key} = #{value}"
end

# Mettre à jour les métadonnées
game = game.with_meta(
  round:      game.meta[:round] + 1,
  updated_at: Time.now.iso8601
)
```

### Gérer les propositions de nulle

```ruby
# Proposer une nulle
game = game.with_draw_offered_by("first")

# Vérifier si une proposition est en attente
puts "Draw offer from: #{game.draw_offered_by}" if game.draw_offered?

# Accepter une nulle
game = game.with_status("agreement")

# Annuler une proposition de nulle
game = game.with_draw_offered_by(nil)
```

### Analyser les joueurs

```ruby
# Comparer les joueurs
sides = game.sides

if sides.complete?
  rating_diff = sides.elos[0] - sides.elos[1]
  puts "Rating difference: #{rating_diff}"
end

# Vérifier l'équité du contrôle du temps
if sides.symmetric_time_control?
  puts "Fair match"
elsif sides.mixed_time_control?
  puts "Handicap game"
elsif sides.unlimited_game?
  puts "Casual game"
end

# Traiter chaque joueur
sides.each.with_index do |player, i|
  color = i == 0 ? "White" : "Black"
  puts "#{color}: #{player.name || 'Anonymous'}"

  puts "  Time: #{player.initial_time_budget / 60} minutes" if player.has_time_control?
end
```

### Import/Export JSON

```ruby
# Import
require "json"

# Depuis un fichier
json = File.read("game.pcn.json")
game = Sashite::Pcn.parse(JSON.parse(json))

# Depuis une API
require "net/http"
response = Net::HTTP.get(URI("https://api.example.com/game/123"))
game = Sashite::Pcn.parse(JSON.parse(response))

# Export
File.write("output.pcn.json", JSON.pretty_generate(game.to_h))

# Vers une API
uri = URI("https://api.example.com/games")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri)
request["Content-Type"] = "application/json"
request.body = JSON.generate(game.to_h)
response = http.request(request)
```

---

## Informations sur la version

- **Version du gem** : Voir la version du gem `sashite-pcn`
- **Spécification PCN** : v1.0.0
- **Ruby requis** : >= 3.2.0
- **Dépendances** :
  - `sashite-pan` ~> 4.0
  - `sashite-feen` ~> 0.3
  - `sashite-snn` ~> 3.1
  - `sashite-cgsn` ~> 0.1

---

## Liens

- [Dépôt GitHub](https://github.com/sashite/pcn.rb)
- [Documentation RubyDoc](https://rubydoc.info/github/sashite/pcn.rb/main)
- [Spécification PCN](https://sashite.dev/specs/pcn/1.0.0/)
- [Exemples](https://sashite.dev/specs/pcn/1.0.0/examples/)
- [Exemples de propositions de nulle](https://sashite.dev/specs/pcn/1.0.0/examples/draw-offers/)
