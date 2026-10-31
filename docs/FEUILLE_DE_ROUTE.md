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

## ✅ Étape 8 — Combat au tour par tour

- `BattleState` (moteur sans affichage, testé), `Combatant`, `BattleAI`, `EncounterData` (10 défis, 2 boss), `BattleSetup` (préparation, bonus de la Caserne, récompenses).
- `BattleScene` : arène 3D, déplacements de mêlée, projectiles élémentaires, ondes de choc, boucliers, chiffres flottants, caméra cinématique des ultimes, tremblements, ordre des tours, synergies, modes manuel/auto, vitesse ×1-×3, fin de combat.
- Écran « Défis des profondeurs » : défis, puissance comparée, récompenses, composition de l'équipe.

## ✅ Étape 9 — Progression et exploration (base complète)

- Équipements (`ItemData`, 12 objets, `ForgeRules`, écran Forge), talents (3 paliers × 2 choix), bonus appliqués en combat.
- Boss à phases dans `BattleState`.
- `ZoneData` (8 zones : 5 profondeurs, 3 surface), `ExplorationState` (progression, déblocage, récompenses, expéditions), arène thématique (couleurs, décors de surface : sapins et feuillus modélisés).
- Écran Exploration (profondeurs, surface, expéditions) ; Tour des explorateurs et Portail antique l'ouvrent.

Reste à faire : créatures et héros propres à la surface, bâtiments spécifiques de la surface, événements de zone, variantes visuelles des personnages, Infirmerie (blessures).

## ✅ Étape 10 — Boutique et événements

- `QuestState` : missions quotidiennes (tirage stable par jour) et hebdomadaires, suivi par `Events.action_done`, connexion sur 7 jours, passe saisonnier (XP des missions, 20 paliers).
- `ShopState` : offres du jour, packs de ressources, coffres ; `EventCalendar` : 4 événements hebdomadaires (bonus de récompenses, boss quotidien).
- Écrans Missions et Boutique ; indicateur de récompense disponible.
- Non intégré : achats en argent réel (Google Play Billing, nécessite le compte développeur du studio), classements en ligne (serveur requis).

## ✅ Étape 11 — Graphismes, animations, effets et son

- Passe de détail sur les 76 modèles : arêtes arrondies, éclairage peint dans les couleurs de sommets, herbes et cailloux au pied des socles, visages expressifs (yeux, reflets, joues, sourire).
- Bande-son originale (`tools/audio/make_audio.py`) et `AudioManager` ; effets de particules `Fx`.

## ✅ Étape 12 — Optimisation, tests et export

- Décors : maillages importés conservés (niveaux de détail), MultiMesh par zones de 16 cases, pas d'ombre pour les falaises, rochers et arbres ; falaises d'arrière-plan allégées. Cité : 1,6 million → 130 000 triangles.
- Qualité graphique réglable (Économie, Équilibrée, Élevée).
- 57 tests automatisés, visites visuelles (cité, combat, interface), sonde de performances.
- APK Android signé (clé de débogage) via `tools/build_apk.sh`.

Reste au studio : essais sur plusieurs téléphones, clé de publication et fiche Play Store, achats intégrés (Google Play Billing), contenu jusqu'à 150 héros et 120 créatures, créatures et bâtiments propres à la surface.

## ✅ v0.13.0 — Contenu, Infirmerie et Recherches

- 9 nouveaux héros (Aria, Sol, Thalia, Korin, Mira, Ezra, Draven, Luma, Orin) et 8 nouvelles créatures (Loup des plaines, Aigle tempête, Sylphe du vent, Colosse d'Aurore, Sylvain ancien, Crabe des marées, Phénix d'aurore, Serpent du Néant), modélisés dans Blender avec portraits, compétences et histoire.
- Héros de surface (`requires_temple`) absents des invocations et des cristaux avant le Temple 5.
- Plaines du Renouveau, Ruines d'Aurore, Pics tempétueux, Lacs abyssaux et Abîme du Néant peuplés de leurs propres créatures et gardiens.
- Infirmerie : blessures des héros K.O., écran de soins, équipe filtrée, lancement de combat refusé si toute l'équipe est blessée.
- Recherches (`src/research/research_state.gd`) : 4 technologies de cité à la Bibliothèque, 4 technologies de héros à l'Académie. Tous les bâtiments ont désormais un module livré.
- 60 tests automatisés.

## ✅ v0.14.0 — Bâtiments de la surface et du minerai

- Fosse de minerai sombre (Temple 3) : cratère en gradins, filons luisants, grue à benne animée, fonderie ; seule source régulière de minerai sombre.
- Puits de lumière (Temple 5) : colonne de soleil translucide, miroirs dorés orientables ; produit l'Essence vitale et apporte du bien-être.
- Ascenseur de surface (Temple 5) : tour de charpente, cabine et contrepoids animés ; +1 équipe d'exploration, expéditions −6 % par niveau.
- Fragments de héros de surface réservés aux zones de surface ; carte « recherche en cours » corrigée dans la Bibliothèque.
- 61 tests automatisés.

## ✅ v0.15.0 — Les 150 héros

- 126 nouveaux héros (25 Communs, 49 Rares, 33 Épiques, 19 Légendaires), tous les couples classe/élément représentés, 21 venus de la surface (Temple 5).
- Kit de modélisation enrichi : chapeaux (mage, sorcière, bandana, béret, large bord, casque à cornes, diadème, fleur), oreilles d'elfe et de bête, cornes, ailes, queues, écharpes, lunettes, masques, sacoches, 5 nouvelles coiffures et 15 nouvelles armes (lance, trident, masse, arbalète, luth, lanterne, griffes, fouet, katana, pioche, baguette, orbe, éventail, chakram, gantelet).
- Générateur de données versionné (`tools/data/`) : statistiques et compétences dérivées de la classe, de l'élément et de la rareté ; 34 héros supplémentaires écrits et gardés en réserve.
- Modèles 3D chargés à la demande (`model_path`) et portraits compressés pour la mémoire des téléphones.
- Les fragments des héros de surface ne sortent plus des défis, de la boutique ni des zones souterraines.

## ✅ v0.16.0 — Les 120 créatures

- 100 nouvelles créatures (25 Communes, 34 Rares, 26 Épiques, 15 Légendaires) dans les 7 catégories, dont 27 de la surface (Temple 5) ; 17 de plus écrites et gardées en réserve.
- Kit Blender `_beast.py` : 14 plans de corps (gelée, quadrupède, drake, oiseau, serpent, insecte, golem, esprit, plante, poisson, crustacé, batracien, méduse, brute) et 15 ornements (cristaux, piquants, flammes, mousse, champignons, cornes, bois, couronne, auréole, carapace, runes, feuilles…).
- Compétences dérivées du plan de corps, de la catégorie et de l'élément.
- Laboratoire : chances par rareté indépendantes du nombre d'espèces ; créatures de surface disponibles au Temple 5 (aussi pour les fusions et les œufs sauvages).
- Les créatures de surface, jusque-là impossibles à obtenir, sortent maintenant du Laboratoire et des zones.
- Exploration : chaque zone compte 7 à 10 espèces ; une victoire peut faire rejoindre une créature de la zone (25 à 50 % selon l'étape, s'il reste de la place).

## ⏳ Étapes suivantes

| Étape | Contenu | Fondations déjà en place |
|---|---|---|
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
