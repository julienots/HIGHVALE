"""Génère les données des héros, créatures et compétences (data/heroes,
data/monsters, data/skills) et les scripts de modèles des héros du roster.
Utilisation : python3 tools/data/gen_collection.py"""
import json, os, sys, random
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
ROOT = os.path.join(REPO, "data")
sys.path.insert(0, HERE)
def q(s): return json.dumps(s, ensure_ascii=False)
EL=dict(NEUTRAL=0,FIRE=1,WATER=2,EARTH=3,AIR=4,NATURE=5,CRYSTAL=6,LIGHT=7,SHADOW=8,VOID=9)
CL=dict(WARRIOR=0,GUARDIAN=1,ASSASSIN=2,MAGE=3,PRIEST=4,ARCHER=5,SUMMONER=6,CONTROLLER=7,BERSERKER=8,SUPPORT=9)
RA=dict(COMMON=0,RARE=1,EPIC=2,LEGENDARY=3,DIVINE=4)
MC=dict(TERRESTRIAL=0,FLYING=1,AQUATIC=2,MAGICAL=3,PLANT=4,ELEMENTAL=5,ANCIENT=6,DIVINE=7)
ST=dict(NONE=0,BURN=1,FREEZE=2,POISON=3,PARALYSIS=4,WEAKEN=5,SHIELD=6,REGEN=7,STUN=8,TAUNT=9)
KIND=dict(BASIC=0,SPECIAL=1,ULTIMATE=2,PASSIVE=3)
TG=dict(SINGLE_ENEMY=0,ALL_ENEMIES=1,ROW_ENEMIES=2,SELF=3,SINGLE_ALLY=4,ALL_ALLIES=5,RANDOM_ENEMIES=6)

def skill(sid, name, desc, kind, el, target, power=1.0, heal=0.0, shield=0.0, cost=0, gain=25, cd=0, status="NONE", chance=0.0, turns=2, hits=1, cine=False):
    open(f"{ROOT}/skills/{sid}.tres","w").write(f'''[gd_resource type="Resource" script_class="SkillData" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/combat/skill_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = {q(sid)}
display_name = {q(name)}
description = {q(desc)}
kind = {KIND[kind]}
element = {EL[el]}
target = {TG[target]}
hits = {hits}
power = {power}
heal_power = {heal}
shield_power = {shield}
energy_cost = {cost}
energy_gain = {gain}
cooldown_turns = {cd}
status_effect = {ST[status]}
status_chance = {chance}
status_turns = {turns}
cinematic = {str(cine).lower()}
''')
    return sid

def stats_block(hp, atk, df, spd, crit=0.05, growth=1.08):
    return f'''[sub_resource type="Resource" id="stats"]
script = ExtResource("2_stats")
max_hp = {hp}
attack = {atk}
defense = {df}
speed = {spd}
crit_chance = {crit}
growth_per_level = {growth}
'''

def write_char(folder, cid, script_path, cls, fields, stats, skills, model, portrait):
    ext = [f'[ext_resource type="Script" path="{script_path}" id="1_script"]',
           '[ext_resource type="Script" path="res://src/combat/character_stats.gd" id="2_stats"]',
           f'[ext_resource type="Texture2D" path="res://assets/portraits/{portrait}.png" id="4_portrait"]']
    for i, s in enumerate(skills):
        ext.append(f'[ext_resource type="Resource" path="res://data/skills/{s}.tres" id="s{i}"]')
    sk = "Array[ExtResource(\"5_skill\")]" 
    ext.append('[ext_resource type="Script" path="res://src/combat/skill_data.gd" id="5_skill"]')
    body = "\n".join(f"{k} = {v}" for k, v in fields.items())
    skill_list = ", ".join(f'ExtResource("s{i}")' for i in range(len(skills)))
    txt = f'''[gd_resource type="Resource" script_class="{cls}" load_steps={len(ext) + 2} format=3]

{chr(10).join(ext)}

{stats}
[resource]
script = ExtResource("1_script")
{body}
stats = SubResource("stats")
skills = Array[ExtResource("5_skill")]([{skill_list}])
model_path = "res://assets/models/characters/{model}.glb"
portrait = ExtResource("4_portrait")
'''
    open(f"{ROOT}/{folder}/{cid}.tres","w").write(txt)

HEROES = [
 # id, nom, titre, rareté, élément, classe, (hp, atk, def, spd), couleur, lore, skills
 ("bram","Bram","Mineur des profondeurs","COMMON","EARTH","WARRIOR",(620,48,30,92),"c8843a",
  "Premier volontaire à descendre dans les galeries de HIGHVALE, Bram manie sa hache de mineur comme une arme de guerre. Sa barbe rousse est célèbre dans toute la cité.",
  [("bram_strike","Coup de pioche","Frappe un ennemi avec une force brute.","BASIC","EARTH","SINGLE_ENEMY",dict(power=1.0)),
   ("bram_quake","Éboulement","Fait trembler le sol : dégâts à tous les ennemis, chance d'étourdir.","SPECIAL","EARTH","ALL_ENEMIES",dict(power=0.7,cost=50,cd=2,status="STUN",chance=0.2,turns=1))]),
 ("lysa","Lysa","Archère des cristaux","COMMON","CRYSTAL","ARCHER",(480,56,22,108),"4fa86a",
  "Lysa chasse dans les forêts de champignons géants. Ses flèches à pointe de cristal ne ratent jamais une cible lumineuse.",
  [("lysa_arrow","Flèche cristalline","Tir précis sur un ennemi.","BASIC","CRYSTAL","SINGLE_ENEMY",dict(power=1.0)),
   ("lysa_volley","Pluie d'éclats","Trois flèches sur des ennemis au hasard.","SPECIAL","CRYSTAL","RANDOM_ENEMIES",dict(power=0.55,hits=3,cost=50,cd=2))]),
 ("toben","Toben","Gardien du Temple","RARE","LIGHT","GUARDIAN",(880,38,52,84),"4a7ad8",
  "Chevalier juré du Temple Primordial, Toben n'a jamais reculé d'un pas. Son bouclier porte l'emblème du premier cristal.",
  [("toben_bash","Coup de bouclier","Frappe un ennemi et le provoque.","BASIC","LIGHT","SINGLE_ENEMY",dict(power=0.8,status="TAUNT",chance=0.5,turns=1)),
   ("toben_aegis","Égide sacrée","Protège toute l'équipe avec un bouclier de lumière.","SPECIAL","LIGHT","ALL_ALLIES",dict(power=0.0,shield=0.6,cost=60,cd=3,status="SHIELD",chance=1.0))]),
 ("nyx","Nyx","Lame de l'Ombre","RARE","SHADOW","ASSASSIN",(460,68,20,124),"7a4ad8",
  "Personne ne connaît le vrai visage de Nyx. On dit qu'elle est née dans une faille de la Fracture et qu'elle voit dans le noir absolu.",
  [("nyx_slash","Entaille","Deux coups rapides sur un ennemi.","BASIC","SHADOW","SINGLE_ENEMY",dict(power=0.55,hits=2)),
   ("nyx_shadowstep","Pas de l'ombre","Frappe dans le dos : gros dégâts et affaiblissement.","SPECIAL","SHADOW","SINGLE_ENEMY",dict(power=2.0,cost=60,cd=2,status="WEAKEN",chance=0.6))]),
 ("aurelle","Aurelle","Mage de la Flamme","RARE","FIRE","MAGE",(470,64,22,100),"e05a30",
  "Aurelle a appris la magie du feu en contemplant les forges abyssales. Ses colères sont aussi célèbres que ses sorts.",
  [("aurelle_bolt","Trait de feu","Projette une flamme sur un ennemi, peut brûler.","BASIC","FIRE","SINGLE_ENEMY",dict(power=0.95,status="BURN",chance=0.25)),
   ("aurelle_inferno","Brasier","Embrase tous les ennemis.","SPECIAL","FIRE","ALL_ENEMIES",dict(power=0.75,cost=60,cd=3,status="BURN",chance=0.5))]),
 ("mirela","Sœur Mirela","Guérisseuse des cavernes","COMMON","NATURE","PRIEST",(540,34,28,96),"e8e2d0",
  "Mirela soigne les mineurs blessés depuis la fondation de la cité. Son bâton capte la lumière des champignons pour refermer les plaies.",
  [("mirela_tap","Coup de bâton","Frappe légère.","BASIC","NATURE","SINGLE_ENEMY",dict(power=0.7)),
   ("mirela_bloom","Floraison","Soigne tous les alliés et leur donne une régénération.","SPECIAL","NATURE","ALL_ALLIES",dict(power=0.0,heal=0.45,cost=60,cd=2,status="REGEN",chance=1.0))]),
 ("kael","Kael","Invocateur du Néant","EPIC","VOID","SUMMONER",(560,70,26,98),"6a3ab8",
  "Kael a ouvert une porte qu'il aurait dû laisser fermée. Depuis, des esprits du Néant le suivent et obéissent à sa voix.",
  [("kael_orb","Orbe du Néant","Projectile d'énergie pure.","BASIC","VOID","SINGLE_ENEMY",dict(power=1.0)),
   ("kael_spirits","Esprits errants","Quatre esprits frappent des ennemis au hasard.","SPECIAL","VOID","RANDOM_ENEMIES",dict(power=0.45,hits=4,cost=60,cd=2)),
   ("kael_rift","Brèche primordiale","Ouvre une brèche : énormes dégâts à tous les ennemis.","ULTIMATE","VOID","ALL_ENEMIES",dict(power=1.6,cost=100,cd=4,cine=True))]),
 ("ondine","Ondine","Dame des Profondeurs","EPIC","WATER","CONTROLLER",(600,58,32,104),"2a9ab8",
  "Ondine règne sur les lacs souterrains. D'un geste, elle fige l'eau et ceux qui s'y aventurent.",
  [("ondine_wave","Vague","Frappe un ennemi avec une lame d'eau.","BASIC","WATER","SINGLE_ENEMY",dict(power=0.9)),
   ("ondine_frost","Marée glaciale","Dégâts à tous les ennemis, chance de geler.","SPECIAL","WATER","ALL_ENEMIES",dict(power=0.6,cost=60,cd=3,status="FREEZE",chance=0.35,turns=1)),
   ("ondine_abyss","Étreinte des abysses","Paralyse et affaiblit un ennemi.","ULTIMATE","WATER","SINGLE_ENEMY",dict(power=1.4,cost=100,cd=4,status="PARALYSIS",chance=0.8,cine=True))]),
 ("gorrak","Gorrak","le Furieux","EPIC","FIRE","BERSERKER",(820,74,26,90),"6aa84a",
  "Venu des tunnels sauvages, Gorrak a rejoint HIGHVALE après avoir perdu un duel contre Bram. Sa rage grandit à chaque blessure.",
  [("gorrak_cleave","Fendoir","Frappe un ennemi avec ses deux haches.","BASIC","FIRE","SINGLE_ENEMY",dict(power=1.1)),
   ("gorrak_rage","Rage sanguinaire","Frappe tous les ennemis et s'octroie un bouclier.","SPECIAL","FIRE","ALL_ENEMIES",dict(power=0.8,shield=0.2,cost=60,cd=2)),
   ("gorrak_whirl","Tourbillon de haches","Cinq frappes dévastatrices.","ULTIMATE","FIRE","RANDOM_ENEMIES",dict(power=0.6,hits=5,cost=100,cd=4,cine=True))]),
 ("pip","Pip","le Bricoleur","COMMON","AIR","SUPPORT",(500,40,26,118),"e8862a",
  "Pip répare tout, même ce qui n'était pas cassé. Ses inventions accélèrent toute l'équipe.",
  [("pip_wrench","Clé à molette","Coup de clé sur un ennemi.","BASIC","AIR","SINGLE_ENEMY",dict(power=0.8)),
   ("pip_gadget","Gadget énergétique","Soigne un allié et lui donne de l'énergie.","SPECIAL","AIR","SINGLE_ALLY",dict(power=0.0,heal=0.35,cost=40,cd=1,gain=40))]),
 ("seraphine","Séraphine","Lumière Primordiale","LEGENDARY","LIGHT","MAGE",(700,82,36,112),"ffd84a",
  "Gardienne d'une lumière plus ancienne que la Fracture, Séraphine est apparue le jour où le Temple s'est éveillé. Sa présence repousse les ténèbres.",
  [("seraphine_ray","Rayon sacré","Rayon de lumière sur un ennemi.","BASIC","LIGHT","SINGLE_ENEMY",dict(power=1.05)),
   ("seraphine_halo","Halo","Soigne et protège toute l'équipe.","SPECIAL","LIGHT","ALL_ALLIES",dict(power=0.0,heal=0.3,shield=0.3,cost=60,cd=3)),
   ("seraphine_dawn","Aube primordiale","Lumière aveuglante : énormes dégâts à tous les ennemis, chance d'étourdir.","ULTIMATE","LIGHT","ALL_ENEMIES",dict(power=1.8,cost=100,cd=4,status="STUN",chance=0.4,turns=1,cine=True))]),
 ("valdor","Valdor","Roi Déchu","LEGENDARY","SHADOW","WARRIOR",(980,86,44,96),"8a3a4a",
  "Ancien souverain d'une cité engloutie par la Fracture, Valdor a erré des siècles dans l'ombre. Il cherche à HIGHVALE un royaume digne de sa lame.",
  [("valdor_strike","Lame royale","Frappe puissante sur un ennemi.","BASIC","SHADOW","SINGLE_ENEMY",dict(power=1.1)),
   ("valdor_decree","Décret de l'ombre","Affaiblit tous les ennemis.","SPECIAL","SHADOW","ALL_ENEMIES",dict(power=0.7,cost=60,cd=3,status="WEAKEN",chance=0.7)),
   ("valdor_fall","Chute du royaume","Frappe titanesque sur un ennemi.","ULTIMATE","SHADOW","SINGLE_ENEMY",dict(power=3.2,cost=100,cd=4,cine=True))]),

 ("kryos","Kryos","Dieu des cristaux","DIVINE","CRYSTAL","MAGE",(1500,120,70,118),"7fdcff",
  "Endormi au cœur du premier cristal, Kryos a façonné les veines lumineuses de la caverne. Son réveil fait chanter toutes les pierres de HIGHVALE.",
  [("kryos_lance","Lance de cristal","Projette une lance de cristal.","BASIC","CRYSTAL","SINGLE_ENEMY",dict(power=1.2)),
   ("kryos_prison","Prison cristalline","Enferme tous les ennemis dans le cristal.","SPECIAL","CRYSTAL","ALL_ENEMIES",dict(power=0.9,cost=60,cd=3,status="FREEZE",chance=0.6,turns=1)),
   ("kryos_genesis","Genèse cristalline","Fait jaillir la caverne entière : dégâts colossaux et boucliers pour l'équipe.","ULTIMATE","CRYSTAL","ALL_ENEMIES",dict(power=2.4,shield=0.4,cost=100,cd=5,cine=True))]),
 ("vitalia","Vitalia","Déesse de la vie","DIVINE","NATURE","PRIEST",(1600,90,64,112),"b8f08a",
  "Vitalia a semé les premières spores après la Fracture. Là où elle passe, la roche se couvre de mousse et les blessés se relèvent.",
  [("vitalia_touch","Toucher de sève","Frappe et soigne légèrement l'équipe.","BASIC","NATURE","SINGLE_ENEMY",dict(power=0.9,heal=0.1)),
   ("vitalia_grove","Bosquet sacré","Soin puissant et régénération pour toute l'équipe.","SPECIAL","NATURE","ALL_ALLIES",dict(power=0.0,heal=0.6,cost=60,cd=3,status="REGEN",chance=1.0)),
   ("vitalia_rebirth","Renaissance","Ramène l'équipe à pleine vigueur et la protège.","ULTIMATE","NATURE","ALL_ALLIES",dict(power=0.0,heal=1.0,shield=0.5,cost=100,cd=6,cine=True))]),
 ("pyros","Pyros","Dieu du feu primordial","DIVINE","FIRE","WARRIOR",(1800,130,76,104),"ff7a30",
  "Pyros était la flamme qui brûlait au centre du monde avant la Fracture. Sa hache peut fendre une montagne.",
  [("pyros_cleave","Fendoir solaire","Coup de hache embrasé.","BASIC","FIRE","SINGLE_ENEMY",dict(power=1.25,status="BURN",chance=0.4)),
   ("pyros_eruption","Éruption primordiale","Le sol s'embrase sous tous les ennemis.","SPECIAL","FIRE","ALL_ENEMIES",dict(power=1.0,cost=60,cd=3,status="BURN",chance=0.7)),
   ("pyros_core","Cœur du monde","Libère la flamme originelle : dégâts dévastateurs.","ULTIMATE","FIRE","ALL_ENEMIES",dict(power=3.0,cost=100,cd=5,cine=True))]),

 ("aria","Aria","Rôdeuse des plaines","RARE","AIR","ARCHER",(520,64,24,118),"6ab84a",
  "Née à la surface, Aria a survécu seule dans les plaines après la Fracture. Elle guide désormais les explorateurs de HIGHVALE vers la lumière.",
  [("aria_shot","Tir du vent","Flèche portée par le vent.","BASIC","AIR","SINGLE_ENEMY",dict(power=1.0)),
   ("aria_gale","Rafale de flèches","Cinq flèches sur des ennemis au hasard.","SPECIAL","AIR","RANDOM_ENEMIES",dict(power=0.45,hits=5,cost=60,cd=2))]),
 ("sol","Sol","Paladin d'Aurore","EPIC","LIGHT","GUARDIAN",(1020,52,64,88),"ffd84a",
  "Dernier chevalier des Ruines d'Aurore, Sol a juré de protéger quiconque porte la lumière. Son bouclier n'a jamais été percé.",
  [("sol_strike","Frappe solaire","Frappe un ennemi et le provoque.","BASIC","LIGHT","SINGLE_ENEMY",dict(power=0.85,status="TAUNT",chance=0.6,turns=1)),
   ("sol_bastion","Bastion d'aurore","Bouclier puissant pour toute l'équipe.","SPECIAL","LIGHT","ALL_ALLIES",dict(power=0.0,shield=0.8,cost=60,cd=3)),
   ("sol_zenith","Zénith","Le soleil s'abat sur tous les ennemis et les étourdit.","ULTIMATE","LIGHT","ALL_ENEMIES",dict(power=1.3,cost=100,cd=4,status="STUN",chance=0.35,turns=1,cine=True))]),
 ("thalia","Thalia","Druidesse des mousses","RARE","NATURE","SUMMONER",(560,58,28,100),"4fa84a",
  "Thalia parle aux champignons et aux racines. Quand elle chante, la forêt fongique se lève pour combattre à ses côtés.",
  [("thalia_thorn","Épines","Projette des épines empoisonnées.","BASIC","NATURE","SINGLE_ENEMY",dict(power=0.9,status="POISON",chance=0.3)),
   ("thalia_roots","Racines vivantes","Des racines frappent quatre fois au hasard.","SPECIAL","NATURE","RANDOM_ENEMIES",dict(power=0.5,hits=4,cost=60,cd=2))]),
 ("korin","Korin","Forgeron de guerre","COMMON","FIRE","WARRIOR",(660,50,34,86),"8a5a3a",
  "Korin forge le jour et se bat la nuit. Son marteau de forge est aussi redoutable sur une enclume que sur un casque.",
  [("korin_hammer","Coup de marteau","Lourde frappe brûlante.","BASIC","FIRE","SINGLE_ENEMY",dict(power=1.05,status="BURN",chance=0.2)),
   ("korin_anvil","Choc de l'enclume","Frappe la rangée ennemie.","SPECIAL","EARTH","ROW_ENEMIES",dict(power=0.8,cost=50,cd=2))]),
 ("mira","Mira","Voleuse de cristaux","COMMON","CRYSTAL","ASSASSIN",(440,62,20,126),"1f8f8a",
  "Mira a « emprunté » plus de cristaux que n'importe qui à HIGHVALE. Le Temple lui a pardonné en échange de ses talents.",
  [("mira_cut","Coupe prismatique","Deux coups rapides.","BASIC","CRYSTAL","SINGLE_ENEMY",dict(power=0.55,hits=2)),
   ("mira_vanish","Éclat fuyant","Frappe le plus faible et l'affaiblit.","SPECIAL","CRYSTAL","SINGLE_ENEMY",dict(power=1.8,cost=50,cd=2,status="WEAKEN",chance=0.5))]),
 ("ezra","Ezra","Oracle des marées","RARE","WATER","PRIEST",(600,46,30,98),"3d6ad8",
  "Ezra lit l'avenir dans les remous des lacs souterrains. Il a prédit la Fracture… et personne ne l'a cru.",
  [("ezra_wave","Onde","Vague sur un ennemi.","BASIC","WATER","SINGLE_ENEMY",dict(power=0.8)),
   ("ezra_tide","Marée bienfaisante","Soigne et régénère toute l'équipe.","SPECIAL","WATER","ALL_ALLIES",dict(power=0.0,heal=0.5,cost=60,cd=2,status="REGEN",chance=1.0))]),
 ("draven","Draven","Chevalier noir","EPIC","SHADOW","BERSERKER",(900,80,34,92),"3a2a3a",
  "Ancien champion de Valdor, Draven a renié son roi pour servir HIGHVALE. Sa rage brûle d'une flamme sombre.",
  [("draven_slash","Taille noire","Frappe puissante.","BASIC","SHADOW","SINGLE_ENEMY",dict(power=1.15)),
   ("draven_fury","Furie d'ombre","Frappe toute la rangée et brûle.","SPECIAL","SHADOW","ROW_ENEMIES",dict(power=0.9,cost=60,cd=2,status="BURN",chance=0.4)),
   ("draven_end","Exécution","Coup dévastateur sur un ennemi.","ULTIMATE","SHADOW","SINGLE_ENEMY",dict(power=3.0,cost=100,cd=4,cine=True))]),
 ("luma","Luma","Enchanteresse des cristaux","LEGENDARY","CRYSTAL","CONTROLLER",(760,84,40,114),"b464ff",
  "Luma façonne les cristaux comme d'autres sculptent l'argile. Elle peut emprisonner une armée entière dans un éclat de lumière.",
  [("luma_ray","Rayon prismatique","Rayon sur un ennemi.","BASIC","CRYSTAL","SINGLE_ENEMY",dict(power=1.05)),
   ("luma_prison","Prison d'améthyste","Gèle tous les ennemis.","SPECIAL","CRYSTAL","ALL_ENEMIES",dict(power=0.7,cost=60,cd=3,status="FREEZE",chance=0.5,turns=1)),
   ("luma_shatter","Éclatement","Les cristaux explosent : énormes dégâts à tous.","ULTIMATE","CRYSTAL","ALL_ENEMIES",dict(power=1.9,cost=100,cd=4,cine=True))]),
 ("orin","Orin","Sage des tempêtes","EPIC","AIR","MAGE",(600,78,28,108),"c8d8ff",
  "Orin vit au sommet des Pics tempétueux. Il a appris à parler à la foudre, et la foudre lui répond.",
  [("orin_bolt","Éclair","Foudre sur un ennemi, peut paralyser.","BASIC","AIR","SINGLE_ENEMY",dict(power=1.0,status="PARALYSIS",chance=0.2,turns=1)),
   ("orin_storm","Orage","Foudre sur tous les ennemis.","SPECIAL","AIR","ALL_ENEMIES",dict(power=0.8,cost=60,cd=3,status="PARALYSIS",chance=0.3,turns=1)),
   ("orin_tempest","Tempête éternelle","Six éclairs dévastateurs.","ULTIMATE","AIR","RANDOM_ENEMIES",dict(power=0.65,hits=6,cost=100,cd=4,cine=True))]),
]
FRAG = {"COMMON":20,"RARE":40,"EPIC":80,"LEGENDARY":160,"DIVINE":200}
for (hid,name,title,rar,el,cl,(hp,atk,df,spd),color,lore,skills) in HEROES:
    sids=[skill(*s[:6], **s[6]) for s in skills]
    write_char("heroes", hid, "res://src/heroes/hero_data.gd", "HeroData", {
        "id": q(hid), "display_name": q(name), "title": q(title), "lore": q(lore), "rarity": RA[rar], "element": EL[el],
        "hero_class": CL[cl], "is_god": "true" if rar == "DIVINE" else "false",
        "requires_temple": 5 if hid in ("aria", "sol", "orin") else 0, "max_level": 60, "fragments_to_unlock": FRAG[rar],
        "signature_color": "Color(%.3f, %.3f, %.3f, 1)" % tuple(int(color[i:i+2], 16) / 255 for i in (0, 2, 4))}, stats_block(hp,atk,df,spd, crit=0.05 + 0.03*RA[rar]),
        sids, "hero_"+hid, "hero_"+hid)

# --- Roster étendu (tools/data/hero_roster.py) --------------------------------
from hero_roster import ACTIVE

CLASS_BASE = dict(WARRIOR=(640, 54, 34, 96), GUARDIAN=(820, 40, 58, 82), ASSASSIN=(460, 64, 20, 124), MAGE=(520, 62, 22, 102),
                  PRIEST=(580, 44, 30, 98), ARCHER=(500, 60, 24, 112), SUMMONER=(540, 56, 28, 100), CONTROLLER=(560, 54, 30, 106),
                  BERSERKER=(700, 66, 26, 96), SUPPORT=(600, 42, 34, 104))
RAR_MULT = dict(COMMON=(1.0, 0), RARE=(1.12, 4), EPIC=(1.28, 8), LEGENDARY=(1.45, 12))
# Vocabulaire par élément : (nom, état infligé)
EL_WORD = dict(FIRE=("Flammes", "BURN"), WATER=("Marée", "FREEZE"), EARTH=("Roc", "STUN"), AIR=("Tempête", "PARALYSIS"),
               NATURE=("Ronces", "POISON"), CRYSTAL=("Cristal", "FREEZE"), LIGHT=("Aurore", "WEAKEN"), SHADOW=("Ombre", "WEAKEN"),
               VOID=("Néant", "WEAKEN"), NEUTRAL=("Acier", "NONE"))
STATUS_FR = dict(BURN="brûler", FREEZE="geler", STUN="étourdir", PARALYSIS="paralyser", POISON="empoisonner", WEAKEN="affaiblir", NONE="")


def de(n):
    return ("d'" if n[0] in "AÉEIOUaéeiou" else "de ") + n


def kit(cl, el, rar):
    n, st = EL_WORD[el]
    stv = STATUS_FR[st]
    may = (", peut " + stv) if stv else ""
    K = {
        "WARRIOR": [("Taille " + de(n), "Frappe un ennemi.", "SINGLE_ENEMY", dict(power=1.0)),
                    ("Charge " + de(n), "Frappe la rangée ennemie" + may + ".", "ROW_ENEMIES", dict(power=0.85, cost=50, cd=2, status=st, chance=0.25)),
                    ("Lame " + de(n), "Coup dévastateur sur un ennemi.", "SINGLE_ENEMY", dict(power=2.6, cost=100, cd=4, cine=True))],
        "GUARDIAN": [("Coup de bouclier", "Frappe et provoque l'ennemi.", "SINGLE_ENEMY", dict(power=0.8, status="TAUNT", chance=0.5, turns=1)),
                     ("Rempart " + de(n), "Bouclier pour toute l'équipe.", "ALL_ALLIES", dict(power=0.0, shield=0.6, cost=60, cd=3)),
                     ("Forteresse " + de(n), "Frappe tous les ennemis et peut les étourdir.", "ALL_ENEMIES", dict(power=1.2, cost=100, cd=4, status="STUN", chance=0.3, turns=1, cine=True))],
        "ASSASSIN": [("Double entaille", "Deux coups rapides.", "SINGLE_ENEMY", dict(power=0.55, hits=2)),
                     ("Frappe " + de(n), "Coup précis qui affaiblit la cible.", "SINGLE_ENEMY", dict(power=1.8, cost=50, cd=2, status="WEAKEN", chance=0.5)),
                     ("Danse " + de(n), "Cinq coups sur des ennemis au hasard.", "RANDOM_ENEMIES", dict(power=0.7, hits=5, cost=100, cd=4, cine=True))],
        "MAGE": [("Trait " + de(n), "Projectile magique" + may + ".", "SINGLE_ENEMY", dict(power=1.0, status=st, chance=0.2)),
                 ("Nova " + de(n), "Explosion sur tous les ennemis" + may + ".", "ALL_ENEMIES", dict(power=0.75, cost=60, cd=3, status=st, chance=0.3)),
                 ("Cataclysme " + de(n), "Dégâts énormes sur tous les ennemis.", "ALL_ENEMIES", dict(power=1.6, cost=100, cd=4, cine=True))],
        "PRIEST": [("Châtiment", "Frappe sacrée sur un ennemi.", "SINGLE_ENEMY", dict(power=0.8)),
                   ("Prière " + de(n), "Soigne toute l'équipe.", "ALL_ALLIES", dict(power=0.0, heal=0.45, cost=60, cd=2)),
                   ("Miracle " + de(n), "Grand soin et régénération de l'équipe.", "ALL_ALLIES", dict(power=0.0, heal=0.8, cost=100, cd=4, status="REGEN", chance=1.0, cine=True))],
        "ARCHER": [("Flèche " + de(n), "Tir précis" + may + ".", "SINGLE_ENEMY", dict(power=1.0, status=st, chance=0.15)),
                   ("Pluie de flèches", "Quatre flèches sur des ennemis au hasard.", "RANDOM_ENEMIES", dict(power=0.5, hits=4, cost=60, cd=2)),
                   ("Tir " + de(n), "Tir chargé dévastateur.", "SINGLE_ENEMY", dict(power=2.8, cost=100, cd=4, cine=True))],
        "SUMMONER": [("Esprit " + de(n), "Un esprit frappe un ennemi.", "SINGLE_ENEMY", dict(power=0.9)),
                     ("Appel " + de(n), "Trois esprits frappent au hasard.", "RANDOM_ENEMIES", dict(power=0.6, hits=3, cost=60, cd=2)),
                     ("Légion " + de(n), "Une armée d'esprits frappe tous les ennemis.", "ALL_ENEMIES", dict(power=1.5, cost=100, cd=4, cine=True))],
        "CONTROLLER": [("Entrave " + de(n), "Frappe et peut " + (stv or "affaiblir") + ".", "SINGLE_ENEMY", dict(power=0.9, status=st if st != "NONE" else "WEAKEN", chance=0.3, turns=1)),
                       ("Prison " + de(n), "Peut geler tous les ennemis.", "ALL_ENEMIES", dict(power=0.6, cost=60, cd=3, status="FREEZE", chance=0.4, turns=1)),
                       ("Domination " + de(n), "Frappe tous les ennemis et peut les étourdir.", "ALL_ENEMIES", dict(power=1.4, cost=100, cd=4, status="STUN", chance=0.4, turns=1, cine=True))],
        "BERSERKER": [("Frappe furieuse", "Coup puissant.", "SINGLE_ENEMY", dict(power=1.15)),
                      ("Tourbillon " + de(n), "Frappe toute la rangée" + may + ".", "ROW_ENEMIES", dict(power=0.95, cost=60, cd=2, status=st, chance=0.3)),
                      ("Rage " + de(n), "Déchaînement sur un ennemi.", "SINGLE_ENEMY", dict(power=3.0, cost=100, cd=4, cine=True))],
        "SUPPORT": [("Coup encourageant", "Frappe un ennemi.", "SINGLE_ENEMY", dict(power=0.8)),
                    ("Chant " + de(n), "Bouclier et régénération pour l'équipe.", "ALL_ALLIES", dict(power=0.0, shield=0.4, cost=60, cd=3, status="REGEN", chance=1.0)),
                    ("Hymne " + de(n), "Grand soin de toute l'équipe.", "ALL_ALLIES", dict(power=0.0, heal=0.6, cost=100, cd=4, cine=True))],
    }[cl]
    n_sk = 3 if rar in ("EPIC", "LEGENDARY") else 2
    out = []
    for i, (name, desc, target, kw) in enumerate(K[:n_sk]):
        kind = ["BASIC", "SPECIAL", "ULTIMATE"][i]
        kw = dict(kw)
        if kw.get("status", "NONE") == "NONE":
            kw.pop("status", None)
            kw.pop("chance", None)
        out.append((kind, name, desc, target, kw))
    return out


SUFFIX = ["b", "s", "u"]
for r in ACTIVE:
    rng = random.Random(r["id"])
    bh, ba, bd, bs = CLASS_BASE[r["cl"]]
    mult, spd_bonus = RAR_MULT[r["rar"]]
    j = lambda v: int(round(v * mult * rng.uniform(0.94, 1.06)))
    hp, atk, df = j(bh), j(ba), j(bd)
    spd = bs + spd_bonus + rng.randint(-4, 4)
    sids = []
    for i, (kind, name, desc, target, kw) in enumerate(kit(r["cl"], r["el"], r["rar"])):
        sids.append(skill("%s_%s" % (r["id"], SUFFIX[i]), name, desc, kind, r["el"], target, **kw))
    write_char("heroes", r["id"], "res://src/heroes/hero_data.gd", "HeroData", {
        "id": q(r["id"]), "display_name": q(r["name"]), "title": q(r["title"]), "lore": q(r["lore"]), "rarity": RA[r["rar"]],
        "element": EL[r["el"]], "hero_class": CL[r["cl"]], "is_god": "false", "requires_temple": 5 if r["surface"] else 0,
        "max_level": 60, "fragments_to_unlock": FRAG[r["rar"]],
        "signature_color": "Color(%.3f, %.3f, %.3f, 1)" % tuple(int(r["color"][i:i + 2], 16) / 255 for i in (0, 2, 4))},
        stats_block(hp, atk, df, spd, crit=0.05 + 0.03 * RA[r["rar"]]), sids, "hero_" + r["id"], "hero_" + r["id"])

# Scripts Blender des héros du roster (tools/blender/characters/hero_<id>.py)
NOARG_TALL = ("wizard", "witch", "horned")


def weapon_src(spec):
    parts = spec.split(":")
    args = "".join(", %s" % q(a) for a in parts[1:])
    return "lambda m, x, z: %s(m, x, z%s)" % (parts[0], args)


CHAR_DIR = os.path.join(REPO, "tools", "blender", "characters")
for r in ACTIVE:
    look = dict(r["look"])
    outfit, outfit2 = look.pop("outfit"), look.pop("outfit2")
    args = [q(outfit), q(outfit2)]
    if "hs" in look:
        look["hair_style"] = look.pop("hs")
    for key in ("w", "o"):
        if key in look:
            args.append("%s=%s" % ("weapon" if key == "w" else "offhand", weapon_src(look.pop(key))))
    for k, v in look.items():
        args.append("%s=%s" % (k, repr(v) if not isinstance(v, str) else q(v)))
    tall = look.get("wings") or look.get("horns") or (look.get("hat") and look["hat"][0] in NOARG_TALL)
    src = ('"""Héros : %s (%s). Généré par tools/data/gen_collection.py."""\n'
           "from characters._hero import *  # noqa: F401,F403\n\nEXTENT = %s\nFLAT_PALETTE = True\n\n\n"
           "def build(m):\n    hero(m, %s)\n") % (r["name"], r["title"], "0.27" if tall else "0.24", ", ".join(args))
    open(os.path.join(CHAR_DIR, "hero_%s.py" % r["id"]), "w").write(src)


MONSTERS = [
 ("gloubi","Gloubi","COMMON","WATER","AQUATIC","Gelées",(420,30,24,86),{"underground_nectar":4},["aquatique","gelee"],
  "Une petite gelée curieuse qui absorbe l'humidité des cavernes. Elle adore le nectar et se dandine quand elle est contente.",
  [("gloubi_splash","Éclaboussure","Projette une giclée d'eau.","BASIC","WATER","SINGLE_ENEMY",dict(power=0.9)),
   ("gloubi_bounce","Rebond gluant","Rebondit sur un ennemi et le ralentit.","SPECIAL","WATER","SINGLE_ENEMY",dict(power=1.3,cost=50,cd=2,status="WEAKEN",chance=0.4))]),
 ("crystal_bat","Chiroptère cristallin","COMMON","CRYSTAL","FLYING","Chiroptères",(360,42,16,120),{"underground_nectar":3},["volant","cristal"],
  "Ses ailes vibrent à la fréquence des cristaux abyssaux. Les colonies entières chantent dans les grandes salles.",
  [("bat_bite","Morsure","Morsure rapide.","BASIC","CRYSTAL","SINGLE_ENEMY",dict(power=1.0)),
   ("bat_screech","Cri strident","Dégâts à tous les ennemis, chance de paralyser.","SPECIAL","AIR","ALL_ENEMIES",dict(power=0.5,cost=50,cd=2,status="PARALYSIS",chance=0.2,turns=1))]),
 ("rock_beetle","Scarabée de roche","COMMON","EARTH","TERRESTRIAL","Insectes",(560,34,44,74),{"underground_nectar":5},["terrestre","roche"],
  "Sa carapace est faite de la même pierre que les parois. Les mineurs le suivent pour trouver les meilleurs filons.",
  [("beetle_ram","Charge cornue","Fonce sur un ennemi.","BASIC","EARTH","SINGLE_ENEMY",dict(power=1.0)),
   ("beetle_shell","Carapace","Se protège avec un épais bouclier.","SPECIAL","EARTH","SELF",dict(power=0.0,shield=0.5,cost=40,cd=2))]),
 ("shroomling","Champignard","COMMON","NATURE","PLANT","Fongiques",(460,32,30,84),{"underground_nectar":4},["vegetal","fongique"],
  "Un jeune champignon qui a appris à marcher. Il sème des spores apaisantes partout où il passe.",
  [("shroom_spore","Spores","Nuage de spores toxiques.","BASIC","NATURE","SINGLE_ENEMY",dict(power=0.8,status="POISON",chance=0.35)),
   ("shroom_heal","Spores apaisantes","Soigne toute l'équipe.","SPECIAL","NATURE","ALL_ALLIES",dict(power=0.0,heal=0.25,cost=50,cd=2))]),
 ("fire_salamander","Salamandre ignée","RARE","FIRE","ELEMENTAL","Reptiles",(520,58,30,104),{"underground_nectar":6},["igne","reptile"],
  "Née dans les forges oubliées, la salamandre se nourrit de braises. Sa crête s'embrase quand elle est en colère.",
  [("sala_flame","Langue de feu","Brûle un ennemi.","BASIC","FIRE","SINGLE_ENEMY",dict(power=1.0,status="BURN",chance=0.3)),
   ("sala_burst","Éruption","Explosion de flammes sur tous les ennemis.","SPECIAL","FIRE","ALL_ENEMIES",dict(power=0.65,cost=60,cd=3,status="BURN",chance=0.4))]),
 ("glow_eel","Anguille luminescente","RARE","WATER","AQUATIC","Serpents d'eau",(500,54,28,110),{"underground_nectar":6},["aquatique","lumineux"],
  "Ses taches lumineuses éclairent les lacs souterrains. Une décharge de sa part suffit à paralyser un ours des cavernes.",
  [("eel_zap","Décharge","Décharge électrique, peut paralyser.","BASIC","WATER","SINGLE_ENEMY",dict(power=0.95,status="PARALYSIS",chance=0.2,turns=1)),
   ("eel_coil","Étreinte","Enserre un ennemi et le blesse lourdement.","SPECIAL","WATER","SINGLE_ENEMY",dict(power=1.8,cost=60,cd=2))]),
 ("wisp","Feu follet","RARE","LIGHT","MAGICAL","Esprits",(400,60,20,128),{"underground_nectar":5},["magique","lumineux"],
  "Un fragment de lumière errante qui guide — ou égare — les voyageurs. Il adore les festins et danse autour des fontaines.",
  [("wisp_spark","Étincelle","Petit éclat de lumière.","BASIC","LIGHT","SINGLE_ENEMY",dict(power=1.0)),
   ("wisp_glow","Lueur bienveillante","Soigne un allié et lui donne de l'énergie.","SPECIAL","LIGHT","SINGLE_ALLY",dict(power=0.0,heal=0.4,cost=40,cd=1,gain=35))]),
 ("crystal_golem","Golem de cristal","EPIC","CRYSTAL","ANCIENT","Golems",(1100,62,70,70),{"underground_nectar":10},["antique","cristal"],
  "Gardien façonné par une civilisation disparue, il s'est réveillé quand le Temple a retrouvé sa lumière. Il protège HIGHVALE sans se lasser.",
  [("golem_smash","Poing de cristal","Frappe lourde.","BASIC","CRYSTAL","SINGLE_ENEMY",dict(power=1.0)),
   ("golem_wall","Rempart","Bouclier pour toute l'équipe et provocation.","SPECIAL","CRYSTAL","ALL_ALLIES",dict(power=0.0,shield=0.45,cost=60,cd=3,status="TAUNT",chance=1.0)),
   ("golem_shatter","Fracture cristalline","Onde de choc sur tous les ennemis.","ULTIMATE","CRYSTAL","ALL_ENEMIES",dict(power=1.3,cost=100,cd=4,status="STUN",chance=0.3,turns=1,cine=True))]),
 ("abyss_owl","Hibou des abysses","EPIC","SHADOW","FLYING","Rapaces",(620,72,30,116),{"underground_nectar":8},["volant","ombre"],
  "Ses yeux voient à travers les murs de pierre. Les anciens disent qu'il garde les secrets des profondeurs.",
  [("owl_talon","Serres","Attaque plongeante.","BASIC","SHADOW","SINGLE_ENEMY",dict(power=1.0)),
   ("owl_gaze","Regard hypnotique","Paralyse un ennemi.","SPECIAL","SHADOW","SINGLE_ENEMY",dict(power=0.8,cost=50,cd=2,status="PARALYSIS",chance=0.6,turns=1)),
   ("owl_night","Nuit éternelle","Plonge les ennemis dans l'ombre et les affaiblit.","ULTIMATE","SHADOW","ALL_ENEMIES",dict(power=1.2,cost=100,cd=4,status="WEAKEN",chance=0.7,cine=True))]),
 ("dragonling","Dragonnet primordial","LEGENDARY","FIRE","ANCIENT","Dragons",(980,90,46,108),{"underground_nectar":14},["antique","igne","dragon"],
  "Le dernier œuf d'une lignée née avant la Fracture. Encore petit, il crache déjà des flammes capables de fondre le cristal.",
  [("drake_bite","Morsure ardente","Morsure enflammée.","BASIC","FIRE","SINGLE_ENEMY",dict(power=1.05,status="BURN",chance=0.3)),
   ("drake_wings","Bourrasque","Vent brûlant sur tous les ennemis.","SPECIAL","AIR","ALL_ENEMIES",dict(power=0.75,cost=60,cd=2)),
   ("drake_breath","Souffle primordial","Torrent de flammes dévastateur.","ULTIMATE","FIRE","ALL_ENEMIES",dict(power=1.9,cost=100,cd=4,status="BURN",chance=0.6,cine=True))]),

 ("magma_slime","Gelée de magma","RARE","FIRE","ELEMENTAL","Gelées",(600,56,40,84),{"underground_nectar":6},["igne","gelee"],
  "Née de la fusion d'une gelée et d'une salamandre, elle laisse une traînée de roche fondue derrière elle.",
  [("magma_glob","Projection de lave","Jet de lave brûlant.","BASIC","FIRE","SINGLE_ENEMY",dict(power=1.0,status="BURN",chance=0.35)),
   ("magma_shell","Croûte volcanique","Se couvre de roche : bouclier et provocation.","SPECIAL","EARTH","SELF",dict(power=0.0,shield=0.6,cost=50,cd=2,status="TAUNT",chance=1.0))]),
 ("crystal_chimera","Chimère de cristal","EPIC","CRYSTAL","MAGICAL","Chimères",(780,76,48,112),{"underground_nectar":10},["cristal","volant","roche"],
  "Créature impossible née de la Fusionnerie : ailes de cristal, carapace de roche et regard d'étoile.",
  [("chimera_claw","Griffes prismatiques","Deux coups de griffes.","BASIC","CRYSTAL","SINGLE_ENEMY",dict(power=0.6,hits=2)),
   ("chimera_storm","Tempête d'éclats","Une pluie de cristaux sur des ennemis au hasard.","SPECIAL","CRYSTAL","RANDOM_ENEMIES",dict(power=0.5,hits=4,cost=60,cd=2)),
   ("chimera_prism","Rayon prismatique","Rayon dévastateur sur tous les ennemis.","ULTIMATE","LIGHT","ALL_ENEMIES",dict(power=1.5,cost=100,cd=4,cine=True))]),

 ("plains_wolf","Loup des plaines","COMMON","EARTH","TERRESTRIAL","Bêtes",(520,46,28,112),{"underground_nectar":4},["terrestre","bete"],
  "Les loups de la surface chassent en meute dans les herbes hautes. Bien nourris, ils deviennent des compagnons fidèles.",
  [("wolf_bite","Morsure","Morsure rapide.","BASIC","EARTH","SINGLE_ENEMY",dict(power=1.0)),
   ("wolf_howl","Hurlement","Affaiblit tous les ennemis.","SPECIAL","AIR","ALL_ENEMIES",dict(power=0.4,cost=50,cd=2,status="WEAKEN",chance=0.5))]),
 ("storm_eagle","Aigle tempête","RARE","AIR","FLYING","Rapaces",(520,64,24,124),{"underground_nectar":6},["volant","tempete"],
  "Il plane au-dessus des Pics tempétueux et plonge plus vite que la foudre.",
  [("eagle_dive","Piqué","Plonge sur un ennemi.","BASIC","AIR","SINGLE_ENEMY",dict(power=1.05)),
   ("eagle_gust","Bourrasque","Vent violent sur tous les ennemis.","SPECIAL","AIR","ALL_ENEMIES",dict(power=0.6,cost=60,cd=2))]),
 ("wind_sylph","Sylphe du vent","RARE","AIR","MAGICAL","Esprits",(440,58,22,130),{"underground_nectar":5},["magique","tempete"],
  "Un esprit né des courants d'air de la surface. Il soigne les voyageurs égarés.",
  [("sylph_breeze","Brise tranchante","Lame de vent.","BASIC","AIR","SINGLE_ENEMY",dict(power=0.95)),
   ("sylph_zephyr","Zéphyr","Soigne toute l'équipe.","SPECIAL","AIR","ALL_ALLIES",dict(power=0.0,heal=0.35,cost=50,cd=2))]),
 ("dawn_golem","Colosse d'Aurore","EPIC","LIGHT","ANCIENT","Golems",(1200,64,74,68),{"underground_nectar":10},["antique","roche"],
  "Gardien des Ruines d'Aurore, taillé dans le marbre et l'or d'une cité oubliée.",
  [("dawn_fist","Poing d'or","Frappe lourde.","BASIC","LIGHT","SINGLE_ENEMY",dict(power=1.0)),
   ("dawn_ward","Rempart doré","Bouclier pour l'équipe et provocation.","SPECIAL","LIGHT","ALL_ALLIES",dict(power=0.0,shield=0.5,cost=60,cd=3,status="TAUNT",chance=1.0)),
   ("dawn_beam","Rayon d'aurore","Lumière sur tous les ennemis.","ULTIMATE","LIGHT","ALL_ENEMIES",dict(power=1.4,cost=100,cd=4,cine=True))]),
 ("treant","Sylvain ancien","EPIC","NATURE","PLANT","Sylvains",(1000,60,56,72),{"underground_nectar":10},["vegetal","antique"],
  "Un arbre millénaire réveillé par les spores. Il marche lentement, mais rien ne l'arrête.",
  [("treant_slam","Branche massive","Frappe lourde.","BASIC","NATURE","SINGLE_ENEMY",dict(power=1.0)),
   ("treant_grove","Bosquet guérisseur","Soin et régénération de l'équipe.","SPECIAL","NATURE","ALL_ALLIES",dict(power=0.0,heal=0.4,cost=60,cd=3,status="REGEN",chance=1.0)),
   ("treant_quake","Racines tremblantes","Étourdit tous les ennemis.","ULTIMATE","EARTH","ALL_ENEMIES",dict(power=1.2,cost=100,cd=4,status="STUN",chance=0.4,turns=1,cine=True))]),
 ("tide_crab","Crabe des marées","COMMON","WATER","AQUATIC","Crustacés",(580,40,48,78),{"underground_nectar":4},["aquatique","carapace"],
  "Il garde les rives des lacs souterrains avec ses pinces géantes.",
  [("crab_pinch","Pince","Pincement douloureux.","BASIC","WATER","SINGLE_ENEMY",dict(power=1.0)),
   ("crab_shell","Carapace","Bouclier et provocation.","SPECIAL","WATER","SELF",dict(power=0.0,shield=0.6,cost=40,cd=2,status="TAUNT",chance=1.0))]),
 ("phoenix","Phénix d'aurore","LEGENDARY","FIRE","FLYING","Phénix",(900,92,40,122),{"underground_nectar":14},["igne","volant","dragon"],
  "L'oiseau qui renaît de ses cendres. On dit qu'il a ramené le soleil après la Fracture.",
  [("phoenix_flare","Plume de feu","Brûle un ennemi.","BASIC","FIRE","SINGLE_ENEMY",dict(power=1.05,status="BURN",chance=0.4)),
   ("phoenix_rebirth","Renaissance","Soigne fortement l'équipe.","SPECIAL","FIRE","ALL_ALLIES",dict(power=0.0,heal=0.6,cost=60,cd=3)),
   ("phoenix_nova","Nova solaire","Explosion de flammes sur tous.","ULTIMATE","FIRE","ALL_ENEMIES",dict(power=2.0,cost=100,cd=4,status="BURN",chance=0.6,cine=True))]),
 ("void_serpent","Serpent du Néant","EPIC","VOID","MAGICAL","Serpents",(820,76,40,104),{"underground_nectar":10},["magique","ombre"],
  "Il s'enroule au fond de l'Abîme, là où la Fracture a commencé. Son regard dévore la lumière.",
  [("serpent_fang","Croc du Néant","Morsure empoisonnée.","BASIC","VOID","SINGLE_ENEMY",dict(power=1.0,status="POISON",chance=0.4)),
   ("serpent_coil","Étreinte","Paralyse un ennemi.","SPECIAL","VOID","SINGLE_ENEMY",dict(power=1.3,cost=60,cd=2,status="PARALYSIS",chance=0.6,turns=1)),
   ("serpent_abyss","Gouffre","Le néant engloutit tous les ennemis.","ULTIMATE","VOID","ALL_ENEMIES",dict(power=1.7,cost=100,cd=4,status="WEAKEN",chance=0.6,cine=True))]),
]
for (mid,name,rar,el,cat,fam,(hp,atk,df,spd),food,tags,lore,skills) in MONSTERS:
    sids=[skill(*s[:6], **s[6]) for s in skills]
    write_char("monsters", mid, "res://src/monsters/monster_data.gd", "MonsterData", {
        "id": q(mid), "display_name": q(name), "lore": q(lore), "rarity": RA[rar], "element": EL[el],
        "category": MC[cat], "family": q(fam), "max_level": 50,
        "food_per_hour": "{" + ", ".join(f'"{k}": {v}' for k,v in food.items()) + "}",
        "habitat_element": EL[el], "genetic_tags": "PackedStringArray(" + ", ".join(q(t) for t in tags) + ")",
        "lab_weight": 0.0 if mid in ("magma_slime", "crystal_chimera") else (0.6 if mid == "void_serpent" else 1.0),
        "requires_temple": 5 if mid in ("plains_wolf", "storm_eagle", "wind_sylph", "dawn_golem", "phoenix") else 0}, stats_block(hp,atk,df,spd, crit=0.05 + 0.02*RA[rar], growth=1.07),
        sids, "monster_"+mid, "monster_"+mid)

# --- Roster étendu des créatures (tools/data/monster_roster.py) ----------------
from monster_roster import ACTIVE as MON_ACTIVE

CAT_BASE = dict(TERRESTRIAL=(560, 48, 32, 96), FLYING=(480, 56, 22, 118), AQUATIC=(540, 44, 34, 92), MAGICAL=(460, 58, 22, 108),
                PLANT=(580, 42, 36, 84), ELEMENTAL=(500, 56, 26, 102), ANCIENT=(760, 54, 48, 78))
FOOD = dict(COMMON=4, RARE=6, EPIC=10, LEGENDARY=14)
BASIC_BY_PLAN = dict(blob=("Rebond", "Bondit sur un ennemi."), quad=("Morsure", "Morsure vive."), drake=("Griffes", "Coup de griffes."),
                     bird=("Coup de bec", "Pique un ennemi."), serpent=("Morsure venimeuse", "Morsure qui peut empoisonner."),
                     insect=("Mandibules", "Pince un ennemi."), golem=("Poing de pierre", "Coup lourd."), spirit=("Lueur", "Rayon d'énergie."),
                     plant=("Fouet de liane", "Fouette un ennemi."), fish=("Charge aquatique", "Fonce sur un ennemi."),
                     crab=("Pince", "Pincement douloureux."), frog=("Langue fouet", "Frappe à distance."), jelly=("Piqûre", "Filaments urticants."),
                     brute=("Coup de poing", "Frappe brutale."))
ULT_BY_CAT = dict(TERRESTRIAL="Ruée", FLYING="Tempête d'ailes", AQUATIC="Raz-de-marée", MAGICAL="Sortilège", PLANT="Floraison",
                  ELEMENTAL="Déchaînement", ANCIENT="Colère")


def monster_kit(m):
    n, st = EL_WORD[m["el"]]
    stv = STATUS_FR[st]
    b_name, b_desc = BASIC_BY_PLAN[m["plan"]]
    basic = dict(power=1.0)
    if m["plan"] == "serpent":
        basic.update(status="POISON", chance=0.3)
    elif st != "NONE":
        basic.update(status=st, chance=0.12)
    cat = m["cat"]
    if cat == "PLANT":
        special = ("Spores apaisantes", "Soigne et régénère l'équipe.", "ALL_ALLIES", dict(power=0.0, heal=0.35, cost=60, cd=3, status="REGEN", chance=1.0))
    elif cat == "ANCIENT" or m["plan"] in ("crab", "golem"):
        special = ("Carapace " + de(n), "Se protège et provoque l'ennemi.", "SELF", dict(power=0.0, shield=0.6, cost=40, cd=2, status="TAUNT", chance=1.0))
    elif cat == "FLYING":
        special = ("Rafale " + de(n), "Frappe tous les ennemis.", "ALL_ENEMIES", dict(power=0.6, cost=60, cd=2))
    elif cat == "MAGICAL":
        special = ("Maléfice " + de(n), "Frappe trois fois au hasard" + ((" et peut " + stv) if stv else "") + ".", "RANDOM_ENEMIES",
                   dict(power=0.55, hits=3, cost=60, cd=2, status=st, chance=0.25))
    elif cat == "ELEMENTAL":
        special = ("Souffle " + de(n), "Souffle sur tous les ennemis" + ((", peut " + stv) if stv else "") + ".", "ALL_ENEMIES",
                   dict(power=0.65, cost=60, cd=3, status=st, chance=0.35))
    elif cat == "AQUATIC":
        special = ("Vague " + de(n), "Frappe la rangée ennemie.", "ROW_ENEMIES", dict(power=0.85, cost=50, cd=2, status=st, chance=0.25))
    else:
        special = ("Charge " + de(n), "Fonce sur la rangée ennemie.", "ROW_ENEMIES", dict(power=0.9, cost=50, cd=2))
    ult = (ULT_BY_CAT[cat] + " " + de(n), "Attaque dévastatrice sur tous les ennemis.", "ALL_ENEMIES",
           dict(power=1.5 if m["rar"] == "EPIC" else 1.8, cost=100, cd=4, cine=True))
    kit = [("BASIC", b_name, b_desc, "SINGLE_ENEMY", basic), ("SPECIAL",) + special]
    if m["rar"] in ("EPIC", "LEGENDARY"):
        kit.append(("ULTIMATE",) + ult)
    out = []
    for kind, name, desc, target, kw in kit:
        kw = dict(kw)
        if kw.get("status", "NONE") == "NONE":
            kw.pop("status", None)
            kw.pop("chance", None)
        out.append((kind, name, desc, target, kw))
    return out


for mm in MON_ACTIVE:
    rng = random.Random(mm["id"])
    bh, ba, bd, bs = CAT_BASE[mm["cat"]]
    mult, spd_bonus = RAR_MULT[mm["rar"]]
    j = lambda v: int(round(v * mult * rng.uniform(0.94, 1.06)))
    sids = [skill("%s_%s" % (mm["id"], SUFFIX[i]), name, desc, kind, mm["el"], target, **kw)
            for i, (kind, name, desc, target, kw) in enumerate(monster_kit(mm))]
    write_char("monsters", mm["id"], "res://src/monsters/monster_data.gd", "MonsterData", {
        "id": q(mm["id"]), "display_name": q(mm["name"]), "lore": q(mm["lore"]), "rarity": RA[mm["rar"]], "element": EL[mm["el"]],
        "category": MC[mm["cat"]], "family": q(mm["fam"]), "max_level": 50,
        "food_per_hour": '{"underground_nectar": %d}' % FOOD[mm["rar"]],
        "habitat_element": EL[mm["el"]], "genetic_tags": "PackedStringArray(" + ", ".join(q(t) for t in mm["tags"]) + ")",
        "lab_weight": 1.0, "requires_temple": 5 if mm["surface"] else 0},
        stats_block(j(bh), j(ba), j(bd), bs + spd_bonus + rng.randint(-5, 5), crit=0.05 + 0.02 * RA[mm["rar"]], growth=1.07),
        sids, "monster_" + mm["id"], "monster_" + mm["id"])
    opts = dict(mm["opts"])
    args = [q(mm["plan"]), q(mm["colors"][0]), q(mm["colors"][1]), q(mm["colors"][2]), "eyes=" + q(mm["eyes"]),
            "deco=" + repr(mm["deco"])] + ["%s=%r" % (k, v) for k, v in opts.items()]
    src = ('"""Créature : %s. Généré par tools/data/gen_collection.py."""\n'
           "from characters._beast import creature, EXTENTS\n\nFLAT_PALETTE = True\nEXTENT = EXTENTS[%s]\n\n\n"
           "def build(m):\n    creature(m, %s)\n") % (mm["name"], q(mm["plan"]), ", ".join(args))
    open(os.path.join(CHAR_DIR, "monster_%s.py" % mm["id"]), "w").write(src)

print(len(HEROES) + len(ACTIVE), "héros,", len(MONSTERS) + len(MON_ACTIVE), "créatures,", len(os.listdir(ROOT + "/skills")), "compétences")
