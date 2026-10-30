# HIGHVALE

**Super Essence Studio** — jeu mobile de construction, gestion, collection et stratégie au tour par tour.
Godot 4 (GDScript), rendu « Mobile », 2.5D isométrique, cible Android (APK).

Le joueur bâtit une civilisation souterraine autour du Temple Primordial, dans une caverne gigantesque, après la Fracture Primordiale.

## État actuel (v0.3.0)

| Étape | Contenu | État |
|---|---|---|
| 1 | Architecture du projet Godot | ✅ terminée |
| 2 | Cité isométrique jouable | ✅ terminée |
| 3 | Bâtiments et économie | 🟡 base jouable (voir [la feuille de route](docs/FEUILLE_DE_ROUTE.md)) |
| 4 → 12 | Population, collections, laboratoire, invocation, combat… | ⏳ à venir |

**Ce qui est jouable et testé :**

- Écran du studio, puis logo HIGHVALE avec chargement réel ; menu principal avec la cité du joueur en 3D en arrière-plan.
- Grande caverne 3D : falaises, cristaux lumineux pulsants, champignons géants, ruines, cascade et bassin animés, spores flottantes.
- Caméra isométrique : glisser avec inertie, pincer ou molette pour zoomer.
- 21 bâtiments définis par des données, chacun avec un modèle 3D procédural distinct qui s'enrichit aux niveaux 3, 5 et 7.
- Construction : menu par catégories avec vignettes 3D, aperçu translucide vert ou rouge, déplacement au doigt, validation.
- Chantiers en temps réel (y compris hors ligne) : bâtisseurs limités, accélération en Prismes (monnaie premium), annulation avec remboursement de 50 %.
- Économie : Or, Pierre, Bois fongique et Cristaux abyssaux produits ; capacités de stockage ; bulles de collecte.
- Le Temple Primordial débloque des bâtiments, relève les niveaux maximum et déclenche les chapitres de l'histoire.
- Les 14 bâtiments des modules futurs (Laboratoire, Sanctuaire, Arène…) sont visibles mais verrouillés (« Prochainement »).
- Sauvegarde automatique, écriture atomique avec copie de secours, sauvegarde à la mise en pause Android.
- Paramètres : ombres, compteur d'images par seconde, limite d'images par seconde, réinitialisation de la partie. Le bouton Retour Android est géré.

## Ouvrir le projet

1. Installer **Godot 4.3** ou une version plus récente (version standard, pas .NET).
2. Ouvrir `project.godot`, puis lancer le projet avec F5.

Sur ordinateur, la souris simule le toucher : clic = toucher, glisser = déplacer la caméra, molette = zoom.

## Tests

```bash
# Tests logiques : économie, cité, sauvegarde, données, modèles
godot --headless res://tests/test_runner.tscn

# Visite visuelle automatique avec captures et vérification des entrées tactiles
xvfb-run godot --rendering-method gl_compatibility res://tests/visual_tour.tscn -- /chemin/captures
```

## Export Android (APK)

Le préréglage « Android » est inclus (`export_presets.cfg`) : paquet `com.superessence.highvale`, arm64-v8a, icônes adaptatives, mode immersif paysage.

1. *Éditeur → Gérer les modèles d'export* : installer les modèles de la version de Godot utilisée.
2. *Éditeur → Paramètres de l'éditeur → Export → Android* : renseigner le SDK Android, le JDK 17 et le keystore de débogage.
3. *Projet → Exporter… → Android → Exporter le projet* → `build/HIGHVALE.apk`.

> L'export APK n'a pas encore été exécuté : l'environnement de développement ne dispose ni du SDK Android ni des modèles d'export. Il est prévu à l'étape 12, avec des tests sur téléphone.

## Documentation

- [Architecture](docs/ARCHITECTURE.md) : modules, flux de données, ajout de contenu.
- [Feuille de route](docs/FEUILLE_DE_ROUTE.md) : les 12 étapes, l'état et la suite.

## Crédits

- Développement : Super Essence Studio
- Moteur : [Godot Engine](https://godotengine.org) (MIT)
- Polices : Lilita One et Fredoka, licence SIL Open Font (voir `assets/fonts/`)
