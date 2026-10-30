extends TestCase


func test_add_respects_capacity() -> void:
	var city := new_city()
	var w := new_wallet(city)
	var cap := w.capacity("stone")
	eq(cap, 1500, "capacité de base pierre")
	eq(w.add("stone", 2000), 1500, "ajout plafonné")
	eq(w.amount("stone"), 1500, "quantité plafonnée")
	eq(w.capacity("prisms"), Wallet.UNLIMITED, "premium illimité")
	eq(w.add("prisms", 99999), 99999, "premium sans plafond")


func test_spend_and_missing() -> void:
	var w := new_wallet(new_city(), {"gold": 100, "stone": 50})
	check(not w.spend({"gold": 80, "stone": 60}), "dépense refusée si insuffisant")
	eq(w.amount("gold"), 100, "aucune dépense partielle")
	eq(w.missing({"gold": 80, "stone": 60}), {"stone": 10}, "ressources manquantes")
	check(w.spend({"gold": 80, "stone": 50}), "dépense acceptée")
	eq(w.amount("gold"), 20, "or restant")


func test_refund_ignores_capacity() -> void:
	var w := new_wallet(new_city(), {"gold": 1500})
	w.refund({"gold": 300})
	eq(w.amount("gold"), 1800, "le remboursement ne perd rien")
