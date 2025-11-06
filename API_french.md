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
                            "status" => "in_progress",
                            "winner" => nil
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

#### `Game.new(setup:, moves: [], status: nil, draw_offered_by: nil, winner: nil, meta: {}, sides: {})`

Crée une nouvelle instance de partie avec validation.

```ruby
# Paramètres
# @param setup [String] position FEEN (requis)
# @param moves [Array<Array>] tableau de tuples [PAN, secondes] (optionnel)
# @param status [String, nil] statut CGSN (optionnel)
# @param draw_offered_by [String, nil] proposition de nulle ("first", "second", ou nil) (optionnel)
# @param winner [String, nil] résultat compétitif ("first", "second", "none", ou nil) (optionnel)
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

# Partie avec proposition de nulle
game = Sashite::Pcn::Game.new(
  setup:           "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves:           [["e2-e4", 8.0], ["e7-e5", 12.0]],
  status:          "in_progress",
  draw_offered_by: "first", # Le premier joueur a proposé une nulle
  winner:          nil
)

# Partie terminée avec un gagnant
game = Sashite::Pcn::Game.new(
  setup:  "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves:  [["e2-e4", 8.0], ["e7-e5", 12.0], ["g1-f3", 15.0]],
  status: "resignation",
  winner: "first" # Le premier joueur a gagné (le second a abandonné)
)

# Nulle par accord mutuel
game = Sashite::Pcn::Game.new(
  setup:           "+rnbq+kbn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+KBN+R / C/c",
  moves:           [["e2-e4", 8.0], ["e7-e5", 12.0]],
  status:          "agreement",
  draw_offered_by: "first",
  winner:          "none" # Pas de gagnant (nulle)
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

**Indépendance avec `status` et `winner` :**

Le champ `draw_offered_by` est complètement indépendant des champs `status` et `winner`. Il enregistre la communication entre les joueurs (état de proposition), tandis que `status` enregistre l'état observable de la partie (condition terminale) et `winner` enregistre le résultat compétitif.

**Transitions d'état courantes :**

1. **Proposition faite** : `draw_offered_by` passe de `nil` à `"first"` ou `"second"`, `status` reste `"in_progress"`, `winner` reste `nil`
2. **Proposition acceptée** : `status` passe à `"agreement"`, `winner` devient `"none"`, `draw_offered_by` peut rester défini ou être effacé (choix d'implémentation)
3. **Proposition annulée/retirée** : `draw_offered_by` retourne à `nil`, `status` reste `"in_progress"`, `winner` reste `nil`

#### `#winner`

Retourne le résultat compétitif de la partie.

```ruby
# @return [String, nil] "first", "second", "none", ou nil

game.winner # => "first"   # Le premier joueur a gagné
game.winner # => "second"  # Le second joueur a gagné
game.winner # => "none"    # Nulle (pas de gagnant)
game.winner # => nil       # Résultat non déterminé ou partie en cours
```

**Sémantique du champ `winner` :**

- **`nil`** (défaut) : Résultat non déterminé ou partie en cours
- **`"first"`** : Le premier joueur a gagné la partie
- **`"second"`** : Le second joueur a gagné la partie
- **`"none"`** : Nulle (pas de gagnant)

**Objectif et avantages :**

Le champ `winner` enregistre explicitement le résultat compétitif, éliminant toute ambiguïté dans l'interprétation du statut de la partie. Il est particulièrement utile pour clarifier les statuts ambigus :

**Désambiguïsation des statuts ambigus :**

- **Abandon** : `status: "resignation", winner: "first"` clarifie que le second joueur a abandonné
- **Temps écoulé** : `status: "time_limit", winner: "second"` clarifie que le premier joueur a perdu au temps
- **Coup illégal** : `status: "illegal_move", winner: "first"` clarifie que le second joueur a fait un coup illégal
- **Accord mutuel** : `status: "agreement", winner: "none"` confirme explicitement la nulle

**Cohérence avec `status` :**

Bien que `winner` puisse souvent être déduit de `status` et de la position, une déclaration explicite :
- Élimine le besoin de logique d'inférence complexe
- Prend en charge les variantes avec différentes interprétations de règles
- Fournit une clarté immédiate pour l'analyse et l'affichage
- Permet des substitutions dans des cas spéciaux ou des règles de tournoi

**Cohérence recommandée :**

| Statut | Gagnant attendu | Notes |
|--------|-----------------|-------|
| `"checkmate"` | `"first"` ou `"second"` | Gagnant selon qui a donné l'échec et mat |
| `"stalemate"` | `"none"` | Généralement nulle aux échecs occidentaux |
| `"resignation"` | `"first"` ou `"second"` | Opposé de celui qui a abandonné |
| `"time_limit"` | `"first"` ou `"second"` | Opposé de celui qui a dépassé le temps |
| `"repetition"` | `"none"` ou autre | Dépend des règles du jeu |
| `"agreement"` | `"none"` | Généralement nulle par accord mutuel |
| `"insufficient"` | `"none"` | Nulle par matériel insuffisant |
| `"in_progress"` | `null` | Partie non terminée |

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

#### `#event`

Retourne le nom de l'événement.

```ruby
# @return [String, nil] nom de l'événement ou nil

game.event # => "World Championship"
```

#### `#round`

Retourne le numéro de ronde.

```ruby
# @return [Integer, nil] numéro de ronde ou nil

game.round # => 5
```

#### `#location`

Retourne le lieu.

```ruby
# @return [String, nil] lieu ou nil

game.location # => "Dubai"
```

#### `#started_at`

Retourne la date/heure de début.

```ruby
# @return [String, nil] date/heure ISO 8601 ou nil

game.started_at # => "2025-01-27T14:00:00Z"
```

#### `#href`

Retourne l'URL de référence.

```ruby
# @return [String, nil] URL ou nil

game.href # => "https://example.com/game/123"
```

### Game Transformations

#### `#with_status(new_status)`

Retourne une nouvelle partie avec le statut mis à jour (immuable).

```ruby
# @param new_status [String, nil] nouvelle valeur de statut
# @return [Game] nouvelle instance de partie avec le statut mis à jour
# @raise [ArgumentError] si le statut est invalide

# Exemple
updated = game.with_status("resignation")
```

#### `#with_draw_offered_by(player)`

Retourne une nouvelle partie avec la proposition de nulle mise à jour (immuable).

```ruby
# @param player [String, nil] "first", "second", ou nil
# @return [Game] nouvelle instance de partie avec la proposition de nulle mise à jour
# @raise [ArgumentError] si le joueur est invalide

# Exemple
# Le premier joueur propose une nulle
game_with_offer = game.with_draw_offered_by("first")

# Retirer la proposition de nulle
game_no_offer = game.with_draw_offered_by(nil)
```

#### `#with_winner(new_winner)`

Retourne une nouvelle partie avec le gagnant mis à jour (immuable).

```ruby
# @param new_winner [String, nil] "first", "second", "none", ou nil
# @return [Game] nouvelle instance de partie avec le gagnant mis à jour
# @raise [ArgumentError] si le gagnant est invalide

# Exemples
# Le premier joueur gagne
game_first_wins = game.with_winner("first")

# Le second joueur gagne
game_second_wins = game.with_winner("second")

# Nulle (pas de gagnant)
game_draw = game.with_winner("none")

# Effacer le gagnant (partie en cours)
game_in_progress = game.with_winner(nil)
```

#### `#with_meta(**new_meta)`

Retourne une nouvelle partie avec les métadonnées mises à jour (immuable).

```ruby
# @param new_meta [Hash] métadonnées à fusionner
# @return [Game] nouvelle instance de partie avec les métadonnées mises à jour

# Exemple
updated = game.with_meta(event: "Casual Game", round: 1)
```

#### `#with_moves(new_moves)`

Retourne une nouvelle partie avec la séquence de coups spécifiée (immuable).

```ruby
# @param new_moves [Array<Array>] nouvelle séquence de coups de tuples [PAN, secondes]
# @return [Game] nouvelle instance de partie avec les nouveaux coups
# @raise [ArgumentError] si le format du coup est invalide

# Exemple
updated = game.with_moves([["e2-e4", 2.0], ["e7-e5", 3.0]])
```

### Game Prédicats

#### `#in_progress?`

Vérifie si la partie est en cours.

```ruby
# @return [Boolean, nil] true si en cours, false si terminée, nil si indéterminé

# Exemple
game.in_progress? # => true
```

#### `#finished?`

Vérifie si la partie est terminée.

```ruby
# @return [Boolean, nil] true si terminée, false si en cours, nil si indéterminé

# Exemple
game.finished? # => false
```

#### `#draw_offered?`

Vérifie si une proposition de nulle est en attente.

```ruby
# @return [Boolean] true si une proposition de nulle est en attente

# Exemple
game.draw_offered?  # => true (si draw_offered_by est "first" ou "second")
game.draw_offered?  # => false (si draw_offered_by est nil)
```

#### `#has_winner?`

Vérifie si un gagnant a été déterminé.

```ruby
# @return [Boolean] true si le gagnant est déterminé (first, second, ou none)

# Exemple
game.has_winner?  # => true (si winner est "first", "second", ou "none")
game.has_winner?  # => false (si winner est nil)
```

#### `#decisive?`

Vérifie si la partie a eu un résultat décisif (pas une nulle).

```ruby
# @return [Boolean, nil] true si décisif (first ou second a gagné), false si nulle, nil si pas de gagnant

# Exemple
game.decisive?  # => true (si winner est "first" ou "second")
game.decisive?  # => false (si winner est "none")
game.decisive?  # => nil (si winner est nil)
```

#### `#drawn?`

Vérifie si la partie s'est terminée par une nulle.

```ruby
# @return [Boolean] true si winner est "none" (nulle)

# Exemple
game.drawn?  # => true (si winner est "none")
game.drawn?  # => false (si winner est nil, "first", ou "second")
```

### Game Sérialisation

#### `#to_h`

Convertit en représentation hash.

```ruby
# @return [Hash] hash avec des clés string prêt pour la sérialisation JSON

# Exemple
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

Convertit en chaîne JSON.

```ruby
# @return [String] représentation JSON

# Exemple
game.to_json
# => '{"setup":"...","moves":[["e2-e4",2.5],["e7-e5",3.1]],...}'

require "json"
JSON.pretty_generate(game.to_h)
```

#### `#==(other)`

Compare avec une autre partie.

```ruby
# @param other [Object] objet à comparer
# @return [Boolean] true si égal

# Exemple
game1 == game2 # => true si tous les attributs correspondent
```

#### `#hash`

Génère un code de hachage.

```ruby
# @return [Integer] code de hachage pour cette partie

# Exemple
game.hash # => 123456789
```

#### `#inspect`

Génère une représentation de débogage.

```ruby
# @return [String] chaîne de débogage

# Exemple
game.inspect
# => "#<Game setup=\"...\" moves=[...] status=\"in_progress\" draw_offered_by=\"first\" winner=nil>"
```

---

## Classe: Meta

Représente les métadonnées de la partie avec support pour les champs standards et personnalisés.

### Meta Champs standards

Champs standards avec validation :

```ruby
meta = Sashite::Pcn::Game::Meta.new(
  name:       "Italian Game",         # String
  event:      "World Championship",   # String
  location:   "Dubai",                # String
  round:      5,                      # Integer >= 1
  started_at: "2025-01-27T14:00:00Z", # ISO 8601
  href:       "https://example.com"   # URL absolue
)
```

### Meta Champs personnalisés

Les champs personnalisés passent sans validation :

```ruby
meta = Sashite::Pcn::Game::Meta.new(
  platform:    "lichess.org",
  opening_eco: "B90",
  rated:       true,
  arbiter:     "John Smith"
)
```

### Meta Méthodes d'accès

#### `#[](key)`

Accède au champ par clé symbole ou string.

```ruby
# @param key [Symbol, String] nom du champ
# @return [Object, nil] valeur du champ ou nil

meta[:event]   # => "World Championship"
meta["event"]  # => "World Championship"
```

#### `#fetch(key, default = nil)`

Récupère le champ avec une valeur par défaut optionnelle.

```ruby
# @param key [Symbol, String] nom du champ
# @param default [Object] valeur par défaut
# @return [Object] valeur du champ ou valeur par défaut

meta.fetch(:event)           # => "World Championship"
meta.fetch(:missing, "N/A")  # => "N/A"
```

#### `#key?(key)`

Vérifie si le champ existe.

```ruby
# @param key [Symbol, String] nom du champ
# @return [Boolean] true si le champ existe

meta.key?(:event)   # => true
meta.key?(:missing) # => false
```

### Meta Itération et collection

#### `#each`

Itère sur les champs.

```ruby
# @yield [key, value] clé et valeur du champ
# @return [Enumerator] si aucun bloc n'est fourni

meta.each do |key, value|
  puts "#{key}: #{value}"
end
```

#### `#keys`

Récupère toutes les clés de champs.

```ruby
# @return [Array<Symbol>] clés de champs

meta.keys # => [:event, :round, :started_at]
```

#### `#values`

Récupère toutes les valeurs de champs.

```ruby
# @return [Array<Object>] valeurs de champs

meta.values # => ["World Championship", 5, "2025-01-27T14:00:00Z"]
```

#### `#empty?`

Vérifie si les métadonnées sont vides.

```ruby
# @return [Boolean] true si aucun champ

meta.empty? # => false
```

#### `#to_h`

Convertit en hash.

```ruby
# @return [Hash] hash avec des clés string

meta.to_h
# => {
#   "event" => "World Championship",
#   "round" => 5,
#   "started_at" => "2025-01-27T14:00:00Z"
# }
```

### Meta Comparaison et égalité

#### `#==(other)`

Compare avec un autre Meta.

```ruby
# @param other [Object] objet à comparer
# @return [Boolean] true si égal

meta1 == meta2 # => true si tous les champs correspondent
```

---

## Classe: Sides

Représente les informations des joueurs pour les deux camps.

### Sides Accès aux joueurs

#### `#first`

Récupère les informations du premier joueur.

```ruby
# @return [Player, nil] premier joueur ou nil

sides.first
# => #<Player name="Magnus Carlsen" elo=2830 style="CHESS" ...>
```

#### `#second`

Récupère les informations du second joueur.

```ruby
# @return [Player, nil] second joueur ou nil

sides.second
# => #<Player name="Hikaru Nakamura" elo=2794 style="chess" ...>
```

### Sides Accès indexé

#### `#[](index)`

Accède au joueur par index numérique.

```ruby
# @param index [Integer] 0 pour le premier, 1 pour le second
# @return [Player, nil] joueur ou nil

sides[0]  # => premier joueur
sides[1]  # => second joueur
sides[2]  # => nil
```

### Sides Opérations par lot

#### `#names`

Récupère les noms des deux joueurs.

```ruby
# @return [Array<String, nil>] tableau de noms (peut contenir des nil)

sides.names # => ["Magnus Carlsen", "Hikaru Nakamura"]
```

#### `#elos`

Récupère les classements ELO des deux joueurs.

```ruby
# @return [Array<Integer, nil>] tableau de classements (peut contenir des nil)

sides.elos # => [2830, 2794]
```

#### `#styles`

Récupère les styles des deux joueurs.

```ruby
# @return [Array<String, nil>] tableau de styles (peut contenir des nil)

sides.styles # => ["CHESS", "chess"]
```

#### `#periods`

Récupère les périodes de contrôle du temps des deux joueurs.

```ruby
# @return [Array<Array<Hash>, nil>] tableau de tableaux de périodes (peut contenir des nil)

sides.periods
# => [
#   [{ time: 300, moves: nil, inc: 3 }],
#   [{ time: 300, moves: nil, inc: 3 }]
# ]
```

### Sides Analyse du contrôle du temps

#### `#symmetric_time_control?`

Vérifie si les deux joueurs ont un contrôle du temps identique.

```ruby
# @return [Boolean] true si les contrôles du temps sont identiques

sides.symmetric_time_control? # => true
```

#### `#mixed_time_control?`

Vérifie si les joueurs ont des contrôles du temps différents.

```ruby
# @return [Boolean] true si les contrôles du temps diffèrent

sides.mixed_time_control? # => false
```

#### `#unlimited_game?`

Vérifie si aucun joueur n'a de contrôle du temps.

```ruby
# @return [Boolean] true si aucun contrôle du temps n'est défini

sides.unlimited_game? # => false
```

### Sides Prédicats

#### `#complete?`

Vérifie si les deux joueurs sont définis.

```ruby
# @return [Boolean] true si le premier et le second sont définis

sides.complete? # => true
```

#### `#empty?`

Vérifie si aucun joueur n'est défini.

```ruby
# @return [Boolean] true si le premier et le second sont nil

sides.empty? # => false
```

### Sides Collections et itération

#### `#each`

Itère sur les joueurs.

```ruby
# @yield [player] instance de joueur
# @return [Enumerator] si aucun bloc n'est fourni

sides.each do |player|
  puts player.name
end
```

#### `#to_h`

Convertit en hash.

```ruby
# @return [Hash] hash avec des clés string

sides.to_h
# => {
#   "first" => { "name" => "...", ... },
#   "second" => { "name" => "...", ... }
# }
```

---

## Classe: Player

Représente les informations d'un joueur individuel.

### Player Attributs principaux

#### `#name`

Récupère le nom du joueur.

```ruby
# @return [String, nil] nom du joueur ou nil

player.name # => "Magnus Carlsen"
```

#### `#elo`

Récupère le classement ELO du joueur.

```ruby
# @return [Integer, nil] classement ELO ou nil

player.elo # => 2830
```

#### `#style`

Récupère le style du joueur.

```ruby
# @return [String, nil] chaîne de style SNN ou nil

player.style # => "CHESS"
```

#### `#periods`

Récupère les périodes de contrôle du temps.

```ruby
# @return [Array<Hash>, nil] tableau de hash de périodes ou nil

player.periods
# => [
#   { time: 5400, moves: 40, inc: 0 },
#   { time: 1800, moves: nil, inc: 30 }
# ]
```

### Player Contrôle du temps

#### `#has_time_control?`

Vérifie si le joueur a un contrôle du temps défini.

```ruby
# @return [Boolean] true si periods est non vide

player.has_time_control? # => true
```

#### `#initial_time_budget`

Calcule le budget de temps initial total.

```ruby
# @return [Integer, nil] secondes totales ou nil

player.initial_time_budget # => 7200 (5400 + 1800)
```

#### `#fischer?`

Vérifie si le contrôle du temps Fischer/incrément est utilisé.

```ruby
# @return [Boolean] true si période unique avec incrément et pas de quota de coups

player.fischer? # => true
```

#### `#byoyomi?`

Vérifie si le contrôle du temps byōyomi est utilisé.

```ruby
# @return [Boolean] true si périodes multiples avec moves=1

player.byoyomi? # => false
```

#### `#canadian?`

Vérifie si le contrôle du temps canadien est utilisé.

```ruby
# @return [Boolean] true si a une période avec moves>1

player.canadian? # => false
```

### Player Prédicats

#### `#complete?`

Vérifie si tous les champs sont définis.

```ruby
# @return [Boolean] true si name, elo, style, et periods sont tous présents

player.complete? # => true
```

#### `#anonymous?`

Vérifie si le joueur n'a pas de nom.

```ruby
# @return [Boolean] true si name est nil

player.anonymous? # => false
```

### Player Sérialisation

#### `#to_h`

Convertit en hash.

```ruby
# @return [Hash] hash avec des clés string

player.to_h
# => {
#   "name" => "Magnus Carlsen",
#   "elo" => 2830,
#   "style" => "CHESS",
#   "periods" => [...]
# }
```

---

## Validation et erreurs

### Gestion des erreurs

Toutes les erreurs de validation sont levées comme `ArgumentError` avec des messages descriptifs.

```ruby
begin
  game = Sashite::Pcn::Game.new(setup: invalid_setup)
rescue ArgumentError => e
  puts "La validation a échoué : #{e.message}"
end
```

### Scénarios d'erreurs courants

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

#### Erreurs de winner

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
| `winner` | String ou nil | `nil` | Résultat compétitif |
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

### Valeurs de winner

```ruby
nil        # Résultat non déterminé ou partie en cours (défaut)
"first"    # Le premier joueur a gagné
"second"   # Le second joueur a gagné
"none"     # Nulle (pas de gagnant)
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
  href:       "https://example.com"   # URL absolue
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

# Terminer avec un résultat
game = game.with_status("resignation")
game = game.with_winner("first") # Le second joueur a abandonné
```

### Enregistrer les résultats de partie

```ruby
# Le premier joueur gagne par échec et mat
game = game.with_status("checkmate")
game = game.with_winner("first")

# Le second joueur gagne au temps
game = game.with_status("time_limit")
game = game.with_winner("second")

# Nulle par accord mutuel
game = game.with_status("agreement")
game = game.with_winner("none")

# Nulle par pat
game = game.with_status("stalemate")
game = game.with_winner("none")

# Le second joueur abandonne
game = game.with_status("resignation")
game = game.with_winner("first")
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

### Gérer les propositions de nulle et les résultats

```ruby
# Proposer une nulle
game = game.with_draw_offered_by("first")

# Vérifier si une proposition est en attente
puts "Draw offer from: #{game.draw_offered_by}" if game.draw_offered?

# Accepter une nulle
game = game.with_status("agreement")
game = game.with_winner("none")

# Annuler une proposition de nulle
game = game.with_draw_offered_by(nil)

# Vérifier le résultat de la partie
if game.has_winner?
  if game.drawn?
    puts "La partie s'est terminée par une nulle"
  elsif game.winner == "first"
    puts "Le premier joueur gagne !"
  else
    puts "Le second joueur gagne !"
  end
end
```

### Analyser les joueurs

```ruby
# Comparer les joueurs
sides = game.sides

if sides.complete?
  rating_diff = sides.elos[0] - sides.elos[1]
  puts "Différence de classement : #{rating_diff}"
end

# Vérifier l'équité du contrôle du temps
if sides.symmetric_time_control?
  puts "Match équitable"
elsif sides.mixed_time_control?
  puts "Partie avec handicap"
elsif sides.unlimited_game?
  puts "Partie informelle"
end

# Traiter chaque joueur
sides.each.with_index do |player, i|
  color = i == 0 ? "Blancs" : "Noirs"
  puts "#{color} : #{player.name || 'Anonyme'}"

  puts "  Temps : #{player.initial_time_budget / 60} minutes" if player.has_time_control?
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

### Exemple complet de partie avec gagnant

```ruby
require "sashite/pcn"

# Partie complète avec toutes les fonctionnalités y compris le gagnant
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
    # ... plus de coups
  ],
  status: "resignation",
  winner: "first" # Magnus Carlsen gagne (Fabiano a abandonné)
)

# Afficher le résultat
puts "Événement : #{game.event}"
puts "Statut : #{game.status}"
puts "Gagnant : #{game.winner == 'first' ? game.first_player.name : game.second_player.name}"
puts "Résultat : Le premier joueur gagne par abandon"
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
