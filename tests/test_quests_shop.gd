extends TestCase
## Missions, connexion, passe saisonnier, boutique et événements.

const T0 := 1_700_000_000.0


func test_missions_progress_and_reset() -> void:
	var q := QuestState.new()
	q.roll(T0)
	var ids := q.daily_ids()
	eq(ids.size(), QuestState.DAILY_COUNT, "missions du jour")
	var q2 := QuestState.new()
	q2.roll(T0 + 100.0)
	eq(q2.daily_ids(), ids, "tirage stable dans la journée")
	q.track("battle_win", 2)
	var w := Wallet.new()
	if "battle" in ids:
		check(q.can_claim("battle"), "mission accomplie")
		check(not q.claim("battle", w).is_empty(), "récompense versée")
		check(not q.can_claim("battle"), "une seule fois")
	q.roll(T0 + QuestState.DAY)
	eq(q.progress_of("battle"), 0, "compteurs du jour remis à zéro")
	check(q.progress_of("w_battle") >= 2, "la semaine continue")


func test_login_and_pass() -> void:
	var q := QuestState.new()
	var w := Wallet.new()
	check(not q.claim_login(w, T0).is_empty(), "connexion récompensée")
	check(q.claim_login(w, T0 + 10.0).is_empty(), "une fois par jour")
	q.claim_login(w, T0 + QuestState.DAY)
	eq(q.login_streak, 2, "série de connexion")
	q.pass_xp = QuestState.PASS_XP_PER_TIER * 2
	check(not q.claim_pass(w).is_empty() and not q.claim_pass(w).is_empty(), "deux paliers du passe")
	check(q.claim_pass(w).is_empty(), "pas au-delà du palier atteint")


func test_shop_daily_offers() -> void:
	var s := ShopState.new()
	s.roll(T0)
	var offers := s.daily_offers()
	eq(offers.size(), ShopState.DAILY_COUNT, "offres du jour")
	var w := Wallet.new()
	for k in ["gold", "prisms", "ancient_shards"]:
		w.set_amount(k, 100000)
	var inv := Inventory.new()
	var coll := CollectionState.new()
	eq(s.buy_daily(offers[0], w, inv, coll), "", "achat")
	eq(s.buy_daily(offers[0], w, inv, coll), "Déjà acheté aujourd'hui", "limite quotidienne")
	eq(s.buy_permanent("gold_pack", w), "", "pack de ressources")
	var got := s.open_chest("ingredient_chest", w, inv, coll, RandomNumberGenerator.new())
	check(not got.has("error") and not got.is_empty(), "coffre ouvert")
	s.roll(T0 + QuestState.DAY)
	check(s.bought.is_empty(), "offres renouvelées le lendemain")


func test_weekly_event() -> void:
	var ev := EventCalendar.current(T0)
	check(ev.has("boss"), "événement en cours")
	var enc := EventCalendar.boss_encounter(T0, CollectionState.new())
	check(enc.enemies[0].boss, "boss d'événement")
	check(EventCalendar.ends_in(T0) <= 7.0 * QuestState.DAY, "durée d'une semaine")
