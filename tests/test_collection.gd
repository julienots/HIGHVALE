extends TestCase
## Collection : données, déblocage, niveaux, étoiles, créatures, sauvegarde.


func test_content_is_complete() -> void:
	var heroes := DataRegistry.all_heroes()
	var monsters := DataRegistry.all_monsters()
	check(heroes.size() >= 12, "au moins 12 héros")
	check(monsters.size() >= 10, "au moins 10 monstres")
	var classes := {}
	var categories := {}
	for h in heroes:
		classes[h.hero_class] = true
		check(h.model_scene != null and h.portrait != null, "visuels manquants : " + h.id)
		check(h.skills.size() >= 2 and h.stats != null, "compétences ou statistiques manquantes : " + h.id)
		check(not h.lore.is_empty(), "histoire manquante : " + h.id)
	for m in monsters:
		categories[m.category] = true
		check(m.model_scene != null and m.portrait != null, "visuels manquants : " + m.id)
		check(m.skills.size() >= 2 and not m.food_per_hour.is_empty(), "données manquantes : " + m.id)
	eq(classes.size(), 10, "les 10 classes sont représentées")
	eq(categories.size(), 7, "7 catégories de créatures (la divine viendra avec l'Autel)")


func test_fragments_unlock_and_star_up() -> void:
	var c := CollectionState.new()
	var d := DataRegistry.hero("toben")
	check(not c.add_fragments("toben", d.fragments_to_unlock - 1), "pas encore débloqué")
	check(c.add_fragments("toben", 1), "débloqué au seuil")
	eq(c.hero_stars("toben"), CollectionState.BASE_STARS[d.rarity], "étoiles de départ selon la rareté")
	eq(c.star_up_reason("toben"), "Fragments insuffisants", "évolution impossible sans fragments")
	c.add_fragments("toben", c.star_up_cost("toben"))
	eq(c.star_up_hero("toben"), "", "évolution réussie")
	eq(c.hero_stars("toben"), CollectionState.BASE_STARS[d.rarity] + 1, "une étoile de plus")


func test_hero_level_up_and_cap() -> void:
	var c := CollectionState.new()
	c.unlock_hero("bram")
	var w := Wallet.new()
	w.set_amount("gold", 1_000_000)
	w.set_amount("abyssal_crystal", 1_000_000)
	var p0 := c.hero_power("bram")
	eq(c.level_up_hero("bram", w), "", "montée de niveau")
	check(c.hero_power("bram") > p0, "la puissance augmente")
	while c.level_up_hero("bram", w) == "":
		pass
	eq(c.hero_level("bram"), CollectionState.level_cap_for_stars(1), "plafonné par les étoiles")
	eq(c.hero_level_reason("bram", w), "Faites évoluer le héros (étoiles)", "raison affichée")


func test_monsters_feed_and_save() -> void:
	var c := CollectionState.new()
	var uid := c.add_monster("gloubi")
	var w := Wallet.new()
	eq(c.monster_level_reason(uid, w), "Nourriture insuffisante", "il faut du nectar")
	w.set_amount("underground_nectar", 500)
	w.set_amount("gold", 500)
	eq(c.feed_monster(uid, w), "", "créature nourrie")
	eq(c.monsters[uid].level, 2, "niveau 2")
	c.add_fragments("lysa", 5)
	c.unlock_hero("bram")
	var c2 := CollectionState.new()
	c2.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())))
	eq(c2.monsters.size(), 1, "créatures sauvegardées")
	eq(c2.hero_level("bram"), 1, "héros sauvegardés")
	eq(int(c2.fragments.get("lysa", 0)), 5, "fragments sauvegardés")
	check(c2.add_monster("wisp") > uid, "identifiants uniques")


func test_wild_bonus_rolls() -> void:
	var c := CollectionState.new()
	var city := new_city()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var fragments := 0
	for i in 40:
		var got := c.roll_wild_bonus("crystal", rng, city)
		if got.has("fragments"):
			for id in got.fragments:
				check(DataRegistry.hero(id).rarity < GameEnums.Rarity.DIVINE, "jamais de fragments divins")
				fragments += got.fragments[id]
	check(fragments > 0, "les cristaux donnent des fragments de héros")
	var eggs := 0
	for i in 400:
		if c.roll_wild_bonus("shrooms", rng, city).has("monster"):
			eggs += 1
	check(eggs > 0, "les champignons cachent parfois un œuf")
	check(c.monsters.size() <= c.monster_capacity(city), "jamais plus de créatures que de places")
