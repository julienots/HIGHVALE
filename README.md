# HIGHVALE

**Super Essence Studio** — jeu mobile de construction, gestion, collection et stratégie au tour par tour.
Godot 4 (GDScript), rendu « Mobile », 2.5D isométrique, cible Android (APK).

Le joueur bâtit une civilisation souterraine autour du Temple Primordial, dans une caverne gigantesque, après la Fracture Primordiale.

## État actuel (v0.9.0)

| Étape | Contenu | État |
|---|---|---|
| 1 | Architecture du projet Godot | ✅ terminée |
| 2 | Cité isométrique jouable | ✅ terminée |
| 3 | Bâtiments et économie | 🟡 base jouable (voir [la feuille de route](docs/FEUILLE_DE_ROUTE.md)) |
| 4 | Population et vie de la cité | ✅ terminée |
| 5 | Collection des héros et des monstres | 🟡 base jouable (15 héros dont 3 dieux, 12 créatures) |
| 6 | Laboratoire et Fusionnerie | ✅ terminée |
| 7 | Invocation et dieux | ✅ terminée |
| 8 | Combat au tour par tour | ✅ terminée |
| 9 → 12 | Progression, exploration et surface, boutique… | ⏳ à venir |

**Ce qui est jouable et testé :**

- Écran du studio, puis logo HIGHVALE avec chargement réel ; menu principal avec la cité du joueur en 3D en arrière-plan.
- Grande caverne 3D : falaises en strates, cristaux lumineux pulsants, bosquets de champignons géants, stalagmites, ruines antiques, cascade et bassin animés, spores flottantes. Les décors sont des modèles glTF instanciés par MultiMesh.
- **Habitants** : la population augmente tant qu'il reste des logements, y compris jeu fermé. Les habitants sont affectés aux postes de production ; un bâtiment produit à 25 % sans ouvrier et à 100 % avec tous ses postes pourvus. Le joueur règle le nombre d'ouvriers avec − / +.
- **Bien-être** : décorations (Fontaine de cristal, Jardin des lueurs, Statue du Fondateur), niveau du Temple et festins payés en Nectar souterrain (produit par la Nectarerie) accélèrent l'arrivée des habitants.
- **Récolte manuelle** : filons de pierre, champignons sauvages et cristaux affleurants apparaissent sur les cases libres (y compris jeu fermé) et se récoltent d'un toucher ; les cristaux peuvent contenir des Prismes.
- **Collection** : 12 héros (les 10 classes, de Commun à Légendaire) et 10 créatures (7 catégories), chacun avec son modèle 3D, son portrait, ses statistiques, 2 à 3 compétences et son histoire. Écran de collection avec cartes par rareté, filtres et fiche détaillée (vitrine 3D orientable, statistiques, compétences). Les héros montent de niveau (or, puis cristaux) et évoluent avec des fragments (étoiles), qui relèvent leur niveau maximal ; les créatures se nourrissent de nectar pour grandir. Fragments trouvés dans les cristaux affleurants, œufs parfois cachés dans les champignons sauvages ; l'Habitat des monstres augmente le nombre de créatures hébergées.
- **Laboratoire** : 12 ingrédients aux affinités génétiques ; jusqu'à 4 emplacements selon le niveau ; probabilités affichées (par rareté et par espèce) ; résultat tiré au lancement, révélé à la fin du compte à rebours ; machine animée (liquides, bulles, arcs électriques) ; synthèse d'ingrédients à partir des ressources.
- **Fusionnerie** : deux créatures fusionnées en une espèce apparentée de rareté égale ou supérieure ; recettes secrètes (dont deux créatures exclusives : Gelée de magma, Chimère de cristal) ; mutations rares en variantes dorée, d'ombre ou de cristal.
- **Sanctuaire des héros** : invocations classique, avancée, élémentaire (élément du jour) et légendaire, avec taux affichés, garantie Épique et doublons convertis en fragments. **Autel divin** : éveil des dieux Kryos, Vitalia et Pyros (fragments divins, éveil complet exceptionnel).
- **Révélations** : charge lumineuse, rayons, éclair et présentation 3D, d'autant plus spectaculaires que la rareté est haute.
- **Combat au tour par tour** : arène 3D dans la caverne, équipe de 5 héros et créatures, ordre selon la vitesse, énergie, recharges, avantages élémentaires, critiques, boucliers, états (brûlure, gel, poison, paralysie, étourdissement, affaiblissement, régénération, provocation), synergie élémentaire d'équipe. Mode manuel (choix de la compétence et de la cible) ou automatique, vitesse ×1 à ×3, caméra cinématique pour les ultimes, chiffres de dégâts. IA ennemie à stratégies (équilibrée, agressive, achever les blessés). 10 défis des profondeurs dont 2 boss, avec récompenses ; la Caserne entraîne l'équipe.
- **Cité vivante** : mineurs, cultivatrices, porteurs, bâtisseurs et flâneurs modélisés en 3D se déplacent sur la grille (A*). Ils travaillent avec leur outil, rapportent leur récolte à l'Entrepôt ou au Temple, et les bâtisseurs martèlent sur les chantiers.
- Caméra isométrique : glisser avec inertie, pincer ou molette pour zoomer.
- **25 bâtiments modélisés en 3D** (fichiers glTF `assets/models/buildings/`, 2 500 à 15 000 faces chacun) : maçonnerie pierre par pierre, toits à tuiles, colombages, fenêtres éclairées, bannières, cristaux taillés, champignons géants. Chaque modèle s'enrichit aux niveaux 3, 5 et 7 et possède des pièces animées (roues, foreuse, cristal flottant, portails) et ses propres lumières.
- Construction : menu par catégories avec vignettes 3D, aperçu translucide vert ou rouge, déplacement au doigt, validation.
- Chantiers en temps réel (y compris hors ligne) : bâtisseurs limités, accélération en Prismes (monnaie premium), annulation avec remboursement de 50 %.
- Économie : Or, Pierre, Bois fongique et Cristaux abyssaux produits ; capacités de stockage ; bulles de collecte.
- Le Temple Primordial débloque des bâtiments, relève les niveaux maximum et déclenche les chapitres de l'histoire.
- Les 14 bâtiments des modules futurs (Laboratoire, Sanctuaire, Arène…) sont visibles mais verrouillés (« Prochainement »).
- Sauvegarde automatique, écriture atomique avec copie de secours, sauvegarde à la mise en pause Android.
- Paramètres : ombres, compteur d'images par seconde, limite d'images par seconde, réinitialisation de la partie. Le bouton Retour Android est géré.

## Modèles 3D

Les modèles sont produits par des scripts Blender versionnés (`tools/blender/`), ce qui permet de les régénérer, de les retoucher dans Blender et de garantir un style cohérent :

Catégories : `models/` (bâtiments), `props/` (décors de la caverne), `characters/` (habitants).

```bash
# Avec Blender 4.2+ installé
blender -b -P tools/blender/build_models.py -- [identifiants…] [--preview dossier --tier 0-3]
# Ou avec le module Python bpy (pip install bpy)
python tools/blender/build_models.py
```

Les fichiers `.glb` générés peuvent être ouverts et retravaillés dans Blender. Les conventions de nommage (paliers de niveau, animations, lumières) sont décrites dans `tools/blender/hv_kit.py`.

## Ouvrir le projet

1. Installer **Godot 4.3** ou une version plus récente (version standard, pas .NET).
2. Ouvrir `project.godot`, puis lancer le projet avec F5.

Sur ordinateur, la souris simule le toucher : clic = toucher, glisser = déplacer la caméra, molette = zoom.

## Tests

```bash
# Tests logiques : économie, cité, population, sauvegarde, données, modèles
# (échoue aussi sur toute erreur de script)
tests/run_tests.sh /chemin/vers/godot

# Visite visuelle automatique avec captures et vérification des entrées tactiles
xvfb-run godot --rendering-method gl_compatibility res://tests/visual_tour.tscn -- /chemin/captures
```

## Export Android (APK)

Le préréglage « Android » est inclus (`export_presets.cfg`) : paquet `com.superessence.highvale`, arm64-v8a, icônes adaptatives, mode immersif paysage.

1. *Éditeur → Gérer les modèles d'export* : installer les modèles de la version de Godot utilisée.
2. *Éditeur → Paramètres de l'éditeur → Export → Android* : renseigner le SDK Android, le JDK 17 et le keystore de débogage.
3. *Projet → Exporter… → Android → Exporter le projet* → `build/HIGHVALE.apk`.

Ou en une commande : `tools/build_apk.sh /chemin/vers/godot debug`.

> L'APK de test est généré et signé avec une clé de débogage (installation manuelle). Les essais sur téléphone restent à faire ; une clé de publication propre au studio sera nécessaire pour le Play Store.

## Documentation

- [Architecture](docs/ARCHITECTURE.md) : modules, flux de données, ajout de contenu.
- [Feuille de route](docs/FEUILLE_DE_ROUTE.md) : les 12 étapes, l'état et la suite.

## Crédits

- Développement : Super Essence Studio
- Moteur : [Godot Engine](https://godotengine.org) (MIT)
- Polices : Lilita One et Fredoka, licence SIL Open Font (voir `assets/fonts/`)
