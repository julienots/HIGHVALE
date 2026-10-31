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

## ✅ Étape 4 — Population et récolte

Fait (v0.5.0) :
- Croissance de la population jusqu'à la capacité des logements, y compris hors ligne.
- Postes d'ouvriers dans les bâtiments de production ; l'efficacité dépend des ouvriers affectés ; réglage − / + par le joueur ; fenêtre « Population ».
- Habitants modélisés (mineur, mineur de cristaux, cultivatrice, porteur, bâtisseur, habitante) qui marchent sur la grille (A*), travaillent, livrent leur récolte et construisent les chantiers.
- Tests : croissance, affectation, efficacité, souhaits du joueur, perte de logements.

Fait (v0.6.0) :
- Bien-être (0-100 %) : base, confort des bâtiments (Temple, décorations), festins payés en Nectar souterrain ; il règle la vitesse d'arrivée des habitants.
- Nectarerie : premier producteur de Nectar souterrain.
- Trois décorations : Fontaine de cristal, Jardin des lueurs, Statue du Fondateur.
- Ressources sauvages (filon, champignons, cristaux) : apparition régulière, aussi hors ligne, sur les cases libres ; elles bloquent la construction et se récoltent d'un toucher.

Plus tard :
- Métiers des bâtiments des étapes suivantes (forgerons, laborantins…).

## 🟡 Étape 5 — Collection des héros et des monstres (base jouable)

Fait (v0.7.0) :
- 12 héros (Guerrier, Gardien, Assassin, Mage, Prêtre, Archer, Invocateur, Contrôleur, Berserker, Support ; Commun à Légendaire) et 10 créatures (terrestre, volante, aquatique, magique, végétale, élémentaire, antique), chacun avec modèle 3D articulé, portrait rendu, statistiques, compétences (52 au total) et histoire.
- `CollectionState` : héros (niveau, étoiles, fragments), créatures en plusieurs exemplaires, sauvegarde ; héros et créatures de départ (aussi pour les anciennes sauvegardes).
- Progression : niveau des héros (or, puis cristaux abyssaux à partir du niveau 10), plafond relevé par les étoiles, évolution par fragments ; niveau des créatures avec le nectar.
- Sources : fragments dans les cristaux affleurants, œufs dans les champignons sauvages ; capacité de créatures augmentée par l'Habitat des monstres (désormais constructible).
- Écran Collection : cartes par rareté, filtres, silhouettes des personnages non découverts, fiche avec vitrine 3D orientable, annonces de découverte.

Reste à faire :
- Monter progressivement jusqu'à 150 héros et 120 créatures (les outils de modélisation et la chaîne de données sont prêts : un script Blender et un fichier .tres par personnage).
- Équipements, talents et arbres de compétences, variantes visuelles (étape 9).
- Créatures visibles dans leur Habitat.

## ✅ Étape 6 — Laboratoire et Fusionnerie

- `IngredientData` (12 ingrédients), `Inventory`, `LabRules` (poids par rareté × affinités génétiques × élément × bonus de rareté, normalisés ; jamais de garantie), `LaboratoryState` (emplacements 2 → 4, coût, durée, résultat tiré au lancement, accélération, synthèse).
- `FusionRules` : recettes secrètes (`data/fusion`), sinon espèce apparentée (tags génétiques communs), 25 % de chances de rareté supérieure, 12 % de mutation ; recettes découvertes mémorisées.
- Sources : Habitat des monstres (Essence vitale), trouvailles des ressources sauvages (ingrédients), synthèse.
- Écrans Laboratoire et Fusionnerie, `RevealOverlay`.

## ✅ Étape 7 — Invocation et dieux

- `SummonBannerData` (5 bannières), `SummonRules` : taux par rareté redistribués si une rareté est vide, garantie Épique, doublons → fragments, élément du jour, Éveil divin (fragments 10-20, 5 % d'éveil complet).
- Trois dieux (Kryos, Vitalia, Pyros) modélisés avec auréoles et ailes ; Éclats antiques et Poussière divine obtenus dans les ressources sauvages et en récompense de chaque niveau du Temple.

## ⏳ Étapes suivantes

| Étape | Contenu | Fondations déjà en place |
|---|---|---|
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
