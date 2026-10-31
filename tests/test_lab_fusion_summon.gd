extends TestCase
## Laboratoire, Fusionnerie et invocations.

const T0 := 1_000_000.0


func _ings(ids: Array) -> Array:
	return LaboratoryState.ingredients_of(ids)


func test_lab_affinities_shift_probabilities_without_guarantee() -> void:
	var base := LabRules.probabilities(_ings(["vital_drop"]))
	var fire := LabRules.probabilities(_ings(["ember_stone", "ember_stone"]))
	check(fire["fire_salamander"] > base["fire_salamander"] * 2.0, "la pierre de braise favorise les créatures ignées")
	check(fire["gloubi"] > 0.0, "aucun résultat n'est garanti")
	var total := 0.0
	for v in fire.values():
		total += v
	check(absf(total - 1.0) < 0.001, "probabilités normalisées")
	check(not fire.has("magma_slime"), "les créatures de fusion ne sortent pas du Laboratoire")
	var rare := LabRules.rarity_distribution(LabRules.probabilities(_ings(["primordial_amber"])))
	var common := LabRules.rarity_distribution(base)
	check(rare[GameEnums.Rarity.LEGENDARY] > common[GameEnums.Rarity.LEGENDARY] * 3.0, "l'ambre augmente nettement les légendaires")
	check(rare[GameEnums.Rarity.LEGENDARY] < 0.5, "sans les rendre certains")


func test_lab_experiment_cycle() -> void:
	var city := new_city()
	var lab := LaboratoryState.new()
	var inv := Inventory.new()
	var w := new_wallet(city, {"gold": 5000, "vital_essence": 100})
	var coll := CollectionState.new()
	var rng := RandomNumberGenerator.new()
	inv.add("ember_stone", 2)
	eq(lab.start_reason(["ember_stone"], w, inv, city), "Construisez un Laboratoire", "Laboratoire requis")
	city.add_built("laboratory", Vector2i(5, 5), 1, T0)
	eq(LaboratoryState.slots(city), 2, "deux emplacements au niveau 1")
	eq(lab.start(["ember_stone", "ember_stone"], w, inv, city, T0, rng), "", "expérience lancée")
	eq(inv.count("ember_stone"), 0, "ingrédients consommés")
	check(lab.claim(coll, city, T0 + 1.0).has("error"), "pas avant la fin")
	var got := lab.claim(coll, city, T0 + 10000.0)
	check(got.has("uid") and coll.monsters.has(got.uid), "créature obtenue")
	check(not lab.is_running(), "laboratoire libéré")
	eq(lab.synthesize("vital_drop", w, inv), "Ressources insuffisantes", "la synthèse coûte des ressources")
	w.set_amount("underground_nectar", 100)
	eq(lab.synthesize("vital_drop", w, inv), "", "synthèse réussie")
	eq(inv.count("vital_drop"), 1, "ingrédient fabriqué")


func test_fusion_secret_recipe_and_generic() -> void:
	var coll := CollectionState.new()
	var w := Wallet.new()
	w.set_amount("gold", 100000)
	w.set_amount("vital_essence", 10000)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var a := coll.add_monster("gloubi", 4)
	var b := coll.add_monster("fire_salamander", 6)
	var r := FusionRules.fuse(coll, a, b, w, rng)
	eq(r.id, "magma_slime", "recette secrète appliquée")
	check(r.recipe and r.new, "recette découverte, espèce nouvelle")
	eq(coll.monsters[r.uid].level, 5, "niveau moyen des parents")
	check(not coll.monsters.has(a) and not coll.monsters.has(b), "parents consommés")
	check("magma_slime" in coll.discovered_recipes, "recette mémorisée")
	var c := coll.add_monster("shroomling")
	var d := coll.add_monster("glow_eel")
	var r2 := FusionRules.fuse(coll, c, d, w, rng)
	check(DataRegistry.monster(r2.id).rarity >= GameEnums.Rarity.RARE, "rareté au moins égale à celle du meilleur parent")


func test_summon_rates_pity_and_duplicates() -> void:
	var coll := CollectionState.new()
	var w := Wallet.new()
	w.set_amount("prisms", 100000)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var adv := DataRegistry.banner("advanced")
	var rates := SummonRules.effective_rates(adv, T0)
	var total := 0.0
	for v in rates:
		total += v
	check(absf(total - 100.0) < 0.01, "taux affichés cohérents")
	var since_epic := 0
	var max_gap := 0
	for i in 60:
		var r := SummonRules.summon(adv, coll, w, rng, T0)
		check(not r.has("error"), "invocation possible")
		check(not DataRegistry.hero(r.hero).is_god, "pas de dieu hors Autel")
		since_epic = 0 if r.rarity >= GameEnums.Rarity.EPIC else since_epic + 1
		max_gap = maxi(max_gap, since_epic)
		if not r.get("new", false):
			eq(r.fragments, SummonRules.DUPLICATE_FRAGMENTS[r.rarity], "doublon converti en fragments")
	check(max_gap < adv.pity_epic, "Épique garanti dans la fenêtre de garantie")
	var el := DataRegistry.banner("elemental")
	var day := SummonRules.element_of_day(T0)
	for i in 10:
		var r := SummonRules.summon(el, coll, w, rng, T0)
		eq(DataRegistry.hero(r.hero).element, day, "invocation élémentaire filtrée")
	var poor := Wallet.new()
	check(SummonRules.summon(adv, coll, poor, rng, T0).has("error"), "coût exigé")


func test_divine_awakening() -> void:
	var coll := CollectionState.new()
	var w := Wallet.new()
	w.set_amount("divine_dust", 10000)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var div := DataRegistry.banner("divine")
	var r := SummonRules.summon(div, coll, w, rng, T0)
	check(DataRegistry.hero(r.hero).is_god, "l'Autel n'éveille que des dieux")
	check(r.has("fragments") or r.get("new", false), "fragments divins ou éveil")
	var gods := 0
	for i in 300:
		SummonRules.summon(div, coll, w, rng, T0)
	for h in DataRegistry.all_heroes():
		if h.is_god and coll.owns_hero(h.id):
			gods += 1
	check(gods >= 1, "un dieu finit par s'éveiller")
