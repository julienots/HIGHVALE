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

## ⏳ Étape 4 — Population et récolte (prochaine étape proposée)

Plan :
1. `PopulationState` : habitants, logements (Hôtel), métiers (mineur, cultivateur, transporteur, bâtisseur), besoins (nourriture, bien-être).
2. Affectation des habitants aux bâtiments ; la production dépend des travailleurs affectés.
3. Habitants visibles qui marchent dans la cité (pathfinding sur la grille avec `AStarGrid2D`) : aller-retour mine ↔ entrepôt, bâtisseurs sur les chantiers.
4. Récolte manuelle de filons et de champignons sauvages autour de la cité.
5. Débloquer le module « population » dans `FeatureFlags`.

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

## Note sur les visuels

Les modèles des bâtiments et des décors sont actuellement **procéduraux** : assemblés par code, distincts les uns des autres et animés. Ce sont des modèles provisoires de qualité prototype. Le cahier des charges exige des modèles 3D, illustrations et animations travaillés individuellement ; ils seront produits (modélisation 3D, par exemple Blender vers glTF) et branchés via `model_scene` à l'étape 11. Les logos fournis par le studio sont déjà utilisés tels quels.
