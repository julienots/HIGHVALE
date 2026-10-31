"""Roster étendu des créatures de HIGHVALE (au-delà des 20 créatures écrites à
la main). Statistiques et compétences dérivées de la catégorie, de l'élément,
de la rareté et du plan de corps (voir gen_collection.py) ; modèle construit par
tools/blender/characters/_beast.py.

M(id, nom, rareté C/R/E/L, élément, catégorie, famille, plan, (c1, c2, c3), yeux,
  ornements, tags génétiques, histoire, surface=False, **options du plan)
"""

MONSTERS = []


def M(mid, name, rar, el, cat, fam, plan, colors, eyes, deco, tags, lore, surface=False, **opts):
    MONSTERS.append(dict(id=mid, name=name, rar={"C": "COMMON", "R": "RARE", "E": "EPIC", "L": "LEGENDARY"}[rar], el=el,
                         cat=cat, fam=fam, plan=plan, colors=colors, eyes=eyes, deco=list(deco), tags=list(tags), lore=lore,
                         surface=surface, opts=opts))


# --- Gelées --------------------------------------------------------------------
M("pink_jelly", "Gelée rose", "C", "WATER", "AQUATIC", "Gelées", "blob", ("slime_pink", "cloth_white", "glow_pink"), "dark", [],
  ["aquatique", "gelee"], "Une gelée douce et collante qui adore les câlins. Ses câlins collent pendant des heures.")
M("royal_jelly", "Gelée royale", "E", "LIGHT", "MAGICAL", "Gelées", "blob", ("slime_gold", "cloth_white", "glow_gold"), "dark", ["crown:gold"],
  ["gelee", "lumineux"], "La reine des gelées porte une couronne qu'elle a avalée par accident. Elle refuse de la rendre.", tall=1.15)
M("ember_jelly", "Gelée de braise", "R", "FIRE", "ELEMENTAL", "Gelées", "blob", ("lava", "fire", "glow_gold"), "dark", ["flame"],
  ["gelee", "igne"], "Elle grésille en permanence et laisse des traces fumantes sur son passage.")
M("void_jelly", "Gelée du Néant", "R", "VOID", "MAGICAL", "Gelées", "blob", ("slime_violet", "void_skin", "glow_violet"), "glow_violet", ["glowspots:glow_violet"],
  ["gelee", "magique"], "On peut voir des étoiles à l'intérieur. Personne ne sait d'où elles viennent.")
M("moss_jelly", "Gelée moussue", "C", "NATURE", "PLANT", "Gelées", "blob", ("slime", "moss", "glow_green"), "dark", ["moss", "mushrooms:mushroom_pink"],
  ["gelee", "fongique"], "Couverte de mousse et de champignons, elle sert de jardin ambulant aux insectes.")
M("crystal_jelly", "Gelée de cristal", "R", "CRYSTAL", "ELEMENTAL", "Gelées", "blob", ("ice", "crystal", "glow_blue"), "dark", ["crystals:crystal"],
  ["gelee", "cristal"], "Son corps se solidifie en cristal quand elle a peur. Elle a souvent peur.")
M("shadow_jelly", "Gelée d'ombre", "C", "SHADOW", "MAGICAL", "Gelées", "blob", ("fur_black", "void_skin", "shadow_glow"), "glow_violet", [],
  ["gelee", "ombre"], "Elle se cache dans les recoins sombres et surprend les mineurs distraits.")

# --- Bêtes terrestres -----------------------------------------------------------
M("ember_fox", "Renard de braise", "R", "FIRE", "TERRESTRIAL", "Bêtes", "quad", ("fur_orange", "fur_white", "fire"), "dark", [],
  ["terrestre", "bete", "igne"], "Sa queue brûle sans jamais se consumer ; il s'en sert de lanterne dans les galeries.", tail="flame", ears="pointy")
M("cave_fox", "Renard des cavernes", "C", "SHADOW", "TERRESTRIAL", "Bêtes", "quad", ("fur_black", "fur_grey", "glow_violet"), "glow_gold", [],
  ["terrestre", "bete", "ombre"], "Ses yeux dorés brillent dans le noir ; il vole les fromages de la cité.", tail="bushy", tailc="fur_grey")
M("snow_fox", "Renard des neiges", "R", "WATER", "TERRESTRIAL", "Bêtes", "quad", ("fur_white", "ice", "glow_blue"), "dark", [],
  ["terrestre", "bete"], "Venu des pics gelés, il souffle un air si froid qu'il givre les armures.", surface=True, tail="bushy", tailc="fur_white")
M("boar", "Sanglier des galeries", "C", "EARTH", "TERRESTRIAL", "Bêtes", "quad", ("fur_brown", "fur_sand", "bone"), "dark", ["horns:bone"],
  ["terrestre", "bete"], "Il charge tout ce qui bouge, y compris son propre reflet.", ears="round", bulk=1.2, snout=0.07, fangs=True)
M("stone_boar", "Sanglier de pierre", "R", "EARTH", "ANCIENT", "Bêtes", "quad", ("rock", "rock_light", "moss"), "glow_gold", ["moss", "spikes:rock_light"],
  ["terrestre", "roche", "antique"], "Mi-bête, mi-rocher, il dort si longtemps que de la mousse pousse sur son dos.", ears="round", bulk=1.3, legs="short")
M("cave_bear", "Ours des cavernes", "R", "EARTH", "TERRESTRIAL", "Bêtes", "quad", ("fur_brown", "fur_sand", "bone"), "dark", [],
  ["terrestre", "bete"], "Un ours énorme qui hiberne dans les galeries désaffectées. Ne le réveillez pas.", ears="round", bulk=1.4, tail="none", snout=0.05)
M("frost_bear", "Ours de givre", "E", "WATER", "TERRESTRIAL", "Bêtes", "quad", ("fur_white", "ice", "crystal"), "glow_blue", ["crystals:ice"],
  ["terrestre", "bete", "cristal"], "Des stalactites de glace poussent sur son dos ; il les secoue comme des javelots.", surface=True, ears="round", bulk=1.45, tail="none")
M("lynx", "Lynx d'ombre", "R", "SHADOW", "TERRESTRIAL", "Félins", "quad", ("fur_violet", "fur_black", "shadow_glow"), "glow_violet", [],
  ["terrestre", "bete", "ombre"], "Il se fond dans l'ombre et n'en sort que pour bondir.", tail="thin", ears="pointy")
M("sun_lion", "Lion solaire", "L", "LIGHT", "TERRESTRIAL", "Félins", "quad", ("scale_gold", "fur_sand", "glow_gold"), "glow_gold", ["halo:glow_gold"],
  ["terrestre", "bete", "lumineux"], "Sa crinière brille comme le soleil levant ; il règne sur les plaines de la surface.",
  surface=True, mane="fur_orange", tail="thin", bulk=1.25, ears="round")
M("crystal_cat", "Chat de cristal", "C", "CRYSTAL", "TERRESTRIAL", "Félins", "quad", ("fur_grey", "fur_white", "crystal"), "crystal", ["crystals:crystal"],
  ["terrestre", "cristal"], "Il ronronne si fort que les cristaux autour de lui se mettent à vibrer.", tail="thin")
M("dune_cat", "Chat des dunes", "C", "EARTH", "TERRESTRIAL", "Félins", "quad", ("fur_sand", "fur_white", "gold"), "dark", [],
  ["terrestre", "bete"], "Venu des déserts de la surface, il a les oreilles plus grandes que la tête.", surface=True, ears="long", tail="thin")
M("moss_deer", "Cerf moussu", "R", "NATURE", "TERRESTRIAL", "Cervidés", "quad", ("fur_brown", "fur_sand", "moss"), "dark", ["antlers:bark", "moss"],
  ["terrestre", "vegetal"], "Des fleurs poussent dans ses bois ; il les offre aux enfants de la cité.", surface=True, ears="pointy", tail="thin")
M("spirit_stag", "Cerf esprit", "L", "LIGHT", "MAGICAL", "Cervidés", "quad", ("ghost", "fur_white", "glow_teal"), "glow_teal", ["antlers:glow_teal", "glowspots:glow_teal"],
  ["magique", "lumineux", "antique"], "Gardien des forêts anciennes, il n'apparaît qu'à ceux qui ont le cœur pur.", surface=True, tail="thin", light="a8fff2")
M("rabbit", "Lapin des mousses", "C", "NATURE", "TERRESTRIAL", "Rongeurs", "quad", ("fur_white", "fur_sand", "mushroom_pink"), "dark", [],
  ["terrestre", "bete"], "Il mange les mousses lumineuses et brille faiblement la nuit.", ears="long", tail="bushy", tailc="fur_white", legs="short")
M("crystal_mole", "Taupe cristalline", "C", "CRYSTAL", "TERRESTRIAL", "Rongeurs", "quad", ("fur_grey", "skin_pale", "crystal"), "dark", ["crystals:crystal_violet"],
  ["terrestre", "cristal"], "Elle creuse des tunnels parfaits et laisse des éclats de cristal derrière elle.", ears="none", legs="short", snout=0.06)
M("ore_rat", "Rat des minerais", "C", "VOID", "TERRESTRIAL", "Rongeurs", "quad", ("fur_grey", "skin_pale", "glow_violet"), "glow_violet", ["glowspots:glow_violet"],
  ["terrestre", "ombre"], "Il se nourrit de minerai sombre ; ses yeux brillent comme le Néant.", ears="round", tail="thin", legs="short")
M("armadillo", "Tatou blindé", "R", "EARTH", "TERRESTRIAL", "Carapaces", "quad", ("fur_sand", "skin_pale", "bone"), "dark", ["shell:rock_light"],
  ["terrestre", "carapace"], "Il se roule en boule et rebondit sur ses ennemis.", ears="round", legs="short", tail="thin")
M("tortoise", "Tortue des sources", "C", "WATER", "AQUATIC", "Carapaces", "quad", ("scale_green", "scale_belly", "moss"), "dark", ["shell:shell_teal", "moss"],
  ["aquatique", "carapace"], "Elle a vu passer trois générations de fondateurs et n'est toujours pas pressée.", ears="none", legs="short", tail="thin")
M("isle_turtle", "Tortue-île", "L", "EARTH", "ANCIENT", "Carapaces", "quad", ("scale_green", "scale_belly", "leaf"), "glow_gold", ["shell:rock", "moss", "mushrooms:mushroom_teal", "crystals:crystal_teal"],
  ["antique", "carapace", "vegetal"], "Un écosystème entier vit sur sa carapace. Elle porte une forêt et ne s'en plaint jamais.", ears="none", legs="short", bulk=1.5, tail="thin")

# --- Drakes et dragons ------------------------------------------------------------
M("moss_drake", "Drake moussu", "R", "NATURE", "ANCIENT", "Dragons", "drake", ("scale_green", "scale_belly", "bark"), "glow_gold", ["moss", "leaves:leaf"],
  ["dragon", "vegetal"], "Un petit dragon qui préfère manger des champignons que des chevaliers.", tail="long", ears="fins", wingc="leaf")
M("frost_drake", "Drake de givre", "E", "WATER", "ANCIENT", "Dragons", "drake", ("scale_blue", "ice", "crystal"), "glow_blue", ["crystals:ice"],
  ["dragon", "cristal"], "Son souffle gèle les lacs souterrains en une seconde.", tail="long", ears="fins", wingc="ice", fangs=True)
M("storm_drake", "Drake d'orage", "E", "AIR", "FLYING", "Dragons", "drake", ("scale_blue", "fur_white", "glow_gold"), "glow_gold", ["spikes:glow_gold"],
  ["dragon", "volant", "tempete"], "Il chevauche les orages des Pics et crache des éclairs.", surface=True, tail="long", wingc="feather_blue", fangs=True)
M("shadow_wyrm", "Wyrm d'ombre", "L", "SHADOW", "ANCIENT", "Dragons", "drake", ("fur_black", "void_skin", "shadow_glow"), "shadow_glow", ["spikes:shadow_glow", "runes:shadow_glow"],
  ["dragon", "ombre", "antique"], "Le plus ancien dragon des profondeurs ; il dort sur un trésor de cristaux noirs.", tail="long", wingc="membrane", fangs=True, bulk=1.3)
M("gold_dragon", "Dragon d'or", "L", "LIGHT", "ANCIENT", "Dragons", "drake", ("scale_gold", "scale_belly", "gold"), "glow_gold", ["crown:gold", "spikes:gold"],
  ["dragon", "lumineux", "antique"], "Le dragon des rois d'Aurore. Ses écailles valent plus que toute la Trésorerie.", surface=True, tail="long", wingc="gold", bulk=1.3)
M("lava_drake", "Drake de lave", "E", "FIRE", "ELEMENTAL", "Dragons", "drake", ("scale_red", "lava", "fire"), "fire", ["flame", "spikes:lava"],
  ["dragon", "igne"], "Il nage dans la lave comme d'autres dans l'eau.", tail="long", wingc="membrane", fangs=True)
M("crystal_wyvern", "Vouivre de cristal", "E", "CRYSTAL", "FLYING", "Dragons", "drake", ("crystal", "ice", "crystal_violet"), "crystal", ["crystals:crystal_violet"],
  ["dragon", "cristal", "volant"], "Ses ailes de cristal chantent quand elle vole.", tail="long", wingc="glass")
M("baby_dragon", "Dragonnet rose", "C", "FIRE", "ELEMENTAL", "Dragons", "drake", ("slime_pink", "scale_belly", "fire"), "dark", [],
  ["dragon", "igne"], "Il crache de petites flammèches en éternuant. C'est adorable, sauf pour les rideaux.", tail="thin", ears="round", wingc="membrane")

# --- Oiseaux ----------------------------------------------------------------------
M("cave_owl", "Hibou des cavernes", "C", "SHADOW", "FLYING", "Rapaces", "bird", ("fur_brown", "fur_sand", "gold"), "glow_gold", [],
  ["volant", "ombre"], "Il veille sur les galeries la nuit et hulule quand un intrus approche.")
M("fire_finch", "Pinson de feu", "C", "FIRE", "FLYING", "Passereaux", "bird", ("feather_red", "fur_orange", "gold"), "dark", ["flame"],
  ["volant", "igne"], "Son chant réchauffe les forges froides le matin.", crest="fire", tail="fan")
M("sky_heron", "Héron céleste", "R", "AIR", "FLYING", "Échassiers", "bird", ("feather_white", "feather_blue", "gold"), "dark", [],
  ["volant", "tempete"], "Il pêche dans les nuages des Pics avec son long bec.", surface=True, legs="long", crest="feather_blue", tail="long")
M("crystal_raven", "Corbeau de cristal", "R", "CRYSTAL", "FLYING", "Corvidés", "bird", ("feather_black", "crystal_violet", "crystal"), "crystal", ["crystals:crystal_violet"],
  ["volant", "cristal"], "Il collectionne tout ce qui brille, surtout les cristaux de la cité.")
M("thunder_bird", "Oiseau-tonnerre", "L", "AIR", "FLYING", "Rapaces", "bird", ("feather_blue", "feather_white", "gold"), "glow_gold", ["crown:glow_gold"],
  ["volant", "tempete", "antique"], "Chaque battement de ses ailes fait gronder le tonnerre sur les Pics.", surface=True, crest="glow_gold", tail="fan")
M("dusk_parrot", "Perroquet du crépuscule", "C", "NATURE", "FLYING", "Psittacidés", "bird", ("leaf", "feather_red", "gold"), "dark", [],
  ["volant", "vegetal"], "Il répète tous les sorts qu'il entend. Heureusement, sans la magie.", crest="feather_red", tail="long")
M("void_crow", "Corneille du Néant", "R", "VOID", "FLYING", "Corvidés", "bird", ("void_skin", "feather_black", "glow_violet"), "glow_violet", ["glowspots:glow_violet"],
  ["volant", "ombre", "magique"], "Elle annonce les failles du Néant avant qu'elles ne s'ouvrent.")
M("dawn_swan", "Cygne d'aurore", "E", "LIGHT", "FLYING", "Cygnes", "bird", ("feather_white", "fur_white", "gold"), "dark", ["halo:glow_gold"],
  ["volant", "lumineux"], "Son plumage reflète la lumière du soleil levant ; il guérit d'un battement d'ailes.", surface=True, tail="fan")
M("glow_moth_bird", "Colibri lumineux", "C", "LIGHT", "FLYING", "Colibris", "bird", ("glow_teal", "feather_blue", "gold"), "dark", [],
  ["volant", "lumineux"], "Il butine les fleurs de cristal et laisse une traînée de lumière.", tail="long")
M("roc", "Roc géant", "E", "EARTH", "FLYING", "Rapaces", "bird", ("fur_brown", "feather_white", "bone"), "glow_gold", ["horns:bone"],
  ["volant", "antique", "roche"], "Un rapace si grand qu'il peut emporter un wagonnet entier.", surface=True, crest="fur_brown", tail="fan")

# --- Serpents et reptiles ------------------------------------------------------------
M("sand_viper", "Vipère des sables", "C", "EARTH", "TERRESTRIAL", "Serpents", "serpent", ("fur_sand", "scale_belly", "cloth_red"), "dark", [],
  ["terrestre", "reptile"], "Elle se cache sous le sable et mord les chevilles distraites.", surface=True, fangs=True)
M("cobra_king", "Cobra royal", "E", "LIGHT", "MAGICAL", "Serpents", "serpent", ("scale_gold", "scale_belly", "cloth_red"), "glow_gold", ["crown:gold"],
  ["reptile", "magique", "lumineux"], "Le cobra des temples d'Aurore ; son regard hypnotise les ennemis.", surface=True, hood=True, fangs=True)
M("moss_snake", "Couleuvre moussue", "C", "NATURE", "PLANT", "Serpents", "serpent", ("scale_green", "scale_belly", "leaf"), "dark", ["leaves:leaf"],
  ["reptile", "vegetal"], "On la confond avec une liane jusqu'à ce qu'elle bouge.")
M("frost_naga", "Naga de givre", "E", "WATER", "AQUATIC", "Serpents", "serpent", ("scale_blue", "ice", "crystal"), "crystal", ["crystals:ice"],
  ["reptile", "aquatique", "cristal"], "Elle garde les grottes gelées sous les lacs.", hood=True, fins=True)
M("lava_serpent", "Serpent de lave", "R", "FIRE", "ELEMENTAL", "Serpents", "serpent", ("lava", "fire", "scale_red"), "fire", ["flame"],
  ["reptile", "igne"], "Il nage dans les rivières de lave sous la forge.", fangs=True)
M("sea_dragon", "Dragon des mers", "L", "WATER", "AQUATIC", "Serpents", "serpent", ("scale_blue", "scale_belly", "shell_teal"), "glow_teal", ["spikes:shell_teal", "horns:bone"],
  ["aquatique", "dragon", "antique"], "Le maître des lacs abyssaux ; ses vagues peuvent engloutir une île.", segments=9, fins=True, fangs=True)
M("crystal_wurm", "Ver de cristal", "R", "CRYSTAL", "TERRESTRIAL", "Vers", "serpent", ("crystal", "ice", "crystal_violet"), "dark", ["crystals:crystal"],
  ["terrestre", "cristal"], "Il digère la roche et rejette des cristaux parfaits.", segments=8)
M("gecko", "Gecko des parois", "C", "NATURE", "TERRESTRIAL", "Lézards", "quad", ("scale_green", "scale_belly", "glow_green"), "dark", ["glowspots:glow_green"],
  ["terrestre", "reptile"], "Il court sur les parois et les plafonds sans jamais tomber.", ears="none", legs="short", tail="long")
M("basilisk", "Basilic", "E", "EARTH", "ANCIENT", "Lézards", "quad", ("scale_green", "rock_light", "gold"), "glow_gold", ["crown:gold", "spikes:rock"],
  ["reptile", "antique", "roche"], "Son regard pétrifie ; les mineurs portent des lunettes noires en le croisant.", ears="none", tail="long", bulk=1.2, fangs=True)

# --- Insectes ---------------------------------------------------------------------
M("glow_beetle", "Scarabée lumineux", "C", "LIGHT", "TERRESTRIAL", "Insectes", "insect", ("scale_gold", "dark", "glow_gold"), "dark", ["glowspots:glow_gold"],
  ["terrestre", "lumineux", "carapace"], "Les habitants le gardent dans des bocaux pour éclairer leurs maisons.")
M("crystal_mantis", "Mante de cristal", "E", "CRYSTAL", "TERRESTRIAL", "Insectes", "insect", ("crystal", "ice", "crystal_violet"), "crystal", ["crystals:crystal"],
  ["cristal", "carapace"], "Ses pattes avant tranchent le cristal comme du beurre.", wings="glass")
M("lava_ant", "Fourmi de lave", "C", "FIRE", "TERRESTRIAL", "Insectes", "insect", ("scale_red", "fur_black", "fire"), "dark", [],
  ["terrestre", "igne", "carapace"], "Une colonie de fourmis de lave peut creuser une galerie en une nuit.")
M("dragonfly", "Libellule des sources", "C", "WATER", "FLYING", "Insectes", "insect", ("shell_teal", "eel_blue", "glow_teal"), "dark", [],
  ["volant", "aquatique"], "Elle survole les lacs souterrains en laissant des ronds sur l'eau.", wings="glass")
M("storm_wasp", "Guêpe d'orage", "R", "AIR", "FLYING", "Insectes", "insect", ("scale_gold", "fur_black", "glow_gold"), "dark", [],
  ["volant", "tempete"], "Sa piqûre envoie une décharge électrique.", surface=True, wings="glass", stinger=True)
M("scorpion", "Scorpion des sables", "R", "EARTH", "TERRESTRIAL", "Arachnides", "insect", ("fur_sand", "scale_red", "dark"), "dark", [],
  ["terrestre", "carapace"], "Il dort sous le sable brûlant de la surface et pique tout ce qui le réveille.", surface=True, stinger=True)
M("void_spider", "Araignée du Néant", "R", "VOID", "MAGICAL", "Arachnides", "insect", ("void_skin", "fur_black", "glow_violet"), "glow_violet", ["glowspots:glow_violet"],
  ["ombre", "magique"], "Ses toiles relient des points éloignés de la caverne.")
M("queen_bee", "Reine des abeilles", "E", "NATURE", "FLYING", "Insectes", "insect", ("scale_gold", "fur_black", "gold"), "dark", ["crown:gold"],
  ["volant", "vegetal"], "Elle produit un nectar si pur qu'il guérit les blessures.", wings="glass", stinger=True)
M("moth", "Phalène de lune", "C", "SHADOW", "FLYING", "Insectes", "insect", ("fur_violet", "fur_white", "glow_violet"), "dark", [],
  ["volant", "ombre"], "Attirée par les lanternes, elle danse autour toute la nuit.", wings="glow_violet")
M("titan_beetle", "Scarabée titan", "L", "EARTH", "ANCIENT", "Insectes", "insect", ("chitin_blue", "fur_black", "gold"), "glow_gold", ["horn:gold", "spikes:gold"],
  ["antique", "carapace", "roche"], "Le plus grand scarabée connu ; il porte des rochers comme des cailloux.")

# --- Golems et créatures de pierre ----------------------------------------------------
M("pebble_golem", "Golem de galets", "C", "EARTH", "ANCIENT", "Golems", "golem", ("rock_light", "rock", "glow_gold"), "glow_gold", ["moss"],
  ["roche", "antique"], "Un petit golem assemblé avec des galets de rivière. Il adore les cailloux plats.")
M("iron_golem", "Golem de fer", "R", "NEUTRAL", "ANCIENT", "Golems", "golem", ("iron", "steel_dark", "fire"), "fire", ["smoke:stone"],
  ["antique", "roche"], "Construit par les forgerons de la cité, il fume quand il réfléchit.")
M("ice_golem", "Golem de glace", "R", "WATER", "ELEMENTAL", "Golems", "golem", ("ice", "crystal", "glow_blue"), "glow_blue", ["crystals:ice"],
  ["cristal", "antique"], "Il fond un peu en été, mais à la surface, il n'y a pas d'été.")
M("lava_golem", "Golem de lave", "E", "FIRE", "ELEMENTAL", "Golems", "golem", ("rock", "lava", "fire"), "fire", ["flame"],
  ["igne", "roche"], "Une coquille de roche autour d'un cœur de lave ; il réchauffe les nuits de la cité.")
M("moss_golem", "Golem moussu", "C", "NATURE", "PLANT", "Golems", "golem", ("rock", "moss", "glow_green"), "glow_green", ["moss", "mushrooms:mushroom_teal"],
  ["roche", "vegetal"], "Couvert de mousse, il passe pour un rocher… jusqu'à ce qu'il se lève.")
M("obsidian_golem", "Golem d'obsidienne", "E", "SHADOW", "ANCIENT", "Golems", "golem", ("fur_black", "void_skin", "shadow_glow"), "shadow_glow", ["runes:shadow_glow"],
  ["antique", "ombre", "roche"], "Taillé dans le verre volcanique ; ses runes violettes brillent quand il combat.")
M("colossus", "Colosse runique", "L", "CRYSTAL", "ANCIENT", "Golems", "golem", ("marble", "gold", "rune"), "rune", ["runes:rune", "crown:gold"],
  ["antique", "cristal", "magique"], "Gardien des premiers fondateurs, il se réveille quand la cité est en danger.")
M("brick_golem", "Golem de briques", "C", "FIRE", "ANCIENT", "Golems", "golem", ("cloth_red", "stone", "fire"), "glow_gold", [],
  ["roche", "antique"], "Construit avec les briques d'une vieille forge, il sent encore la suie.")

# --- Esprits et fantômes ----------------------------------------------------------------
M("ghostling", "Fantômet", "C", "SHADOW", "MAGICAL", "Fantômes", "spirit", ("ghost", "ghost", "glow_violet"), "dark", [],
  ["magique", "ombre"], "Un petit fantôme timide qui aime faire peur… puis s'excuse.", kind="ghost")
M("will_o_wisp", "Feu des marais", "C", "FIRE", "ELEMENTAL", "Esprits", "spirit", ("fire", "lava", "glow_gold"), "dark", [],
  ["magique", "igne"], "Il égare les voyageurs dans les marais de la surface. Par jeu, dit-il.", surface=True, kind="flame", light="ffa040")
M("frost_wisp", "Feu de givre", "R", "WATER", "ELEMENTAL", "Esprits", "spirit", ("glow_blue", "ice", "glow_blue"), "dark", [],
  ["magique", "cristal"], "Une flamme bleue et glacée qui flotte au-dessus des lacs gelés.", kind="flame", light="8ac8ff")
M("banshee", "Banshee", "E", "VOID", "MAGICAL", "Fantômes", "spirit", ("ghost", "glow_violet", "glow_violet"), "glow_violet", ["crown:steel_dark"],
  ["magique", "ombre"], "Son cri glace le sang et fige les ennemis sur place.", kind="ghost", light="b49cff")
M("lumen_spirit", "Esprit de lumière", "R", "LIGHT", "MAGICAL", "Esprits", "spirit", ("glow_gold", "glow_gold", "glow_gold"), "dark", ["halo:glow_gold"],
  ["magique", "lumineux"], "Né de la première lumière qui a traversé la Fracture.", kind="wisp")
M("storm_spirit", "Esprit d'orage", "E", "AIR", "ELEMENTAL", "Esprits", "spirit", ("glow_blue", "fur_white", "glow_gold"), "dark", [],
  ["magique", "tempete"], "Un nuage vivant chargé d'électricité.", surface=True, kind="wisp", light="c8d8ff")
M("ancestor", "Esprit ancestral", "L", "LIGHT", "ANCIENT", "Fantômes", "spirit", ("ghost", "glow_teal", "gold"), "glow_teal", ["crown:gold", "halo:glow_teal"],
  ["antique", "magique", "lumineux"], "L'esprit du premier fondateur de HIGHVALE veille encore sur sa cité.", kind="ghost", light="a8fff2")
M("nature_wisp", "Feu sylvestre", "C", "NATURE", "MAGICAL", "Esprits", "spirit", ("glow_green", "leaf", "glow_green"), "dark", ["leaves:leaf"],
  ["magique", "vegetal"], "Une petite lumière verte qui fait pousser les plantes sur son passage.", kind="wisp", light="8aff6a")

# --- Plantes vivantes ---------------------------------------------------------------------
M("bloomling", "Fleuron", "C", "NATURE", "PLANT", "Fleurs", "plant", ("leaf", "mushroom_pink", "glow_gold"), "dark", [],
  ["vegetal"], "Une petite fleur qui marche ; elle suit le soleil, même sous terre.", surface=True, kind="flower")
M("sun_flower", "Tournesol vivant", "R", "LIGHT", "PLANT", "Fleurs", "plant", ("leaf", "scale_gold", "fur_brown"), "dark", [],
  ["vegetal", "lumineux"], "Il concentre la lumière du soleil en rayons brûlants.", surface=True, kind="flower")
M("spore_cap", "Champi-spore", "C", "NATURE", "PLANT", "Champignons", "plant", ("mushroom_stem", "mushroom_teal", "glow_teal"), "dark", [],
  ["vegetal", "fongique"], "Il libère un nuage de spores quand on lui marche dessus.", kind="mushroom")
M("toxic_cap", "Amanite toxique", "R", "VOID", "PLANT", "Champignons", "plant", ("mushroom_stem", "feather_red", "cloth_white"), "dark", [],
  ["vegetal", "fongique", "ombre"], "Très jolie, très venimeuse. Ne la goûtez pas.", kind="mushroom")
M("king_shroom", "Roi des champignons", "E", "NATURE", "PLANT", "Champignons", "plant", ("mushroom_stem", "mushroom_violet", "glow_violet"), "glow_violet", ["crown:gold"],
  ["vegetal", "fongique", "antique"], "Il règne sur toute la forêt fongique ; ses spores font pousser des armées.", kind="mushroom")
M("cactus", "Cactus grognon", "C", "EARTH", "PLANT", "Cactus", "plant", ("scale_green", "mushroom_pink", "cloth_white"), "dark", [],
  ["vegetal"], "Il pique tout le monde, mais c'est pour se protéger.", surface=True, kind="cactus")
M("bulb_beast", "Bulbe dormant", "R", "WATER", "PLANT", "Bulbes", "plant", ("leaf_dark", "slime", "glow_teal"), "dark", [],
  ["vegetal", "aquatique"], "Il boit tant d'eau qu'il gonfle comme un ballon.", kind="bulb")
M("thorn_rose", "Rose épineuse", "E", "SHADOW", "PLANT", "Fleurs", "plant", ("leaf_dark", "feather_red", "fur_black"), "dark", ["spikes:leaf_dark"],
  ["vegetal", "ombre"], "Une rose noire aux épines venimeuses, née sur une tombe oubliée.", kind="flower")
M("world_tree", "Pousse d'Yggdra", "L", "NATURE", "ANCIENT", "Sylvains", "plant", ("bark", "leaf", "glow_gold"), "glow_gold", ["leaves:leaf_autumn", "halo:glow_gold"],
  ["vegetal", "antique", "magique"], "Une graine de l'arbre-monde a germé dans la caverne. Elle grandit encore.", kind="bulb")

# --- Créatures aquatiques ------------------------------------------------------------------
M("lantern_fish", "Poisson-lanterne", "C", "WATER", "AQUATIC", "Poissons", "fish", ("eel_blue", "cloth_white", "glow_gold"), "dark", ["glowspots:glow_gold"],
  ["aquatique", "lumineux"], "Il éclaire les profondeurs avec la lanterne qui pend de son front.")
M("piranha", "Piranha des abysses", "C", "SHADOW", "AQUATIC", "Poissons", "fish", ("fur_grey", "feather_red", "cloth_red"), "dark", ["spikes:cloth_white"],
  ["aquatique", "ombre"], "Petit, mais avec beaucoup, beaucoup de dents.")
M("crystal_carp", "Carpe de cristal", "R", "CRYSTAL", "AQUATIC", "Poissons", "fish", ("crystal", "ice", "crystal_violet"), "dark", ["crystals:crystal"],
  ["aquatique", "cristal"], "On dit qu'elle exauce un vœu à qui la pêche… puis la relâche.")
M("puffer", "Poisson-globe", "C", "NATURE", "AQUATIC", "Poissons", "fish", ("fur_sand", "cloth_white", "leaf"), "dark", ["spikes:fur_sand"],
  ["aquatique"], "Quand il a peur, il gonfle et devient un ballon d'épines.")
M("abyss_ray", "Raie abyssale", "E", "VOID", "AQUATIC", "Raies", "fish", ("void_skin", "fur_black", "glow_violet"), "glow_violet", ["glowspots:glow_violet"],
  ["aquatique", "magique", "ombre"], "Elle glisse dans l'eau noire comme une ombre et paralyse ses proies.")
M("golden_koi", "Koï doré", "L", "LIGHT", "AQUATIC", "Poissons", "fish", ("scale_gold", "cloth_white", "feather_red"), "dark", ["crown:gold"],
  ["aquatique", "lumineux", "antique"], "Le koï sacré du Temple ; il porte chance à toute la cité.")
M("hermit", "Bernard-l'ermite", "C", "WATER", "AQUATIC", "Crustacés", "crab", ("shell_violet", "fur_sand", "shell_red"), "dark", ["shell:shell_violet"],
  ["aquatique", "carapace"], "Il change de coquille chaque saison et passe des heures à choisir.")
M("crystal_crab", "Crabe de cristal", "R", "CRYSTAL", "AQUATIC", "Crustacés", "crab", ("crystal", "ice", "crystal_violet"), "dark", ["crystals:crystal"],
  ["aquatique", "carapace", "cristal"], "Sa carapace de cristal résiste aux pioches.")
M("lava_crab", "Crabe de lave", "R", "FIRE", "ELEMENTAL", "Crustacés", "crab", ("rock", "lava", "lava"), "fire", ["flame"],
  ["igne", "carapace"], "Il vit au bord des coulées de lave et pince avec des pinces brûlantes.")
M("king_crab", "Crabe-roi", "E", "WATER", "AQUATIC", "Crustacés", "crab", ("shell_red", "fur_sand", "shell_red"), "dark", ["crown:gold", "spikes:shell_red"],
  ["aquatique", "carapace", "antique"], "Le plus grand crabe des lacs ; ses pinces peuvent couper une barque en deux.")
M("pond_frog", "Grenouille des mares", "C", "WATER", "AQUATIC", "Batraciens", "frog", ("scale_green", "scale_belly", "leaf"), "dark", [],
  ["aquatique"], "Elle chante toute la nuit au bord des lacs souterrains.")
M("toad_sage", "Crapaud sage", "R", "NATURE", "MAGICAL", "Batraciens", "frog", ("fur_brown", "fur_sand", "moss"), "dark", ["mushrooms:mushroom_pink", "moss"],
  ["magique", "vegetal"], "Un vieux crapaud qui connaît tous les secrets des marais.")
M("poison_frog", "Grenouille venimeuse", "C", "VOID", "AQUATIC", "Batraciens", "frog", ("slime_violet", "fur_black", "glow_violet"), "dark", [],
  ["aquatique", "ombre"], "Ses couleurs vives préviennent : ne la touchez pas.")
M("fire_toad", "Crapaud de feu", "R", "FIRE", "ELEMENTAL", "Batraciens", "frog", ("scale_red", "fur_orange", "fire"), "dark", ["flame"],
  ["igne", "reptile"], "Il gonfle sa gorge et crache des bulles de feu.")
M("moon_jelly", "Méduse de lune", "C", "WATER", "AQUATIC", "Méduses", "jelly", ("glow_blue", "slime", "glow_teal"), "dark", [],
  ["aquatique", "lumineux"], "Elle flotte dans l'air humide des grottes comme dans l'eau.", light="8ac8ff")
M("storm_jelly", "Méduse d'orage", "R", "AIR", "MAGICAL", "Méduses", "jelly", ("glow_gold", "scale_gold", "glow_blue"), "dark", [],
  ["magique", "tempete"], "Ses filaments sont chargés d'électricité ; gare à qui les touche.", surface=True, light="ffe680")
M("abyss_jelly", "Méduse abyssale", "E", "VOID", "AQUATIC", "Méduses", "jelly", ("glow_violet", "slime_violet", "shadow_glow"), "dark", ["crown:steel_dark"],
  ["aquatique", "magique", "ombre"], "Venue des fosses les plus profondes, elle dévore la lumière.", light="b49cff")

# --- Brutes -----------------------------------------------------------------------------
M("yeti", "Yéti", "E", "WATER", "TERRESTRIAL", "Brutes", "brute", ("fur_white", "skin_blue", "ice"), "dark", ["horns:bone"],
  ["terrestre", "bete"], "Il garde les Pics gelés ; ses rugissements déclenchent des avalanches.", surface=True, fangs=True)
M("cave_troll", "Troll des cavernes", "R", "EARTH", "TERRESTRIAL", "Brutes", "brute", ("skin_green", "fur_brown", "moss"), "dark", ["moss"],
  ["terrestre", "roche"], "Lent et bête, mais si solide que les pioches rebondissent sur lui.", fangs=True)
M("magma_ogre", "Ogre de magma", "E", "FIRE", "ELEMENTAL", "Brutes", "brute", ("rock", "lava", "fire"), "fire", ["flame", "horns:rock"],
  ["igne", "roche"], "Ses poings de roche fondue écrasent les ennemis.", fangs=True)
M("gorilla", "Gorille des ruines", "R", "LIGHT", "TERRESTRIAL", "Brutes", "brute", ("fur_black", "fur_grey", "gold"), "dark", ["crown:gold"],
  ["terrestre", "bete", "antique"], "Il protège les Ruines d'Aurore et frappe sa poitrine pour effrayer les pilleurs.", surface=True)
M("shadow_beast", "Bête d'ombre", "L", "SHADOW", "MAGICAL", "Brutes", "brute", ("fur_black", "void_skin", "shadow_glow"), "shadow_glow", ["horns:shadow_glow", "glowspots:shadow_glow"],
  ["ombre", "magique", "antique"], "Une créature née des ténèbres de l'Abîme ; même les dragons l'évitent.", fangs=True)
M("crystal_ape", "Singe de cristal", "C", "CRYSTAL", "TERRESTRIAL", "Brutes", "brute", ("fur_grey", "skin_pale", "crystal"), "dark", ["crystals:crystal"],
  ["terrestre", "cristal"], "Il grimpe aux parois et jette des éclats de cristal sur les intrus.")

# --- Créatures célestes et légendaires (surface) ------------------------------------------
M("pegasus", "Pégase", "L", "AIR", "FLYING", "Chevaux", "quad", ("fur_white", "feather_white", "gold"), "dark", ["halo:glow_gold"],
  ["volant", "magique", "antique"], "Le cheval ailé des légendes ; il n'a été vu qu'une fois depuis la Fracture.", surface=True,
  wings=True, wingc="feather_white", mane="feather_white", tail="bushy", tailc="feather_white", snout=0.06)
M("unicorn", "Licorne", "L", "LIGHT", "MAGICAL", "Chevaux", "quad", ("fur_white", "fur_white", "gold"), "dark", ["horn:gold"],
  ["magique", "lumineux", "antique"], "Sa corne guérit toutes les blessures ; elle ne s'approche que des cœurs purs.", surface=True,
  mane="glow_pink", tail="bushy", tailc="glow_pink", snout=0.06)
M("griffin", "Griffon", "E", "AIR", "FLYING", "Griffons", "quad", ("fur_sand", "feather_white", "gold"), "glow_gold", [],
  ["volant", "bete", "antique"], "Mi-aigle, mi-lion, il garde les nids des Pics tempétueux.", surface=True, wings=True, wingc="feather_white",
  tail="thin", ears="pointy", mane="feather_white")
M("chimera_lion", "Manticore", "E", "VOID", "MAGICAL", "Chimères", "quad", ("fur_orange", "fur_sand", "scale_red"), "fire", ["spikes:scale_red"],
  ["magique", "bete", "dragon"], "Une manticore échappée du Néant, à la queue de scorpion.", wings=True, wingc="membrane", tail="club", mane="fur_brown", fangs=True)
M("hydra", "Hydre des marais", "L", "NATURE", "AQUATIC", "Serpents", "serpent", ("scale_green", "scale_belly", "leaf_dark"), "glow_gold", ["spikes:leaf_dark", "horns:bone"],
  ["aquatique", "reptile", "antique"], "Coupez une tête, deux repoussent. Mieux vaut l'avoir dans son camp.", surface=True, segments=9, fins=True, fangs=True)
M("behemoth", "Béhémoth", "L", "EARTH", "ANCIENT", "Titans", "quad", ("rock", "rock_light", "crystal"), "glow_gold", ["crystals:crystal", "horns:bone", "moss"],
  ["antique", "roche", "terrestre"], "La caverne entière tremble quand il marche. Il dort depuis la Fracture.", ears="none", legs="short", bulk=1.6, tail="club")


# Créatures écrites mais gardées en réserve (le jeu vise 120 créatures : 20
# historiques + 100 de ce roster).
RESERVE = {"shadow_jelly", "ore_rat", "dune_cat", "rabbit", "glow_moth_bird", "dusk_parrot", "moss_snake", "gecko", "moth",
           "brick_golem", "nature_wisp", "puffer", "poison_frog", "crystal_ape", "pond_frog", "golden_koi", "isle_turtle"}
ACTIVE = [m for m in MONSTERS if m["id"] not in RESERVE]
