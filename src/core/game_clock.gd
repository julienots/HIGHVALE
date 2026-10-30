extends Node
## Horloge du jeu (autoload « GameClock »).
## Toutes les minuteries utilisent l'heure Unix pour que la progression
## continue hors ligne. Le décalage de débogage permet de tester le temps.

var debug_offset := 0.0


func now() -> float:
	return Time.get_unix_time_from_system() + debug_offset


func skip(seconds: float) -> void:
	debug_offset += seconds
