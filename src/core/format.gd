class_name Fmt
extends RefCounted
## Utilitaires de mise en forme des nombres et durées pour l'interface.


static func amount(v: float) -> String:
	var n := int(floor(v))
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 10_000:
		return "%.1fk" % (n / 1000.0)
	var s := str(n)
	if n >= 1000:
		s = s.substr(0, s.length() - 3) + " " + s.substr(s.length() - 3)
	return s


static func duration(seconds: float) -> String:
	var s := int(ceil(maxf(seconds, 0.0)))
	if s < 60:
		return "%ds" % s
	var m := s / 60
	if m < 60:
		return "%dm %02ds" % [m, s % 60]
	var h := m / 60
	if h < 24:
		return "%dh %02dm" % [h, m % 60]
	return "%dj %02dh" % [h / 24, h % 24]
