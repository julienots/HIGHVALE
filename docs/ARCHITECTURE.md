# Architecture de HIGHVALE

## Principes

1. **Les données sont séparées de la logique.** Tout le contenu (ressources, bâtiments, histoire, et plus tard héros, monstres, compétences, objets) est décrit par des ressources Godot `.tres` dans `data/`. Le `DataRegistry` charge automatiquement chaque dossier : ajouter du contenu revient à déposer un fichier.
2. **La logique est séparée de l'affichage.** `CityState`, `BuildingState` et `Wallet` sont de purs objets `RefCounted`, sans nœud ni rendu. Ils sont testés en mode headless et entièrement sérialisables.
3. **Les modules communiquent par signaux** (`Events`), sans références croisées.
4. **Le temps est mesuré en heure Unix** (`GameClock`) : chantiers et production avancent aussi hors ligne.
5. **Les visuels sont remplaçables.** Chaque `BuildingData` a un `model_scene` (modèle glTF) et une `model_recipe` (modèle procédural de secours). Le modèle est utilisé partout : cité, aperçu de placement, vignettes des menus.

## Chaîne des modèles 3D

```
tools/blender/hv_kit.py        Boîte à outils : pierres biseautées, murs maçonnés, toits à tuiles,
                               colombages, fenêtres, portes, bannières, cristaux, champignons…
tools/blender/models/<id>.py   Un script par bâtiment : build(m)
tools/blender/build_models.py  Export → assets/models/buildings/<id>.glb (+ aperçus Cycles)
src/city/model_rig.gd          Lecture des conventions à l'import dans Godot
```

Conventions des noms de nœuds glTF (jetons séparés par `_`) :

| Jeton | Effet dans Godot |
|---|---|
| `t0`…`t3` | visible à partir du palier (niveaux 1-2, 3-4, 5-6, 7+) |
| `spinY35` | rotation continue, 35°/s autour de l'axe Y |
| `bob8` | flottement vertical de 0,08 |
| `light_RRGGBB_e14_r50` | repère remplacé par une OmniLight3D (énergie 1,4, portée 5,0) |

Les matériaux sont fusionnés par type (`stone`, `wood`, `roof_blue`, `gold`…) : un bâtiment représente environ 10 à 20 appels de rendu. Les couleurs de sommets ajoutent la variation pierre par pierre et une occlusion ambiante au pied des murs. Les matériaux `crystal*` reçoivent le shader de cristal pulsé.

## Arborescence

```
project.godot            Configuration (rendu Mobile, paysage, autoloads)
export_presets.cfg       Préréglage Android
assets/
  branding/              Logos HIGHVALE / Super Essence, icônes Android
  fonts/                 Lilita One (titres), Fredoka (texte) + licences OFL
  icons/resources/       Icônes SVG des 11 ressources
  icons/ui/              Icônes SVG de l'interface
  shaders/               Sol, eau, cascade, cristaux, quadrillage, sélection
data/
  config/game_config.tres  Équilibrage global et disposition de départ
  resources/*.tres         ResourceTypeData
  buildings/*.tres         BuildingData (21 bâtiments)
  story/*.tres             StoryChapterData
scenes/                  Scènes minimales (boot, menu, cité)
src/
  core/        Autoloads et utilitaires partagés
  economy/     Wallet, ResourceTypeData
  city/        CityState, BuildingState, BuildingData, vue 3D, caméra, modèles
  save/        SaveSystem
  ui/          Thème, HUD, menus, fenêtres
  heroes/      HeroData, CollectionState (héros, fragments, créatures)
  monsters/    MonsterData
  laboratory/  IngredientData (schéma, étape 6)
  combat/      Moteur de combat (BattleState, Combatant, BattleSetup), scène 3D, SkillData, CharacterRig
  ai/          BattleAI (IA tactique)
  laboratory/  LabRules, LaboratoryState, LabMachine
  fusion/      FusionRules, recettes
  summoning/   Bannières, SummonRules
  inventory/   Inventory (ingrédients)
  inventory/   ItemData (schéma)
  exploration/ ZoneData (schéma, étape 9)
  quests/      StoryChapterData
  population/  CityNav (A*), Villager, PopulationView
tests/                   Tests headless et visite visuelle
```

Les modules **AI**, **Fusion**, **Summoning** et **Shop** du cahier des charges n'ont pas encore de code. Leurs dossiers seront créés à l'étape où ils sont livrés, plutôt que de laisser des fichiers vides.

## Autoloads (ordre de chargement)

| Nom | Rôle |
|---|---|
| `Events` | Bus de signaux global |
| `GameClock` | Heure Unix plus un décalage de débogage (`skip()`) |
| `DataRegistry` | Charge `data/**` ; accès par identifiant |
| `Settings` | Préférences utilisateur (`user://settings.cfg`) |
| `SaveSystem` | Sauvegarde JSON versionnée, atomique, avec copie de secours |
| `GameState` | Possède `wallet` et `city` ; avance les chantiers ; sauvegarde automatique |
| `SceneRouter` | Changement d'écran avec fondu |

## Flux d'une action (exemple : améliorer une mine)

```
BuildingPanel (UI) ─▶ CityScene.open_upgrade() ─▶ DialogBox
   ─▶ CityState.start_upgrade(b, wallet, now)   # règles, paiement, minuterie
        └─ signal building_changed ─▶ GameState ─▶ Events.building_changed
                                            └─▶ CityScene ─▶ BuildingNode.refresh()
GameState._process ─▶ CityState.update(now) ─▶ task_finished ─▶ Events (+ histoire si Temple)
```

## Règles de la cité

- **Grille** de 40 × 40 cases, dont 34 × 34 constructibles (`GameConfig.buildable_rect`).
- **Coûts et durées** : `base × croissance^(niveau−1)`, arrondis à des valeurs lisibles.
- **Niveau maximal** d'un bâtiment = `level_cap_base + (Temple − 1) × level_cap_per_temple`.
- **Nombre d'exemplaires** : `max_count_by_temple[niveau du Temple − 1]`.
- **Bâtisseurs** = `base_builders` + `builders_provided` des bâtiments (Hôtel des habitants).
- **Production** : accumulée depuis `prod_since`, plafonnée par la réserve interne, en pause pendant un chantier. La collecte est limitée à la place libre ; le surplus reste dans le bâtiment.
- **Modules futurs** : `BuildingData.feature` et `FeatureFlags` verrouillent les bâtiments dont le système n'est pas encore livré.

## Collection

- Données : `data/heroes`, `data/monsters`, `data/skills` (chargés par `DataRegistry`). Chaque personnage référence son modèle (`assets/models/characters/`) et son portrait (`assets/portraits/`, rendu par `build_models.py --portraits`).
- `CollectionState` (dans `GameState.collection`, sauvegardé sous `collection`) : héros `{level, stars}`, `fragments`, créatures `{uid: {id, level}}`.
- Étoiles de départ selon la rareté (1 à 4) ; niveau maximal = 10 + 10 × étoiles ; statistiques +10 % par étoile au-delà de la première.
- `CharacterRig` anime un personnage articulé (respiration, bras, ailes, queue) ; `CharacterViewer` l'affiche dans une SubViewport.

## Population

- `CityState` porte les habitants (`inhabitants`, `growth_since`) : un arrivant toutes les `population_growth_seconds` jusqu'à la capacité des logements, calcul par horodatage (progression hors ligne).
- `BuildingData.base_workers` définit les postes (+1 tous les deux niveaux). `BuildingState.workers` et `desired_workers` sont sauvegardés.
- Efficacité = 25 % + 75 % × ouvriers / postes ; la production accumulée est figée (`flush`) avant chaque changement.
- `auto_assign` répartit les habitants libres vers les postes les moins pourvus ; `set_desired_workers` applique le choix du joueur.
- Affichage : `PopulationView` crée jusqu'à 26 habitants visibles (deux par bâtiment de production, un par chantier, six flâneurs). `Villager` suit une petite machine à états (marche, travail, attente) et anime ses pièces articulées.
- Les personnages utilisent un matériau unique « palette » (couleurs portées par les sommets) : environ 6 appels de rendu par habitant.

## Ajouter du contenu

**Nouveau bâtiment** : créer `data/buildings/mon_batiment.tres` (type `BuildingData`) avec un `id` unique, écrire `tools/blender/models/mon_batiment.py`, lancer `build_models.py mon_batiment`, puis renseigner `model_scene`. Les tests `test_data` et `test_models` vérifient la cohérence.

**Nouvelle ressource** : créer `data/resources/x.tres` (type `ResourceTypeData`) avec son icône SVG.

**Nouveau chapitre** : créer `data/story/x.tres` (type `StoryChapterData`, `temple_level`).

**Livrer un module** : ajouter son identifiant dans `FeatureFlags.ENABLED`. Les bâtiments liés deviennent alors constructibles.

## Sauvegarde

`user://highvale_save.json` :

```json
{ "version": 1, "game_version": "0.3.0", "saved_at": 0, "data": {
  "profile": { "player_name": "...", "story_seen": [] },
  "wallet": { "gold": 1000 },
  "city": { "next_uid": 5, "buildings": [{ "uid": 1, "id": "primordial_temple", "level": 1, "x": 18, "y": 18, "task": 0 }] } } }
```

Toute évolution du format incrémente `SAVE_VERSION` et ajoute une étape à `SaveSystem._migrate()`.

## Performances mobiles

- Rendu « Mobile » (Vulkan), lueur, ombre directionnelle unique (désactivable), brouillard léger.
- Les décors statiques de la caverne sont fusionnés par matériau (`CaveEnvironment._merge_static`), quelques appels de rendu au lieu de plusieurs centaines.
- Matériaux et maillages primitifs mis en cache (`MeshKit`).
- Limite de 30 ou 60 images par seconde configurable (batterie).
