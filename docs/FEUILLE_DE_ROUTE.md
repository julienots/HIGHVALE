# Feuille de route de HIGHVALE

Méthode suivie à chaque étape : analyser l'existant, présenter le plan, développer par petites étapes, tester, et garder une version jouable. Rien n'est déclaré terminé sans avoir été implémenté et testé.

## ✅ Étape 1 — Architecture

- Projet Godot 4 en rendu Mobile, paysage, autoloads, gestion du bouton Retour Android.
- Registre de données automatique ; schémas de données pour tous les domaines (bâtiments, ressources, héros, monstres, compétences, ingrédients, objets, zones, histoire).
- Énumérations partagées : raretés, éléments, classes, catégories de monstres, altérations d'état.
- Sauvegarde versionnée, atomique, avec copie de secours ; paramètres utilisateur.
- Thème d'interface « cartoon » complet, polices sous licence libre, icônes SVG originales.
- Tests headless (27 tests) et visite visuelle automatisée avec vérification des entrées tactiles.

## ✅ Étape 2 — Cité isométrique jouable

- Caverne 3D procédurale et animée, caméra isométrique tactile.
- Pose, déplacement et sélection des bâtiments ; aperçu de placement ; quadrillage.
- Modèles procéduraux distincts pour les 21 bâtiments, avec évolution visuelle par paliers.

## 🟡 Étape 3 — Bâtiments et économie (base jouable)

Fait :
- 10 ressources et la monnaie premium définies ; 4 ressources produites (Or, Pierre, Bois fongique, Cristaux abyssaux).
- Production, réserve interne, collecte, capacités de stockage (Temple, Entrepôt, Trésorerie).
- Construction et amélioration avec coûts, durées, bâtisseurs, accélération et annulation.
- Déblocages et niveaux maximum liés au Temple ; chapitres d'histoire aux niveaux 1, 2, 3 et 5.

Reste à faire :
- Sources des 6 autres ressources (Essence vitale, Éclats antiques, Sang primordial, Poussière divine, Minerai obscur, Nectar souterrain). Elles dépendent des étapes 4 à 9 ; d'ici là, elles sont affichées avec leur futur moyen d'obtention.
- Équilibrage complet de la progression du Temple, niveaux 1 à 10.
- Décorations et obstacles à dégager.

## 🟡 Étape 4 — Population et récolte (base jouable)

Fait (v0.5.0) :
- Croissance de la population jusqu'à la capacité des logements, y compris hors ligne.
- Postes d'ouvriers dans les bâtiments de production ; l'efficacité dépend des ouvriers affectés ; réglage − / + par le joueur ; fenêtre « Population ».
- Habitants modélisés (mineur, mineur de cristaux, cultivatrice, porteur, bâtisseur, habitante) qui marchent sur la grille (A*), travaillent, livrent leur récolte et construisent les chantiers.
- Tests : croissance, affectation, efficacité, souhaits du joueur, perte de logements.

Reste à faire :
- Besoins des habitants (nourriture, bien-être) et leur effet sur la croissance.
- Récolte manuelle de filons et de champignons sauvages autour de la cité.
- Métiers supplémentaires pour les bâtiments des étapes suivantes.

## ⏳ Étapes suivantes

| Étape | Contenu | Fondations déjà en place |
|---|---|---|
| 5 | Collections des héros et monstres | `HeroData`, `MonsterData`, `CharacterStats`, raretés et éléments |
| 6 | Laboratoire et Fusionnerie | `IngredientData` (affinités génétiques, bonus de rareté), `MonsterData.genetic_tags` |
| 7 | Invocations et dieux | `HeroData.is_god`, Sanctuaire et Autel divin dans les données |
| 8 | Combat au tour par tour et IA | `SkillData` (cibles, effets, altérations), `CharacterStats` |
| 9 | Progression et exploration, surface | `ZoneData.is_surface`, Portail antique, Tour des explorateurs |
| 10 | Boutique et événements | monnaie premium Prismes, bâtiment Marché |
| 11 | Graphismes définitifs | `model_scene` sur chaque donnée pour brancher les modèles glTF |
| 12 | Optimisation, tests appareils, export APK | préréglage Android prêt |

## Visuels (étape 11 entamée en avance)

Fait (v0.4.0) :
- Les 21 bâtiments ont un vrai modèle 3D glTF, construit dans Blender par des scripts versionnés (`tools/blender/`) : maçonnerie, tuiles, colombages, détails par palier de niveau, pièces animées et lumières intégrées.
- Aperçus Cycles et vitrine en jeu (`tests/model_showcase.tscn`) pour contrôler chaque modèle.

Reste à faire :
- Décors de la caverne (rochers, cristaux, champignons, ruines) au même niveau de détail ; ils sont encore assemblés en primitives dans `cave_environment.gd`.
- Textures peintes et animations squelettiques pour les héros et monstres (étape 5).
- Validation du rendu sur téléphone (renderer Mobile) : les captures actuelles proviennent du renderer de compatibilité sans GPU.
