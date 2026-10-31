"""Roster étendu des héros de HIGHVALE (au-delà des 24 héros écrits à la main
dans gen_collection.py). Chaque entrée décrit l'identité, l'histoire et
l'apparence ; les statistiques et compétences sont dérivées de la classe, de
l'élément et de la rareté (voir gen_collection.py).

H(id, nom, titre, rareté C/R/E/L, élément, classe, couleur, histoire, apparence, surface=False)
L(tenue, tenue2, w="arme[:arg…]", o="main gauche[:arg…]", hs=coiffure, …autres options de _hero.hero)
"""

ROSTER = []


def L(outfit, outfit2="leather", **kw):
    kw["outfit"] = outfit
    kw["outfit2"] = outfit2
    return kw


def H(hid, name, title, rar, el, cl, color, lore, look, surface=False):
    ROSTER.append(dict(id=hid, name=name, title=title, rar={"C": "COMMON", "R": "RARE", "E": "EPIC", "L": "LEGENDARY"}[rar],
                       el=el, cl=cl, color=color, lore=lore, look=look, surface=surface))


# --- Mineurs, forgerons et bâtisseurs ----------------------------------------
H("garn", "Garn", "Contremaître des galeries", "C", "EARTH", "GUARDIAN", "9a7a4a",
  "Garn a creusé la moitié des galeries de HIGHVALE et connaît chaque fissure par son nom.",
  L("cloth_brown", "leather", hair="hair_brown", hs="bald", beard=True, helmet="helmet_yellow", w="pickaxe", o="shield:cloth_brown:iron"))
H("tilda", "Tilda", "Riveteuse", "C", "FIRE", "SUPPORT", "d0703a",
  "Tilda soude les poutres d'acier de la cité et les armures de ses amis avec le même sourire.",
  L("cloth_orange", "leather", hair="hair_red", hs="bun", goggles="bronze", pouch="leather", w="wrench", o="gauntlet:iron"))
H("orsk", "Orsk", "Tailleur de pierre", "C", "EARTH", "WARRIOR", "7a7a6a",
  "Ses statues gardent les places de HIGHVALE ; son marteau garde ses compagnons.",
  L("cloth_cream", "leather", skin="skin_dark", hair="hair_black", hs="short", beard=True, w="hammer_big"))
H("brunhild", "Brunhild", "Forgeronne des runes", "R", "FIRE", "BERSERKER", "c0502a",
  "Elle grave des runes de feu sur chaque lame qu'elle forge, et teste les plus belles elle-même.",
  L("leather", "cloth_red", hair="hair_blond", hs="braids", armor="iron", pauldrons="iron", glow="fire", w="greataxe"))
H("pell", "Pell", "Apprenti mécanicien", "C", "NEUTRAL", "SUPPORT", "8a8a9a",
  "Pell démonte tout ce qui tourne pour comprendre comment cela marche, puis le remonte en mieux.",
  L("cloth_blue", "cloth_brown", hair="hair_brown", hs="spiky", goggles="iron", pouch="leather", w="wrench"))
H("hurl", "Hurl", "Dynamiteur", "R", "FIRE", "ARCHER", "ff8a3a",
  "Hurl ouvre les nouvelles galeries à coups d'explosifs et lance ses bâtons fumants avec une précision effrayante.",
  L("cloth_orange", "leather", hair="hair_black", hs="mohawk", goggles="bronze", scarf="cloth_red", pouch="leather", w="flame_hand"))
H("magda", "Magda", "Gardienne des wagonnets", "C", "EARTH", "GUARDIAN", "6a5a4a",
  "Aucun wagonnet ne déraille sous la surveillance de Magda, ni aucun ennemi.",
  L("cloth_green", "leather", skin="skin_dark", hair="hair_black", hs="ponytail", armor="iron", w="mace:iron", o="shield:cloth_green:iron"))
H("dorrin", "Dorrin", "Maître des forges", "E", "FIRE", "WARRIOR", "e05a20",
  "Dorrin a allumé la grande forge de HIGHVALE avec une braise rapportée de la Fracture elle-même.",
  L("leather", "steel_dark", skin="skin_dark", hair="hair_white", hs="bald", beard=True, armor="steel_dark", pauldrons="steel_dark", cape="cloth_red", glow="fire", w="sword:steel:fire"))
H("kip", "Kip", "Petit ramoneur", "C", "SHADOW", "ASSASSIN", "4a4a5a",
  "Kip se faufile dans les cheminées de la cité ; personne ne l'entend arriver.",
  L("cloth_black", "cloth_brown", hair="hair_black", hs="spiky", hat=("beret", "cloth_black"), scarf="cloth_red", w="dagger:steel", o="dagger:steel"))
H("helga", "Helga", "Architecte du Temple", "R", "CRYSTAL", "SUPPORT", "6ac8d8",
  "Helga a dessiné les plans du Temple Primordial ; ses compas tracent aussi des boucliers de cristal.",
  L("cloth_teal", "cloth_white", hair="hair_silver", hs="bun", goggles="gold", w="staff:crystal_teal:gold", o="tome:cloth_teal"))

# --- Garde du Temple ----------------------------------------------------------
H("aldric", "Aldric", "Sentinelle du Temple", "C", "LIGHT", "GUARDIAN", "e8d8a0",
  "Aldric veille devant les portes du Temple depuis l'aube de la cité, sans jamais fermer l'œil.",
  L("steel", "cloth_white", hair="hair_brown", hs="short", armor="steel", helmet="steel", w="spear:steel", o="shield:cloth_white:gold"))
H("rowena", "Rowena", "Lancière de la Garde", "C", "LIGHT", "WARRIOR", "f0e0b0",
  "Rowena a gagné sa lance au tournoi de l'Arène ; elle ne l'a jamais perdue depuis.",
  L("cloth_white", "steel", hair="hair_red", hs="ponytail", armor="steel", pauldrons="steel", w="spear:gold"))
H("cedric", "Cédric", "Porte-étendard", "R", "LIGHT", "SUPPORT", "ffd84a",
  "Tant que la bannière de Cédric flotte, aucun soldat de HIGHVALE ne recule.",
  L("cloth_blue", "steel", hair="hair_blond", hs="short", armor="steel", cape="cloth_blue", w="banner_pole:cloth_blue", o="shield:cloth_blue:gold"))
H("isolde", "Isolde", "Capitaine de la Garde", "E", "LIGHT", "GUARDIAN", "fff0b0",
  "Isolde commande la Garde du Temple ; son bouclier porte les éraflures de cent batailles.",
  L("steel", "cloth_white", skin="skin_dark", hair="hair_black", hs="braids", armor="gold", pauldrons="gold", cape="cloth_white", glow="glow_gold", w="sword:steel:glow_gold", o="shield:cloth_white:gold"))
H("bastian", "Bastian", "Arbalétrier des remparts", "C", "AIR", "ARCHER", "a0b8c8",
  "Bastian n'a jamais manqué une cible depuis le haut des remparts de la cité.",
  L("cloth_blue", "leather", hair="hair_brown", hs="short", helmet="steel", w="crossbow"))
H("gwen", "Gwen", "Écuyère", "C", "NEUTRAL", "WARRIOR", "b0a090",
  "Gwen rêve d'être chevalière ; en attendant, elle bat déjà la moitié des chevaliers à l'entraînement.",
  L("cloth_red", "leather", hair="hair_blond", hs="bob", armor="leather", w="sword:steel", o="shield:cloth_red:iron"))
H("tiberius", "Tibérius", "Paladin de l'Aube", "L", "LIGHT", "GUARDIAN", "fff2c0",
  "Tibérius a porté le Temple sur son dos pendant la Fracture, dit la légende. Il ne la dément pas.",
  L("gold", "cloth_white", hair="hair_white", hs="short", beard=True, armor="gold", pauldrons="gold", helmet="gold", cape="cloth_white", glow="glow_gold", eyes="glow_gold", w="mace:gold", o="shield:cloth_white:gold"))
H("marek", "Marek", "Vétéran borgne", "R", "EARTH", "BERSERKER", "8a6a4a",
  "Marek a perdu un œil contre un golem de cristal. Le golem, lui, a tout perdu.",
  L("leather", "cloth_brown", hair="hair_silver", hs="short", beard=True, armor="iron", pauldrons="fur_brown", mask="cloth_black", w="greataxe"))

# --- Ordre des Cristaux -------------------------------------------------------
H("selene", "Sélène", "Prismatiste", "R", "CRYSTAL", "MAGE", "8ad8ff",
  "Sélène découpe la lumière des cristaux en rayons tranchants comme du verre.",
  L("cloth_teal", "cloth_white", hair="hair_blue", hs="long", eyes="crystal", hat=("circlet", "gold"), w="wand:crystal", o="orb:crystal"))
H("quartz", "Quartz", "Golem apprivoisé", "C", "CRYSTAL", "GUARDIAN", "7ab8d0",
  "Né d'un éclat de cristal tombé dans un chaudron, Quartz a choisi de protéger ceux qui l'ont réveillé.",
  L("crystal", "steel_dark", skin="skin_blue", hs="bald", eyes="crystal", pauldrons="crystal", w="gauntlet:crystal", o="gauntlet:crystal"))
H("ambre", "Ambre", "Joaillière", "C", "CRYSTAL", "SUPPORT", "e0a040",
  "Ambre sertit des pierres de chance dans les amulettes des combattants de la cité.",
  L("cloth_orange", "cloth_cream", hair="hair_red", hs="bun", hat=("circlet", "gold"), pouch="leather", w="wand:crystal_teal"))
H("cyrus", "Cyrus", "Chevalier de cristal", "E", "CRYSTAL", "WARRIOR", "62c8ff",
  "L'armure de Cyrus a poussé sur lui comme une géode : elle grandit avec chacune de ses victoires.",
  L("crystal", "steel", hair="hair_silver", hs="short", armor="crystal", pauldrons="crystal", helmet="crystal", glow="rune", eyes="crystal", w="sword:crystal", o="shield:crystal_teal:crystal"))
H("opaline", "Opaline", "Voyante des géodes", "R", "CRYSTAL", "CONTROLLER", "c8b4ff",
  "Dans les reflets d'une géode, Opaline voit les gestes de l'ennemi avant qu'il ne les fasse.",
  L("cloth_purple", "cloth_white", skin="skin_pale", hair="hair_white", hs="long", hood="cloth_purple", eyes="crystal", o="orb:crystal_violet", w="wand:crystal_violet"))
H("zircon", "Zircon", "Lame prismatique", "E", "CRYSTAL", "ASSASSIN", "4ae0d8",
  "Zircon se déplace d'un reflet à l'autre ; on ne voit que l'éclat de ses deux lames.",
  L("cloth_teal", "cloth_black", hair="hair_blue", hs="spiky", mask="cloth_teal", eyes="crystal", w="katana:crystal", o="dagger:crystal"))
H("beryl", "Béryl", "Archiviste des cristaux", "C", "CRYSTAL", "MAGE", "5aa8c8",
  "Béryl classe chaque cristal de la cité par couleur, taille et humeur.",
  L("cloth_blue", "cloth_cream", hair="hair_brown", hs="bob", goggles="gold", w="staff:crystal:gold", o="tome:cloth_blue"))
H("adamant", "Adamant", "Colosse de diamant", "L", "CRYSTAL", "GUARDIAN", "e0f8ff",
  "Le plus ancien gardien de l'Ordre ; aucune arme connue n'a jamais rayé sa peau de diamant.",
  L("crystal", "crystal_teal", skin="skin_blue", hs="bald", eyes="glow_gold", armor="crystal", pauldrons="crystal", crown="crystal", glow="rune", w="hammer_big", o="shield:crystal_teal:crystal"))

# --- Druides fongiques et gens des bosquets ------------------------------------
H("moss", "Moss", "Druide des champignons", "C", "NATURE", "PRIEST", "6aa84a",
  "Moss soigne les blessures avec un baume de spores qui sent la pluie et la terre.",
  L("cloth_green", "bark", hair="hair_brown", hs="long", beard=True, hood="cloth_green", w="staff:glow_teal:bark"))
H("fen", "Fen", "Cueilleuse de spores", "C", "NATURE", "ARCHER", "8ac85a",
  "Fen tire des flèches enduites de spores somnifères, puis cueille tranquillement ses ennemis endormis.",
  L("leaf", "leather", hair="hair_blond", hs="twintails", hat=("flower", "mushroom_pink"), w="bow"))
H("bramble", "Ronce", "Gardien des bosquets", "R", "NATURE", "GUARDIAN", "4a7a3a",
  "Ronce s'enracine devant ses alliés ; il faut des haches pour le faire bouger d'un pas.",
  L("bark", "leaf_dark", skin="skin_green", hair="leaf", hs="mane", eyes="glow_teal", armor="bark", pauldrons="leaf_dark", w="mace:bark", o="shield:leaf:bark"))
H("sporrin", "Sporrin", "Mage-champignon", "R", "NATURE", "SUMMONER", "b46ad8",
  "Sporrin fait pousser des champignons combattants partout où il pose le pied.",
  L("mushroom_violet", "cloth_brown", hair="hair_white", hs="short", hat=("witch", "mushroom_violet"), w="staff:glow_violet:bark"))
H("willow", "Saule", "Druidesse ancienne", "E", "NATURE", "PRIEST", "7ac86a",
  "Saule a vu naître la première forêt fongique ; elle chante encore pour la faire grandir.",
  L("leaf", "bark", skin="skin_pale", hair="hair_white", hs="long", ears="elf", crown="leaf", skirt="leaf_dark", eyes="glow_teal", w="staff:glow_teal:bark", o="orb:leaf"))
H("thorn", "Épine", "Chasseresse sylvestre", "R", "NATURE", "ASSASSIN", "3a6a2a",
  "Épine chasse dans les bosquets la nuit ; ses dagues sont taillées dans des épines géantes.",
  L("leaf_dark", "leather", skin="skin_green", hair="hair_black", hs="ponytail", ears="elf", hood="leaf_dark", w="dagger:leaf", o="dagger:leaf"))
H("pollen", "Pollen", "Barde des fleurs", "C", "NATURE", "SUPPORT", "ffd84a",
  "Les chansons de Pollen font éclore les fleurs et redonnent courage aux plus fatigués.",
  L("cloth_green", "cloth_cream", hair="hair_blond", hs="short", hat=("flower", "glow_gold"), w="lute", o="fan:cloth_green"))
H("verdant", "Verdant", "Seigneur des racines", "L", "NATURE", "CONTROLLER", "2a9a4a",
  "Verdant commande à chaque racine de la caverne ; le sol lui-même se soulève à son appel.",
  L("leaf_dark", "bark", skin="skin_green", hair="leaf", hs="mane", eyes="glow_teal", crown="bark", cape="leaf", glow="glow_teal", horns="bark", w="staff:glow_teal:bark", o="orb:leaf"))

# --- Marins des lacs abyssaux --------------------------------------------------
H("marin", "Marin", "Pêcheur des abysses", "C", "WATER", "ARCHER", "3a7ab8",
  "Marin pêche les anguilles lumineuses au harpon ; les monstres des lacs le craignent.",
  L("cloth_blue", "cloth_cream", skin="skin_dark", hair="hair_black", hs="short", hat=("bandana", "cloth_red"), beard=True, w="trident:steel"))
H("nerine", "Nérine", "Sirène des lacs", "R", "WATER", "SUPPORT", "4ab8d8",
  "Nérine a quitté les lacs pour vivre parmi les hommes ; sa voix calme les tempêtes et les cœurs.",
  L("cloth_teal", "cloth_teal", skin="skin_blue", hair="hair_blue", hs="long", hat=("circlet", "gold"), skirt="cloth_teal", w="lute", o="orb:water"))
H("kraken", "Barbe-Kraken", "Capitaine des barques", "E", "WATER", "BERSERKER", "2a5a8a",
  "Le capitaine a vaincu un kraken à mains nues. Il garde ses tentacules en guise de barbe, prétend-il.",
  L("cloth_blue", "leather", skin="skin_dark", hair="hair_black", hs="short", beard=True, hat=("wide", "cloth_black"), cape="cloth_red", w="greataxe", o="gauntlet:bronze"))
H("coral", "Corail", "Plongeuse", "C", "WATER", "ASSASSIN", "ff7a6a",
  "Corail retient son souffle plus longtemps que quiconque et frappe depuis les eaux sombres.",
  L("cloth_red", "cloth_teal", hair="hair_red", hs="ponytail", goggles="bronze", w="dagger:steel", o="dagger:steel"))
H("tidus", "Tidus", "Gardien des écluses", "R", "WATER", "GUARDIAN", "3a8ac8",
  "Tidus contrôle les écluses qui protègent la cité des crues ; il retient les ennemis de la même façon.",
  L("steel", "cloth_blue", hair="hair_brown", hs="short", armor="steel", helmet="steel", w="trident:steel", o="shield:cloth_blue:steel"))
H("morgane", "Morgane", "Sorcière des marées", "E", "WATER", "MAGE", "1a6ad8",
  "Morgane fait monter les eaux d'un geste et les retire d'un autre ; ses ennemis se noient de surprise.",
  L("cloth_blue", "cloth_black", skin="skin_pale", hair="hair_blue", hs="long", hat=("witch", "cloth_blue"), eyes="crystal", w="staff:crystal_teal:steel", o="orb:water"))
H("abyss", "Thalassa", "Reine des profondeurs", "L", "WATER", "SUMMONER", "0a4a9a",
  "Souveraine des lacs souterrains, Thalassa appelle les créatures abyssales à combattre pour elle.",
  L("cloth_teal", "gold", skin="skin_blue", hair="hair_blue", hs="long", crown="gold", cape="cloth_blue", skirt="cloth_teal", eyes="glow_teal", glow="glow_teal", w="trident:gold", o="orb:crystal_teal"))
H("ripple", "Ondin", "Mousse des barques", "C", "WATER", "SUPPORT", "6ac8e8",
  "Le petit Ondin écope, rame, cuisine et soigne. Sur une barque, il vaut trois marins.",
  L("cloth_white", "cloth_blue", hair="hair_blond", hs="spiky", hat=("bandana", "cloth_blue"), w="wand:water"))

# --- Ombres de Valdor et voleurs ---------------------------------------------
H("vex", "Vex", "Voleur de l'ombre", "C", "SHADOW", "ASSASSIN", "3a2a4a",
  "Vex dérobe une bourse et disparaît avant que son propriétaire ne cligne des yeux.",
  L("cloth_black", "leather", hair="hair_black", hs="short", hood="cloth_black", mask="cloth_black", w="dagger", o="dagger"))
H("lilith", "Lilith", "Danseuse des lames", "R", "SHADOW", "ASSASSIN", "8a2a6a",
  "Lilith danse au milieu des ennemis ; quand la musique s'arrête, plus personne ne tient debout.",
  L("cloth_purple", "cloth_black", skin="skin_pale", hair="hair_black", hs="twintails", eyes="shadow_glow", w="chakram:shadow_glow", o="chakram:shadow_glow"))
H("mordecai", "Mordecai", "Nécromancien repenti", "E", "SHADOW", "SUMMONER", "4a3a6a",
  "Mordecai servait Valdor ; il prête désormais ses esprits à la défense de HIGHVALE.",
  L("cloth_black", "cloth_purple", skin="skin_pale", hair="hair_white", hs="long", hood="cloth_purple", eyes="shadow_glow", glow="shadow_glow", w="scythe", o="tome:cloth_black"))
H("raven", "Corbeau", "Espion", "R", "SHADOW", "CONTROLLER", "2a2a3a",
  "Personne ne connaît le vrai nom de Corbeau. Lui connaît les secrets de tout le monde.",
  L("cloth_black", "cloth_black", hair="hair_black", hs="spiky", hat=("wide", "cloth_black"), scarf="cloth_purple", w="whip:cloth_black", o="dagger"))
H("umbra", "Umbra", "Chevalière du crépuscule", "E", "SHADOW", "WARRIOR", "5a2a7a",
  "Umbra combat au moment où le jour tombe ; c'est alors que sa lame d'ombre est la plus tranchante.",
  L("steel_dark", "cloth_purple", skin="skin_pale", hair="hair_silver", hs="bob", armor="steel_dark", pauldrons="steel_dark", cape="cloth_purple", glow="shadow_glow", w="katana:shadow_glow"))
H("hex", "Hexa", "Maudisseuse", "C", "SHADOW", "MAGE", "6a3a8a",
  "Hexa jette de petites malédictions : lacets défaits, flèches tordues, ennemis maladroits.",
  L("cloth_purple", "cloth_black", hair="hair_black", hs="bob", hat=("witch", "cloth_black"), w="wand:shadow_glow"))
H("noctis", "Noctis", "Prince des ombres", "L", "SHADOW", "ASSASSIN", "1a0a2a",
  "Héritier oublié d'un royaume englouti, Noctis marche dans les ombres comme d'autres marchent dans la rue.",
  L("cloth_black", "steel_dark", skin="skin_pale", hair="hair_silver", hs="spiky", crown="steel_dark", cape="cloth_black", eyes="shadow_glow", glow="shadow_glow", w="katana:shadow_glow", o="dagger:shadow_glow"))
H("griselda", "Griselda", "Herboriste noire", "R", "SHADOW", "PRIEST", "4a4a3a",
  "Les potions de Griselda soignent tout, à condition de ne pas demander ce qu'elles contiennent.",
  L("cloth_black", "cloth_brown", skin="skin_green", hair="hair_white", hs="long", hat=("witch", "cloth_black"), pouch="leather", w="staff:brew_green:wood_dark"))

# --- Érudits, mages et prêtres ------------------------------------------------
H("alaric", "Alaric", "Bibliothécaire", "C", "LIGHT", "MAGE", "d8c890",
  "Alaric a lu tous les livres de la Bibliothèque, deux fois. Il en récite les sorts par cœur.",
  L("cloth_brown", "cloth_cream", hair="hair_white", hs="bald", beard=True, goggles="gold", w="staff:glow_gold:gold", o="tome:cloth_red"))
H("elara", "Elara", "Astronome", "R", "LIGHT", "CONTROLLER", "e8e0ff",
  "Elara n'a jamais vu les étoiles, mais elle a calculé leur position exacte depuis le fond de la caverne.",
  L("cloth_blue", "cloth_white", skin="skin_dark", hair="hair_black", hs="long", hat=("wizard", "cloth_blue"), w="staff:glow_gold:gold", o="orb:glow_gold"))
H("benedict", "Benoît", "Frère soignant", "C", "LIGHT", "PRIEST", "f0e8d0",
  "Frère Benoît soigne quiconque frappe à sa porte, ami ou ennemi, et sert la soupe ensuite.",
  L("cloth_brown", "cloth_cream", hair="hair_brown", hs="bald", hood="cloth_brown", w="staff:glow_gold:wood_dark", o="tome:cloth_brown"))
H("ignatius", "Ignatius", "Pyromancien", "R", "FIRE", "MAGE", "ff5a1a",
  "Ignatius a brûlé trois laboratoires avant de maîtriser son feu. Le quatrième tient encore.",
  L("cloth_red", "cloth_black", hair="hair_red", hs="spiky", hat=("wizard", "cloth_red"), eyes="fire", w="staff:fire:gold", o="flame_hand"))
H("rosalind", "Rosalinde", "Grande prêtresse", "E", "LIGHT", "PRIEST", "fff0d8",
  "Rosalinde dirige les prières du Temple ; on dit que sa voix porte jusqu'à la surface.",
  L("cloth_white", "gold", skin="skin_dark", hair="hair_white", hs="bun", crown="gold", cape="cloth_white", skirt="cloth_white", glow="glow_gold", w="staff:glow_gold:gold", o="orb:glow_gold"))
H("tobias", "Tobias", "Élève mage", "C", "AIR", "MAGE", "a0c8e8",
  "Tobias rate encore la moitié de ses sorts, mais l'autre moitié fait de sacrés dégâts.",
  L("cloth_blue", "cloth_cream", hair="hair_blond", hs="spiky", hat=("wizard", "cloth_teal"), w="wand:rune", o="tome:cloth_blue"))
H("cassia", "Cassia", "Chronomancienne", "L", "VOID", "CONTROLLER", "8a6aff",
  "Cassia peut ralentir une seconde jusqu'à en faire une heure. Elle l'utilise surtout pour finir ses livres.",
  L("cloth_purple", "gold", skin="skin_pale", hair="hair_silver", hs="long", hat=("circlet", "gold"), cape="cloth_purple", eyes="glow_violet", glow="glow_violet", w="staff:crystal_violet:gold", o="orb:glow_violet"))
H("fennick", "Fennick", "Alchimiste", "R", "NATURE", "SUPPORT", "6ac84a",
  "Fennick mélange tout ce qu'il trouve ; ses potions explosent rarement, et toujours au bon moment.",
  L("cloth_green", "leather", hair="hair_red", hs="short", goggles="bronze", pouch="leather", w="wand:brew_green", o="orb:brew_green"))
H("seraph", "Uriel", "Ange déchu", "L", "LIGHT", "WARRIOR", "fff8e0",
  "Tombé du ciel le jour de la Fracture, Uriel a perdu une aile mais jamais sa lame de lumière.",
  L("cloth_white", "gold", skin="skin_pale", hair="hair_blond", hs="long", wings="cloth_white", armor="gold", pauldrons="gold", glow="glow_gold", eyes="glow_gold", w="sword:steel:glow_gold"), surface=True)

# --- Tribu des bêtes ------------------------------------------------------------
H("rook", "Rook", "Homme-loup", "R", "EARTH", "BERSERKER", "7a6a5a",
  "Les nuits de pleine lune à la surface, Rook redevient un loup. Le reste du temps, il est juste grognon.",
  L("fur_grey", "leather", hair="fur_grey", hs="mane", ears="fur_grey", tail="fur_grey", w="claws:steel", o="claws:steel"), surface=True)
H("mila", "Mila", "Fille-renarde", "C", "FIRE", "ASSASSIN", "ff8a3a",
  "Mila est vive comme une flamme et rusée comme un renard. Elle est d'ailleurs un peu les deux.",
  L("cloth_orange", "cloth_white", hair="hair_red", hs="short", ears="cloth_orange", tail="cloth_orange", scarf="cloth_white", w="dagger:fire", o="dagger:fire"))
H("bruno", "Bruno", "Ours guerrier", "R", "NATURE", "GUARDIAN", "8a5a3a",
  "Bruno dort tout l'hiver, mais une fois réveillé, il protège son clan comme une montagne.",
  L("fur_brown", "leather", hair="fur_brown", hs="mane", ears="fur_brown", armor="leather", pauldrons="fur_brown", w="hammer_big"))
H("pounce", "Bondi", "Garçon-chat", "C", "AIR", "ASSASSIN", "e8c88a",
  "Bondi retombe toujours sur ses pattes, même après une chute du haut du Temple.",
  L("cloth_cream", "cloth_brown", hair="hair_blond", hs="spiky", ears="hair_blond", tail="hair_blond", w="claws:steel"))
H("hoofa", "Cornebois", "Faune", "R", "NATURE", "SUPPORT", "8a6a3a",
  "Les airs de flûte de Cornebois font danser les champignons et dormir les monstres.",
  L("leaf", "fur_brown", hair="hair_brown", hs="short", horns="bark", tail="fur_brown", w="lute", o="wand:leaf"))
H("ursa", "Ursa", "Chamane ourse", "E", "NATURE", "SUMMONER", "6a4a2a",
  "Ursa parle avec les esprits des bêtes et les invite à combattre à ses côtés.",
  L("fur_brown", "cloth_brown", skin="skin_dark", hair="hair_black", hs="braids", hood="fur_brown", ears="fur_brown", glow="glow_teal", w="staff:glow_teal:bark", o="orb:leaf"))
H("fang", "Croc", "Chef de meute", "E", "EARTH", "WARRIOR", "5a5a5a",
  "Croc a uni les tribus des bêtes de la surface sous une même bannière : la sienne.",
  L("fur_grey", "leather", hair="fur_grey", hs="mane", ears="fur_grey", tail="fur_grey", armor="iron", pauldrons="fur_grey", cape="cloth_red", w="sword:steel", o="claws:steel"), surface=True)
H("leo", "Léo", "Roi-lion", "L", "LIGHT", "BERSERKER", "e8b84a",
  "Léo règne sur les plaines de la surface ; son rugissement fait trembler les ruines d'Aurore.",
  L("gold", "leather", skin="skin_dark", hair="hair_blond", hs="mane", ears="hair_blond", tail="hair_blond", crown="gold", armor="gold", cape="cloth_red", glow="glow_gold", w="claws:gold", o="claws:gold"), surface=True)

# --- Ailés et gens du ciel (surface) ------------------------------------------
H("skye", "Skye", "Messagère ailée", "C", "AIR", "SUPPORT", "a0d8ff",
  "Skye porte les messages entre la cité et la surface en volant par les puits de lumière.",
  L("cloth_white", "cloth_blue", hair="hair_blond", hs="ponytail", wings="feather_white", w="wand:glow_gold"), surface=True)
H("aquila", "Aquila", "Chasseur des cimes", "R", "AIR", "ARCHER", "8ab8e8",
  "Aquila chasse les aigles tempête sur les Pics ; il est le seul à les avoir apprivoisés.",
  L("cloth_blue", "leather", skin="skin_dark", hair="hair_black", hs="mohawk", wings="feather_white", w="bow"), surface=True)
H("zephyra", "Zéphyra", "Danseuse des vents", "E", "AIR", "CONTROLLER", "c8f0ff",
  "Zéphyra danse avec les courants ; les ennemis qui l'approchent sont emportés comme des feuilles.",
  L("cloth_white", "cloth_teal", skin="skin_pale", hair="hair_white", hs="twintails", wings="feather_white", eyes="crystal", w="fan:cloth_teal", o="fan:cloth_white"), surface=True)
H("gale", "Rafale", "Pirate des airs", "R", "AIR", "WARRIOR", "6a9ac8",
  "Rafale pille les caravanes de la surface depuis son navire volant. Il rend parfois le butin.",
  L("cloth_blue", "leather", hair="hair_red", hs="short", hat=("wide", "cloth_red"), scarf="cloth_white", w="katana", o="crossbow"), surface=True)
H("celeste", "Céleste", "Oracle des nuages", "L", "AIR", "PRIEST", "e0f0ff",
  "Céleste vit au-dessus des nuages et ne descend que lorsque le monde a besoin d'elle.",
  L("cloth_white", "gold", skin="skin_pale", hair="hair_silver", hs="long", wings="feather_white", crown="gold", skirt="cloth_white", glow="glow_gold", eyes="glow_gold", w="staff:glow_gold:gold", o="orb:glow_gold"), surface=True)
H("pip2", "Plume", "Petite aviatrice", "C", "AIR", "ARCHER", "e8a85a",
  "Plume a construit ses propres ailes avec des toiles et des cordes ; elles marchent presque toujours.",
  L("cloth_orange", "leather", hair="hair_brown", hs="bob", goggles="bronze", scarf="cloth_red", wings="cloth_cream", w="crossbow"), surface=True)

# --- Démons et êtres du Néant -------------------------------------------------
H("azazel", "Azazel", "Démon des forges", "E", "FIRE", "BERSERKER", "c02a1a",
  "Azazel est sorti d'une faille de lave ; il a trouvé la cité si amusante qu'il a décidé d'y rester.",
  L("scale_red", "cloth_black", skin="skin_dark", hair="hair_black", hs="spiky", horns="dark", wings="membrane", tail="scale_red", eyes="fire", glow="fire", w="trident:fire"))
H("imp", "Grigri", "Diablotin", "C", "FIRE", "MAGE", "e04a2a",
  "Grigri est petit, rouge et très farceur. Ses boules de feu, elles, ne plaisantent pas.",
  L("scale_red", "cloth_black", skin="scale_red", hair="hair_black", hs="bald", horns="dark", tail="scale_red", eyes="glow_gold", w="flame_hand", o="flame_hand"))
H("vesper", "Vesper", "Succube repentie", "E", "VOID", "CONTROLLER", "8a2a8a",
  "Vesper envoûtait les voyageurs du Néant ; elle envoûte désormais les ennemis de la cité.",
  L("cloth_purple", "cloth_black", skin="skin_pale", hair="hair_black", hs="long", horns="dark", wings="membrane", tail="cloth_purple", eyes="glow_pink", w="whip:cloth_purple", o="orb:glow_pink"))
H("nihil", "Nihil", "Marcheur du Néant", "R", "VOID", "ASSASSIN", "3a1a5a",
  "Nihil sort du vide, frappe et y retourne. Il n'a jamais expliqué ce qu'il y trouve.",
  L("void_skin", "cloth_black", skin="void_skin", hs="bald", hood="cloth_black", eyes="glow_violet", w="dagger:glow_violet", o="dagger:glow_violet"))
H("oblivia", "Oblivia", "Mage du vide", "R", "VOID", "MAGE", "5a3a9a",
  "Oblivia efface ce qu'elle touche : sorts, armures, et parfois les souvenirs de ses ennemis.",
  L("cloth_black", "cloth_purple", skin="skin_blue", hair="hair_white", hs="bob", eyes="glow_violet", hat=("circlet", "steel_dark"), w="staff:glow_violet:steel_dark", o="orb:glow_violet"))
H("malakar", "Malakar", "Seigneur de l'Abîme", "L", "VOID", "WARRIOR", "2a0a4a",
  "Malakar régnait sur l'Abîme du Néant ; vaincu par les fondateurs, il leur a juré une loyauté de fer.",
  L("steel_dark", "void_skin", skin="void_skin", hair="hair_black", hs="mane", horns="steel_dark", wings="membrane", armor="steel_dark", pauldrons="steel_dark", cape="cloth_purple", glow="glow_violet", eyes="glow_violet", w="sword:steel_dark:glow_violet"))
H("echo", "Écho", "Enfant du vide", "C", "VOID", "SUPPORT", "7a6aaa",
  "Écho répète tout ce qu'on lui dit, y compris les sorts de soin qu'il a entendus une seule fois.",
  L("cloth_purple", "cloth_white", skin="skin_blue", hair="hair_white", hs="short", eyes="glow_violet", scarf="cloth_purple", w="wand:glow_violet"))
H("vortex", "Vortex", "Invocatrice des failles", "E", "VOID", "SUMMONER", "6a2aaa",
  "Vortex ouvre des failles d'où surgissent des créatures que même elle ne connaît pas.",
  L("cloth_purple", "cloth_black", skin="skin_pale", hair="hair_silver", hs="twintails", horns="crystal_violet", eyes="glow_violet", glow="glow_violet", w="staff:crystal_violet:steel_dark", o="orb:glow_violet"))

# --- Artisans, inventeurs et marchands ----------------------------------------
H("gizmo", "Gizmo", "Inventeur fou", "R", "AIR", "SUMMONER", "c8a85a",
  "Gizmo fabrique de petits automates volants qui harcèlent l'ennemi en sifflant.",
  L("cloth_brown", "leather", hair="hair_white", hs="spiky", goggles="bronze", pouch="leather", beard=True, w="wrench", o="gauntlet:bronze"))
H("penny", "Penny", "Marchande ambulante", "C", "NEUTRAL", "SUPPORT", "e8c86a",
  "Penny vend de tout, partout, à tout le monde. Même en plein combat.",
  L("cloth_red", "cloth_brown", hair="hair_brown", hs="braids", hat=("wide", "straw"), pouch="leather", w="lantern", o="wand:glow_gold"))
H("cogsworth", "Rouage", "Automate gardien", "E", "NEUTRAL", "GUARDIAN", "b08a4a",
  "Rouage a été construit pour garder le Trésor. Il a étendu sa définition du trésor à tous les habitants.",
  L("bronze", "iron", skin="bronze", hs="bald", eyes="glow_gold", armor="bronze", pauldrons="bronze", helmet="bronze", glow="glow_gold", w="gauntlet:bronze", o="shield:bronze:gold"))
H("fizz", "Fizz", "Artificière", "R", "FIRE", "MAGE", "ff6a4a",
  "Les feux d'artifice de Fizz illuminent les fêtes de la cité, et les champs de bataille aussi.",
  L("cloth_red", "cloth_black", hair="hair_blond", hs="twintails", goggles="bronze", pouch="leather", w="wand:fire", o="flame_hand"))
H("barnaby", "Barnabé", "Aubergiste", "C", "EARTH", "BERSERKER", "a07a4a",
  "Barnabé sort de derrière son comptoir quand une bagarre éclate, et il la termine toujours.",
  L("cloth_cream", "cloth_brown", hair="hair_brown", hs="bald", beard=True, w="mace:wood_dark"))
H("ottilie", "Ottilie", "Cartographe", "R", "EARTH", "CONTROLLER", "8a7a5a",
  "Ottilie a cartographié chaque recoin des profondeurs ; elle sait toujours où piéger l'ennemi.",
  L("cloth_green", "leather", hair="hair_red", hs="bun", hat=("beret", "cloth_green"), goggles="gold", w="tome:cloth_green", o="lantern"))

# --- Bardes et artistes ----------------------------------------------------------
H("lyric", "Lyre", "Barde errant", "C", "LIGHT", "SUPPORT", "e8c8a0",
  "Lyre chante les exploits des héros de HIGHVALE, en exagérant juste ce qu'il faut.",
  L("cloth_red", "cloth_brown", hair="hair_brown", hs="short", hat=("beret", "cloth_red"), cape="cloth_green", w="lute"))
H("melody", "Mélodie", "Chanteuse du Temple", "R", "LIGHT", "PRIEST", "ffe0f0",
  "Quand Mélodie chante au Temple, les blessés se relèvent et les cristaux se mettent à briller.",
  L("cloth_white", "cloth_cream", hair="hair_blond", hs="long", hat=("flower", "mushroom_pink"), skirt="cloth_white", w="lute", o="fan:cloth_white"))
H("harlequin", "Arlequin", "Bouffon masqué", "R", "SHADOW", "CONTROLLER", "c84a8a",
  "Derrière son masque, Arlequin rit des ennemis qu'il fait tourner en bourrique.",
  L("cloth_red", "cloth_black", hair="hair_black", hs="short", hat=("bandana", "cloth_purple"), mask="cloth_white", w="chakram:gold", o="fan:cloth_red"))
H("cadence", "Cadence", "Tambour de guerre", "E", "EARTH", "SUPPORT", "c8783a",
  "Le rythme des tambours de Cadence fait battre le cœur de toute une armée à l'unisson.",
  L("cloth_orange", "leather", skin="skin_dark", hair="hair_black", hs="braids", scarf="cloth_red", armor="leather", w="mace:wood_light", o="gauntlet:bronze"))

# --- Gens de la surface : plaines, ruines, pics --------------------------------
H("harvey", "Harvey", "Fermier des plaines", "C", "NATURE", "WARRIOR", "c8a84a",
  "Harvey a été le premier à semer du blé à la surface ; il défend ses champs à la fourche.",
  L("cloth_blue", "cloth_brown", hair="hair_blond", hs="short", hat=("wide", "straw"), w="trident:iron"), surface=True)
H("ruth", "Ruth", "Gardienne des ruines", "R", "LIGHT", "GUARDIAN", "e8d0a0",
  "Ruth protège les Ruines d'Aurore des pilleurs ; elle connaît chaque pierre tombée.",
  L("cloth_cream", "gold", skin="skin_dark", hair="hair_black", hs="bun", armor="gold", helmet="gold", w="spear:gold", o="shield:cloth_cream:gold"), surface=True)
H("ash", "Cendre", "Ermite des pics", "R", "AIR", "PRIEST", "a0a0b0",
  "Cendre médite depuis vingt ans au sommet des Pics tempétueux ; la foudre ne le dérange plus.",
  L("cloth_cream", "cloth_brown", skin="skin_dark", hair="hair_white", hs="bald", beard=True, scarf="cloth_orange", w="staff:rune:wood_dark"), surface=True)
H("dawn", "Aube", "Archère du soleil levant", "E", "LIGHT", "ARCHER", "ffd87a",
  "Aube tire sa première flèche au lever du soleil ; on dit qu'elle n'a jamais manqué l'aurore.",
  L("cloth_white", "gold", hair="hair_blond", hs="ponytail", ears="elf", hat=("circlet", "gold"), cape="cloth_orange", glow="glow_gold", w="bow"), surface=True)
H("tumble", "Roulebois", "Bûcheron", "C", "NATURE", "BERSERKER", "8a5a2a",
  "Roulebois abat un chêne en trois coups de hache ; il lui en faut deux pour un monstre.",
  L("cloth_red", "cloth_brown", hair="hair_red", hs="short", beard=True, hat=("beret", "cloth_red"), w="greataxe"), surface=True)
H("sora", "Sora", "Moine du vent", "E", "AIR", "WARRIOR", "c8e0f0",
  "Sora combat à mains nues ; ses coups de poing soulèvent des bourrasques.",
  L("cloth_orange", "cloth_cream", skin="skin_pale", hair="hair_black", hs="bald", scarf="cloth_orange", w="gauntlet:cloth_orange", o="gauntlet:cloth_orange"), surface=True)
H("ivy", "Lierre", "Éclaireuse", "C", "NATURE", "ARCHER", "5a9a4a",
  "Lierre repère les nids de monstres avant tout le monde et les signale d'une flèche.",
  L("leaf_dark", "leather", hair="hair_red", hs="ponytail", hood="leaf", w="bow"), surface=True)
H("solon", "Solon", "Roi des ruines", "L", "LIGHT", "SUPPORT", "ffe8a0",
  "Dernier roi de la cité d'Aurore, Solon a dormi mille ans sous les ruines. Il s'est réveillé pour HIGHVALE.",
  L("gold", "cloth_white", skin="skin_dark", hair="hair_white", hs="long", beard=True, crown="gold", cape="cloth_red", glow="glow_gold", eyes="glow_gold", w="staff:glow_gold:gold", o="orb:glow_gold"), surface=True)

# --- Héros variés (complément) -------------------------------------------------
H("rufus", "Rufus", "Garde-chasse", "C", "EARTH", "ARCHER", "8a7a4a",
  "Rufus connaît chaque piste de la caverne et chaque créature qui l'emprunte.",
  L("cloth_green", "leather", hair="hair_brown", hs="short", beard=True, hat=("wide", "leather"), w="crossbow"))
H("elowen", "Elowen", "Elfe des cavernes", "R", "CRYSTAL", "ARCHER", "8ae0c8",
  "Les elfes des cavernes voient dans le noir ; Elowen voit même à travers la roche.",
  L("cloth_teal", "leather", skin="skin_pale", hair="hair_silver", hs="long", ears="elf", cape="cloth_teal", eyes="crystal", w="bow"))
H("grim", "Grim", "Fossoyeur", "C", "SHADOW", "WARRIOR", "4a4a4a",
  "Grim creuse les tombes de la cité, et parfois celles des ennemis qui l'ont sous-estimé.",
  L("cloth_black", "leather", skin="skin_pale", hair="hair_black", hs="short", hat=("wide", "cloth_black"), w="scythe"))
H("blaze", "Brasier", "Cracheur de feu", "C", "FIRE", "MAGE", "ff7a2a",
  "Brasier amusait les foules au marché ; ses flammes amusent beaucoup moins les monstres.",
  L("cloth_red", "cloth_brown", skin="skin_dark", hair="hair_black", hs="mohawk", w="flame_hand", o="flame_hand"))
H("frost", "Givre", "Chasseuse des glaces", "R", "WATER", "ARCHER", "a0e0ff",
  "Givre vient des cavernes gelées du nord ; ses flèches gèlent ce qu'elles touchent.",
  L("cloth_white", "fur_grey", skin="skin_pale", hair="hair_white", hs="braids", hood="fur_grey", eyes="crystal", w="bow"))
H("talon", "Serre", "Dresseur de chauves-souris", "R", "SHADOW", "SUMMONER", "5a4a6a",
  "Serre a élevé des centaines de chauves-souris de cristal ; elles obéissent à son sifflet.",
  L("cloth_black", "leather", hair="hair_brown", hs="spiky", scarf="cloth_purple", goggles="iron", w="wand:crystal_violet", o="lantern:glow_violet"))
H("goliath", "Goliath", "Géant de pierre", "E", "EARTH", "GUARDIAN", "6a6a6a",
  "Goliath est né de la roche des parois ; il est lent, patient et presque indestructible.",
  L("rock", "rock_light", skin="rock", hs="bald", eyes="glow_gold", armor="rock_light", pauldrons="rock", w="hammer_big", o="gauntlet:rock"))
H("nim", "Nim", "Gnome illusionniste", "C", "CRYSTAL", "CONTROLLER", "a88ad8",
  "Nim fait apparaître trois copies de lui-même ; personne ne sait laquelle est la vraie.",
  L("cloth_purple", "cloth_brown", hair="hair_white", hs="short", beard=True, hat=("wizard", "cloth_purple"), w="wand:crystal_violet"))
H("hilda", "Hilda", "Valkyrie", "E", "AIR", "WARRIOR", "c8d8e8",
  "Hilda est descendue des Pics sur un aigle tempête pour défendre la cité. Elle n'est jamais remontée.",
  L("steel", "cloth_blue", hair="hair_blond", hs="braids", hat=("horned", "steel"), wings="feather_white", armor="steel", pauldrons="steel", w="spear:steel", o="shield:cloth_blue:steel"), surface=True)
H("silas", "Silas", "Chasseur de primes", "R", "SHADOW", "ARCHER", "6a5a4a",
  "Silas ne travaille que pour l'or. Heureusement, HIGHVALE paie bien.",
  L("leather", "cloth_black", hair="hair_brown", hs="short", hat=("wide", "leather"), scarf="cloth_red", mask="cloth_red", w="crossbow", o="dagger"))
H("aurora", "Boréale", "Danseuse des lueurs", "E", "LIGHT", "SUPPORT", "a0ffd8",
  "Boréale danse avec les lueurs des cristaux ; son spectacle redonne force et joie aux combattants.",
  L("cloth_teal", "cloth_white", skin="skin_dark", hair="hair_blue", hs="long", hat=("circlet", "gold"), skirt="cloth_teal", glow="glow_teal", w="fan:cloth_teal", o="fan:cloth_white"))
H("magnus", "Magnus", "Archimage", "L", "FIRE", "MAGE", "ff4a1a",
  "Magnus a fondé l'école de magie de HIGHVALE. Ses sorts de feu ont la taille d'un bâtiment.",
  L("cloth_red", "gold", hair="hair_white", hs="long", beard=True, hat=("wizard", "cloth_red"), cape="cloth_red", glow="fire", eyes="fire", w="staff:fire:gold", o="tome:cloth_red"))
H("wren", "Roitelet", "Petit chapardeur", "C", "AIR", "ASSASSIN", "c8a87a",
  "Roitelet est le plus petit voleur de la cité, et de loin le plus rapide.",
  L("cloth_brown", "cloth_green", hair="hair_brown", hs="spiky", hat=("beret", "cloth_green"), scarf="cloth_green", w="dagger:steel"))
H("bertha", "Bertha", "Cuisinière de la caserne", "C", "FIRE", "SUPPORT", "e88a5a",
  "Les soupes de Bertha ont guéri plus de soldats que l'Infirmerie, assure-t-elle.",
  L("cloth_white", "cloth_red", hair="hair_red", hs="bun", hat=("bandana", "cloth_white"), w="mace:wood_light", o="lantern:fire"))
H("kaito", "Kaito", "Rônin des profondeurs", "E", "WATER", "ASSASSIN", "3a5aa8",
  "Kaito a erré seul dans les galeries pendant des années avant de trouver une cité à servir.",
  L("cloth_blue", "cloth_black", skin="skin_pale", hair="hair_black", hs="ponytail", hat=("bandana", "cloth_blue"), w="katana:steel"))
H("yara", "Yara", "Charmeuse de serpents", "R", "NATURE", "CONTROLLER", "4a8a5a",
  "Yara apaise les serpents du Néant d'une note de flûte, et paralyse les ennemis de la même façon.",
  L("cloth_green", "cloth_orange", skin="skin_dark", hair="hair_black", hs="long", hat=("circlet", "gold"), w="whip:leaf", o="lute"))
H("bolt", "Foudre", "Courrier éclair", "C", "AIR", "WARRIOR", "e8e84a",
  "Foudre livre les messages de la cité plus vite que le son. Il frappe à la même vitesse.",
  L("cloth_blue", "cloth_white", hair="hair_blond", hs="spiky", scarf="glow_gold", goggles="iron", w="sword:steel:glow_gold"))
H("morrow", "Lendemain", "Devin aveugle", "E", "VOID", "PRIEST", "8a8ac8",
  "Lendemain ne voit plus le présent, mais il voit l'avenir clairement. Il soigne les blessures avant qu'elles arrivent.",
  L("cloth_white", "cloth_purple", skin="skin_dark", hair="hair_white", hs="bald", beard=True, mask="cloth_white", glow="glow_violet", w="staff:glow_violet:wood_dark", o="orb:glow_violet"))
H("rhea", "Rhéa", "Mère des golems", "L", "EARTH", "SUMMONER", "a08a5a",
  "Rhéa sculpte des golems dans la roche vive et leur souffle la vie d'une chanson.",
  L("cloth_brown", "rock", skin="skin_dark", hair="hair_silver", hs="braids", crown="rock_light", cape="cloth_brown", glow="glow_gold", eyes="glow_gold", w="staff:crystal:rock", o="gauntlet:rock"))
H("ember", "Braise", "Gardienne du foyer", "R", "FIRE", "GUARDIAN", "e85a2a",
  "Braise entretient le feu éternel du Temple ; elle ne laissera personne l'éteindre.",
  L("cloth_red", "steel_dark", hair="hair_red", hs="bob", armor="steel_dark", glow="fire", w="mace:fire", o="shield:cloth_red:steel_dark"))
H("quill", "Calame", "Scribe de guerre", "C", "NEUTRAL", "CONTROLLER", "c8b88a",
  "Calame écrit le nom de ses ennemis dans son grimoire ; ils se sentent soudain très lents.",
  L("cloth_cream", "cloth_brown", hair="hair_black", hs="bob", goggles="gold", w="tome:cloth_brown", o="wand:rune"))
H("sable", "Sable", "Nomade des dunes", "R", "EARTH", "ASSASSIN", "d8b87a",
  "Sable vient des déserts de la surface ; il disparaît dans un nuage de poussière.",
  L("cloth_cream", "cloth_orange", skin="skin_dark", hair="hair_black", hs="short", hat=("bandana", "cloth_cream"), mask="cloth_cream", w="katana:steel", o="dagger:steel"), surface=True)
H("orla", "Orla", "Pêcheuse de perles", "C", "WATER", "PRIEST", "8ad8e8",
  "Orla offre ses perles aux blessés ; on dit qu'elles guérissent les fièvres.",
  L("cloth_teal", "cloth_white", skin="skin_dark", hair="hair_black", hs="ponytail", hat=("flower", "cloth_white"), w="wand:water", o="orb:water"))
H("baldur", "Baldur", "Juge du Temple", "E", "LIGHT", "CONTROLLER", "f8f0c0",
  "Les sentences de Baldur sont justes et sans appel ; ses ennemis se figent sous son regard.",
  L("cloth_white", "gold", hair="hair_silver", hs="short", beard=True, crown="gold", cape="cloth_white", glow="glow_gold", eyes="glow_gold", w="mace:gold", o="tome:cloth_white"))
H("scrap", "Ferraille", "Récupérateur", "C", "NEUTRAL", "WARRIOR", "8a8a7a",
  "Ferraille s'est fait une armure avec ce que les autres jettent. Elle tient étonnamment bien.",
  L("iron", "leather", hair="hair_brown", hs="mohawk", armor="iron", pauldrons="iron", goggles="iron", w="wrench", o="shield:iron:bronze"))
H("vivienne", "Viviane", "Dame du lac", "L", "WATER", "PRIEST", "6ad8ff",
  "Viviane veille sur le lac le plus profond de la caverne ; ses eaux guérissent toutes les blessures.",
  L("cloth_white", "cloth_teal", skin="skin_pale", hair="hair_blue", hs="long", crown="crystal_teal", cape="cloth_teal", skirt="cloth_white", glow="glow_teal", eyes="crystal", w="staff:crystal_teal:gold", o="orb:water"))
H("torvald", "Torvald", "Berserker du nord", "E", "WATER", "BERSERKER", "8ab8d8",
  "Torvald combat torse nu dans les cavernes gelées ; le froid le rend encore plus furieux.",
  L("fur_grey", "leather", skin="skin_pale", hair="hair_blond", hs="braids", beard=True, hat=("horned", "iron"), pauldrons="fur_grey", w="greataxe", o="gauntlet:iron"))
H("pixie", "Lutine", "Fée des lueurs", "R", "LIGHT", "SUMMONER", "ffb8f0",
  "Lutine appelle des nuées de lucioles qui aveuglent l'ennemi et éclairent les alliés.",
  L("cloth_teal", "cloth_white", skin="skin_pale", hair="hair_blond", hs="twintails", ears="elf", wings="glass", w="wand:glow_pink"))
H("gorm", "Gorm", "Orc des tunnels", "C", "EARTH", "BERSERKER", "5a7a3a",
  "Gorm est arrivé à HIGHVALE pour piller ; il est resté pour la cuisine de Bertha.",
  L("leather", "cloth_brown", skin="skin_green", hair="hair_black", hs="mohawk", pauldrons="fur_brown", w="mace:iron"))
H("yseult", "Yseult", "Chevalière errante", "R", "NEUTRAL", "WARRIOR", "a0a0c0",
  "Yseult parcourt les galeries à la recherche d'une cause digne d'elle. Elle l'a trouvée à HIGHVALE.",
  L("steel", "cloth_purple", hair="hair_black", hs="long", armor="steel", pauldrons="steel", cape="cloth_purple", w="sword:steel", o="shield:cloth_purple:steel"))
H("ozzy", "Ozzy", "Dompteur de slimes", "C", "WATER", "SUMMONER", "6ac86a",
  "Ozzy a apprivoisé une douzaine de slimes ; ils le suivent partout en rebondissant.",
  L("cloth_green", "cloth_blue", hair="hair_red", hs="spiky", hat=("beret", "slime"), pouch="leather", w="wand:slime"))
H("seren", "Seren", "Étoile filante", "L", "AIR", "ARCHER", "f0f8ff",
  "Seren est tombée du ciel comme une étoile ; ses flèches de lumière traversent les montagnes.",
  L("cloth_white", "gold", skin="skin_pale", hair="hair_silver", hs="long", ears="elf", wings="feather_white", hat=("circlet", "gold"), glow="glow_gold", eyes="glow_gold", w="bow"), surface=True)
H("cinder", "Escarbille", "Enfant des braises", "C", "FIRE", "ASSASSIN", "ff4a2a",
  "Escarbille est née dans la forge ; elle a des étincelles plein les cheveux et plein les poings.",
  L("cloth_black", "cloth_red", hair="hair_red", hs="spiky", scarf="fire", w="dagger:fire", o="dagger:fire"))
H("hollow", "Creux", "Épouvantail vivant", "R", "SHADOW", "CONTROLLER", "8a7a4a",
  "Creux gardait un champ de la surface ; un éclat de Néant l'a réveillé. Il effraie toujours les corbeaux.",
  L("straw", "cloth_brown", skin="straw", hs="bald", hat=("witch", "cloth_brown"), eyes="fire", scarf="cloth_red", w="scythe"), surface=True)
H("kestrel", "Crécerelle", "Fauconnière", "C", "AIR", "SUMMONER", "b88a5a",
  "Crécerelle et son faucon chassent ensemble depuis l'enfance ; ils se comprennent sans un mot.",
  L("cloth_brown", "leather", hair="hair_blond", hs="ponytail", hat=("wide", "leather"), w="gauntlet:leather", o="bow"), surface=True)
H("onyx", "Onyx", "Gardien noir", "R", "EARTH", "GUARDIAN", "2a2a2a",
  "Onyx porte une armure de pierre noire polie ; elle reflète les coups comme un miroir.",
  L("steel_dark", "cloth_black", skin="skin_dark", hair="hair_black", hs="bald", armor="steel_dark", pauldrons="steel_dark", helmet="steel_dark", w="mace:steel_dark", o="shield:cloth_black:steel_dark"))
H("faye", "Faye", "Enchanteresse", "R", "NATURE", "CONTROLLER", "d88ae8",
  "Faye ensorcelle les ennemis d'un sourire ; ils oublient pourquoi ils étaient venus.",
  L("cloth_purple", "cloth_green", skin="skin_pale", hair="hair_red", hs="long", ears="elf", hat=("flower", "glow_pink"), w="wand:glow_pink", o="orb:glow_pink"))
H("brom", "Brom", "Brasseur", "C", "NATURE", "GUARDIAN", "c89a4a",
  "Brom brasse la bière de nectar de la cité et protège ses tonneaux comme un trésor.",
  L("cloth_cream", "cloth_brown", hair="hair_red", hs="bald", beard=True, armor="leather", w="mace:wood_dark", o="shield:wood:iron"))
H("aegis", "Égide", "Protectrice divine", "L", "LIGHT", "GUARDIAN", "fff8d0",
  "Égide est l'incarnation du serment du Temple ; tant qu'elle se tient debout, personne ne tombe.",
  L("gold", "cloth_white", skin="skin_pale", hair="hair_blond", hs="long", wings="feather_white", crown="gold", armor="gold", pauldrons="gold", cape="cloth_white", glow="glow_gold", eyes="glow_gold", w="spear:gold", o="shield:cloth_white:gold"))
H("dusk", "Brune", "Chasseresse du crépuscule", "E", "SHADOW", "ARCHER", "6a4a7a",
  "Brune chasse entre chien et loup ; ses flèches d'ombre ne font aucun bruit.",
  L("cloth_purple", "leather", skin="skin_dark", hair="hair_silver", hs="ponytail", ears="elf", hood="cloth_purple", eyes="shadow_glow", w="bow"))
H("tank", "Cuirasse", "Soldat lourd", "C", "NEUTRAL", "GUARDIAN", "7a7a8a",
  "Cuirasse porte l'armure la plus lourde de la caserne et ne se plaint jamais. Il ne parle pas beaucoup non plus.",
  L("steel", "steel_dark", hair="hair_brown", hs="short", armor="steel", pauldrons="steel", helmet="steel", w="mace:steel", o="shield:steel:iron"))
H("nova", "Nova", "Étincelle stellaire", "E", "LIGHT", "MAGE", "fff0a0",
  "Nova a capturé un éclat d'étoile dans un cristal ; elle le libère par petites explosions.",
  L("cloth_white", "cloth_blue", skin="skin_dark", hair="hair_white", hs="twintails", hat=("wizard", "cloth_white"), eyes="glow_gold", glow="glow_gold", w="wand:glow_gold", o="orb:glow_gold"))
H("grub", "Larve", "Gobelin des égouts", "C", "VOID", "ASSASSIN", "6a8a4a",
  "Larve connaît tous les égouts de la cité ; il en sort toujours là où on ne l'attend pas.",
  L("cloth_brown", "leather", skin="skin_green", hair="hair_black", hs="bald", ears="elf", w="dagger:glow_violet"))
H("idris", "Idris", "Sage du désert", "E", "EARTH", "MAGE", "d8a85a",
  "Idris lit les sables comme un livre ; il fait se lever des tempêtes de poussière d'un mot.",
  L("cloth_cream", "cloth_orange", skin="skin_dark", hair="hair_white", hs="bald", beard=True, hat=("bandana", "cloth_orange"), w="staff:glow_gold:wood_dark", o="orb:glow_gold"), surface=True)
H("tamsin", "Tamsin", "Infirmière de campagne", "C", "LIGHT", "PRIEST", "f8d8d8",
  "Tamsin court d'un blessé à l'autre sur le champ de bataille, bandages à la main.",
  L("cloth_white", "cloth_red", hair="hair_brown", hs="bun", hat=("bandana", "cloth_white"), pouch="leather", w="wand:glow_pink"))
H("ragnar", "Ragnar", "Roi des berserkers", "L", "FIRE", "BERSERKER", "c83a1a",
  "Ragnar a mené cent raids à la surface ; sa hache brûle encore du dernier.",
  L("fur_brown", "leather", skin="skin_pale", hair="hair_red", hs="braids", beard=True, hat=("horned", "steel_dark"), pauldrons="fur_brown", cape="cloth_red", glow="fire", eyes="fire", w="greataxe", o="gauntlet:steel_dark"))
H("sprig", "Brindille", "Esprit de la forêt", "C", "NATURE", "SUMMONER", "8ae86a",
  "Brindille est un petit esprit sylvestre ; de minuscules lutins des bois l'accompagnent toujours.",
  L("leaf", "bark", skin="skin_green", hair="leaf", hs="spiky", ears="elf", w="wand:leaf"))
H("valka", "Valka", "Lancière des glaces", "R", "WATER", "WARRIOR", "8ad8f8",
  "La lance de Valka est taillée dans une stalactite de glace qui ne fond jamais.",
  L("cloth_white", "cloth_blue", hair="hair_white", hs="ponytail", armor="steel", pauldrons="fur_grey", w="spear:crystal"))
H("mortimer", "Mortimer", "Vampire distingué", "E", "SHADOW", "MAGE", "8a1a2a",
  "Mortimer ne sort que la nuit, ce qui, sous terre, lui laisse beaucoup de temps libre.",
  L("cloth_black", "cloth_red", skin="skin_pale", hair="hair_black", hs="short", cape="cloth_red", eyes="fire", glow="fire", w="wand:fire", o="orb:shadow_glow"))
H("goldie", "Pépite", "Chercheuse d'or", "C", "EARTH", "ARCHER", "e8c84a",
  "Pépite a trouvé plus d'or dans les rivières souterraines que toute la Trésorerie réunie.",
  L("cloth_blue", "cloth_brown", hair="hair_blond", hs="braids", hat=("wide", "straw"), pouch="leather", w="crossbow", o="pickaxe"))
H("azura", "Azura", "Impératrice du ciel", "L", "AIR", "CONTROLLER", "6ab8ff",
  "Azura gouvernait les cités volantes avant la Fracture ; elle commande encore aux tempêtes.",
  L("cloth_blue", "gold", skin="skin_dark", hair="hair_white", hs="long", crown="gold", wings="feather_white", cape="cloth_blue", glow="glow_teal", eyes="crystal", w="staff:rune:gold", o="orb:rune"), surface=True)
H("fergus", "Fergus", "Fauconnier des tunnels", "C", "SHADOW", "SUMMONER", "6a5a5a",
  "Fergus a dressé des chauves-souris géantes qui chassent dans le noir complet.",
  L("cloth_brown", "leather", hair="hair_red", hs="short", beard=True, hood="cloth_black", w="gauntlet:leather", o="lantern:glow_violet"))
H("delphine", "Delphine", "Druidesse des marées", "R", "WATER", "SUMMONER", "4ac8c8",
  "Delphine appelle les esprits de l'eau qui jaillissent des lacs pour submerger l'ennemi.",
  L("cloth_teal", "cloth_white", skin="skin_dark", hair="hair_blue", hs="braids", hood="cloth_teal", w="staff:water:bark", o="orb:water"))
H("hector", "Hector", "Champion de l'Arène", "E", "NEUTRAL", "WARRIOR", "c8a86a",
  "Hector a remporté cent combats d'affilée dans l'Arène ; il cherche encore un adversaire à sa taille.",
  L("leather", "cloth_red", skin="skin_dark", hair="hair_black", hs="short", helmet="bronze", armor="bronze", pauldrons="bronze", cape="cloth_red", w="sword:steel", o="shield:cloth_red:bronze"))
H("whisper", "Murmure", "Espionne silencieuse", "R", "VOID", "ASSASSIN", "4a3a6a",
  "Murmure n'a jamais prononcé un mot ; elle n'en a pas besoin pour faire tomber ses cibles.",
  L("cloth_black", "cloth_purple", skin="skin_pale", hair="hair_silver", hs="bob", mask="cloth_black", eyes="glow_violet", w="dagger:glow_violet", o="chakram:steel_dark"))
H("bjorn", "Bjorn", "Charpentier", "C", "NATURE", "GUARDIAN", "a07a4a",
  "Bjorn a bâti la moitié des maisons de la cité ; il bâtit maintenant des barricades.",
  L("cloth_green", "leather", hair="hair_blond", hs="short", beard=True, pouch="leather", w="hammer_big", o="shield:wood:iron"))
H("lumen", "Lumen", "Porteuse de lanterne", "R", "LIGHT", "SUPPORT", "ffe8a0",
  "Lumen guide les explorateurs dans les galeries obscures ; sa lanterne ne s'éteint jamais.",
  L("cloth_cream", "cloth_blue", hair="hair_blond", hs="bob", hood="cloth_blue", w="lantern", o="wand:glow_gold"))
H("drakon", "Drakon", "Dragonnier", "L", "FIRE", "SUMMONER", "e83a1a",
  "Drakon a élevé un dragon depuis l'œuf ; ensemble, ils ont brûlé l'armée de Valdor.",
  L("scale_red", "steel_dark", skin="skin_dark", hair="hair_black", hs="mohawk", armor="scale_red", pauldrons="scale_red", cape="cloth_black", glow="fire", eyes="fire", tail="scale_red", w="spear:fire", o="gauntlet:scale_red"))
H("mabel", "Mabel", "Grand-mère sorcière", "R", "NATURE", "MAGE", "8a6a9a",
  "Mabel a l'air d'une gentille grand-mère. Ne mangez jamais ses biscuits pendant un combat.",
  L("cloth_purple", "cloth_brown", hair="hair_white", hs="bun", hat=("witch", "cloth_purple"), scarf="cloth_red", w="staff:brew_violet:wood_dark"))
H("caspian", "Caspian", "Prince des lacs", "E", "WATER", "WARRIOR", "3a8ad8",
  "Caspian a hérité de la couronne des lacs ; il se bat en première ligne pour la mériter.",
  L("cloth_blue", "steel", skin="skin_pale", hair="hair_blond", hs="short", crown="gold", armor="steel", cape="cloth_teal", w="sword:steel:crystal_teal", o="shield:cloth_teal:gold"))
H("rusty", "Rouille", "Robot de chantier", "C", "NEUTRAL", "BERSERKER", "a8683a",
  "Rouille a été construit pour démolir des murs ; il démolit maintenant des monstres.",
  L("iron", "bronze", skin="iron", hs="bald", eyes="fire", armor="iron", pauldrons="bronze", w="pickaxe", o="gauntlet:iron"))


# Héros écrits mais gardés en réserve pour de futures mises à jour (le jeu vise
# 150 héros au total : 24 historiques + 126 de ce roster).
RESERVE = {"pell", "magda", "gwen", "ambre", "beryl", "pollen", "ripple", "alaric", "tumble", "ivy", "wren", "bolt",
           "quill", "orla", "cinder", "kestrel", "brom", "tank", "grub", "sprig", "bjorn", "fergus", "echo", "bastian",
           "aldric", "orsk", "benedict", "nim", "pounce", "pip2", "barnaby", "goldie", "rufus", "scrap"}
ACTIVE = [r for r in ROSTER if r["id"] not in RESERVE]
