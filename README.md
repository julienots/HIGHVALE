# HIGHVALE

**Super Essence Studio** — jeu mobile de construction, gestion, collection et stratégie au tour par tour.
Godot 4 (GDScript), rendu « Mobile », 2.5D isométrique, cible Android (APK).

Le joueur bâtit une civilisation souterraine autour du Temple Primordial, dans une caverne gigantesque, après la Fracture Primordiale.

## État actuel (v0.18.0)

| Étape | Contenu | État |
|---|---|---|
| 1 | Architecture du projet Godot | ✅ terminée |
| 2 | Cité isométrique jouable | ✅ terminée |
| 3 | Bâtiments et économie | ✅ les 33 bâtiments sont fonctionnels (dont 4 défenses et les remparts) |
| 4 | Population et vie de la cité | ✅ terminée |
| 5 | Collection des héros et des monstres | ✅ 150 héros et 120 créatures |
| 6 | Laboratoire et Fusionnerie | ✅ terminée |
| 7 | Invocation et dieux | ✅ terminée |
| 8 | Combat au tour par tour | ✅ terminée |
| 9 | Progression, exploration et surface | ✅ base complète |
| 10 | Boutique et événements | ✅ terminée (sans paiement réel) |
| 11 | Graphismes, animations, effets, son | ✅ terminée |
| 12 | Optimisation, tests, export APK | ✅ terminée (tests sur téléphone à faire par le studio) |

**Ce qui est jouable et testé :**

- Écran du studio, puis logo HIGHVALE avec chargement réel ; menu principal avec la cité du joueur en 3D en arrière-plan.
- Grande caverne 3D : falaises en strates, cristaux lumineux pulsants, bosquets de champignons géants, stalagmites, ruines antiques, cascade et bassin animés, spores flottantes. Les décors sont des modèles glTF instanciés par MultiMesh.
- **Habitants** : la population augmente tant qu'il reste des logements, y compris jeu fermé. Les habitants sont affectés aux postes de production ; un bâtiment produit à 25 % sans ouvrier et à 100 % avec tous ses postes pourvus. Le joueur règle le nombre d'ouvriers avec − / +.
- **Bien-être** : décorations (Fontaine de cristal, Jardin des lueurs, Statue du Fondateur), niveau du Temple et festins payés en Nectar souterrain (produit par la Nectarerie) accélèrent l'arrivée des habitants.
- **Récolte manuelle** : filons de pierre, champignons sauvages et cristaux affleurants apparaissent sur les cases libres (y compris jeu fermé) et se récoltent d'un toucher ; les cristaux peuvent contenir des Prismes.
- **Collection** : 150 héros (les 10 classes et les 10 éléments, de Commun à Divin ; 24 héros de la surface ne s'invoquent qu'à partir du Temple 5) et 120 créatures (14 plans de corps : gelées, bêtes, drakes, oiseaux, serpents, insectes, golems, esprits, plantes, poissons, crustacés, batraciens, méduses, brutes ; celles de la surface n'apparaissent qu'au Temple 5). Une victoire en exploration peut faire rejoindre une créature de la zone, chacun avec son modèle 3D, son portrait, ses statistiques, 2 à 3 compétences et son histoire. Écran de collection avec cartes par rareté, filtres et fiche détaillée (vitrine 3D orientable, statistiques, compétences). Les héros montent de niveau (or, puis cristaux) et évoluent avec des fragments (étoiles), qui relèvent leur niveau maximal ; les créatures se nourrissent de nectar pour grandir. Fragments trouvés dans les cristaux affleurants, œufs parfois cachés dans les champignons sauvages ; l'Habitat des monstres augmente le nombre de créatures hébergées.
- **Laboratoire** : 12 ingrédients aux affinités génétiques ; jusqu'à 4 emplacements selon le niveau ; probabilités affichées (par rareté et par espèce) ; résultat tiré au lancement, révélé à la fin du compte à rebours ; machine animée (liquides, bulles, arcs électriques) ; synthèse d'ingrédients à partir des ressources.
- **Fusionnerie** : deux créatures fusionnées en une espèce apparentée de rareté égale ou supérieure ; recettes secrètes (dont deux créatures exclusives : Gelée de magma, Chimère de cristal) ; mutations rares en variantes dorée, d'ombre ou de cristal.
- **Sanctuaire des héros** : invocations classique, avancée, élémentaire (élément du jour) et légendaire, avec taux affichés, garantie Épique et doublons convertis en fragments. **Autel divin** : éveil des dieux Kryos, Vitalia et Pyros (fragments divins, éveil complet exceptionnel).
- **Révélations** : charge lumineuse, rayons, éclair et présentation 3D, d'autant plus spectaculaires que la rareté est haute.
- **Combat au tour par tour** : arène 3D dans la caverne, équipe de 5 héros et créatures, ordre selon la vitesse, énergie, recharges, avantages élémentaires, critiques, boucliers, états (brûlure, gel, poison, paralysie, étourdissement, affaiblissement, régénération, provocation), synergie élémentaire d'équipe. Mode manuel (choix de la compétence et de la cible) ou automatique, vitesse ×1 à ×3, caméra cinématique pour les ultimes, chiffres de dégâts. IA ennemie à stratégies (équilibrée, agressive, achever les blessés). 10 défis des profondeurs dont 2 boss, avec récompenses ; la Caserne entraîne l'équipe.
- **Progression** : équipements forgés (arme, armure, amulette ; 12 objets) et talents à choisir aux niveaux 10, 20 et 30 ; boss à phases (purification, bouclier, rage à 66 % et 33 %).
- **Exploration** : carte des 5 zones des profondeurs et des 3 régions de la surface (ouvertes au Temple niveau 5), chacune avec 3 combats dont un gardien, ambiance d'arène propre (cristaux, forges, plein jour et forêts à la surface) et butin ; expéditions de héros (1, 4 ou 8 h) depuis la Tour des explorateurs.
- **Nouveaux bâtiments** : Fosse de minerai sombre (produit le minerai sombre des équipements), Puits de lumière (colonne de soleil venue de la surface : Essence vitale et bien-être) et Ascenseur de surface (une équipe d'exploration de plus, expéditions −6 % par niveau).
- **Assauts en temps réel** (bouton « Assaut ») : on attaque une base ennemie générée au hasard (donjon, tours, canons, tours de cristal, balistes, enceintes de remparts, bâtiments à piller). Les héros et créatures de l'équipe deviennent des cartes : 4 en main, la suivante affichée, énergie qui se recharge, zone de déploiement hors de la base. Les unités trouvent leur chemin, brisent les remparts qui les bloquent, les défenses tirent (au sol, dans les airs, en zone), les soigneurs soignent. 1 à 3 étoiles (50 %, donjon, 100 %), butin, trophées et ligues (Bronze → Légende), « Suivant » pour un autre adversaire.
- **Défense de la cité** : les hordes attaquent votre propre cité ; vos tours, canons, tours de cristal, balistes et remparts la défendent, et vous déployez vos héros près du Temple.
- **Défenses et remparts** : Tour d'archers, Canon de pierre (sol), Tour de cristal (zone), Baliste (longue portée) ; remparts posés en chaîne, sans bâtisseur, qui se raccordent à leurs voisins.
- **Boutique** : cadeau gratuit toutes les 4 heures, Pack du Fondateur (une fois), 4 packs de la semaine avec compte à rebours (héros vedette, œuf de créature, équipement, caravane de ressources), offres du jour, 4 coffres avec animation d'ouverture, ressources et packs de prismes (paiement réel non activé dans cette version de test). Bouton bien visible sur l'écran de la cité, avec pastille quand le cadeau est prêt.
- **Musique et sons** : 7 musiques orchestrales originales (thème principal, cité, combat, boss, laboratoire et invocations, boutique, exploration), ambiance sonore de la caverne, jingles (victoire, défaite, niveau, mission, révélations selon la rareté) et 47 effets sonores. Chaque écran a sa musique ; chaque action a son son, y compris un son par élément en combat.
- **Infirmerie** : les héros mis K.O. sont blessés et se reposent (10 min, −8 % par niveau d'Infirmerie) avant de pouvoir recombattre ; soin immédiat en Essence vitale.
- **Recherches** : la Bibliothèque (production, durée des chantiers, stockage, bien-être) et l'Académie (coût d'entraînement des héros, attaque et PV en combat, places de créatures) développent 8 technologies, plafonnées par le niveau du bâtiment.
- **Missions et événements** : 4 missions du jour et 3 de la semaine suivies automatiquement, récompenses de connexion sur 7 jours, passe saisonnier de 20 paliers, événement hebdomadaire tournant (+50 % de récompenses de combat, boss d'événement quotidien).
- **Boutique** : 6 offres du jour renouvelées (ingrédients, fragments, équipements), packs de ressources, coffres d'alchimiste et du héros ; le Marché l'ouvre aussi. Tout s'achète avec les monnaies du jeu : aucun paiement réel n'est intégré.
- **Son** : bande-son originale synthétisée (thème de la cité, thème de combat, jingles) et 13 effets sonores ; volumes réglables.
- **Effets** : gerbes de particules (collecte, niveau atteint, récolte, coups, soins), poussière de chantier, révélations lumineuses.
- **Performances** : décors instanciés par zones avec niveaux de détail, ombres réservées aux objets proches, qualité graphique réglable (résolution 3D, ombres, lueur, particules). Mesures : environ 130 000 triangles et 370 appels de rendu dans la cité, 137 000 triangles en combat (`tests/perf_probe.tscn`).
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

Les héros, créatures et compétences sont générés par `python3 tools/data/gen_collection.py` à partir de données lisibles (`tools/data/hero_roster.py` : nom, titre, histoire, apparence ; statistiques et compétences dérivées de la classe, de l'élément et de la rareté). Le même script écrit les scripts Blender des héros du roster.

La bande-son originale est entièrement synthétisée par `python3 tools/audio/make_audio.py` (numpy, scipy, ffmpeg) : `synth.py` (cordes, cuivres, chœur, harpe, célesta, flûte, cloches, percussions orchestrales, réverbération à convolution, mastering adapté aux haut-parleurs de téléphone), `compose.py` (7 musiques construites autour d'un même thème, ambiance de caverne, jingles) et `sfx.py` (47 effets sonores).

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

## Outils : LocalHub (GitHub local pour Claude)

`tools/localhub-mcp/` est un serveur MCP sans dépendance : dépôts git, tickets, pull requests et versions en local, plus création, build, signature et envoi d’APK. Voir [tools/localhub-mcp/README.md](tools/localhub-mcp/README.md).
