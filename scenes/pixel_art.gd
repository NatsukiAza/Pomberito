class_name PixelArt
extends RefCounted

static var _cache: Dictionary = {}

static func _from_ascii(key: String, rows: Array[String], palette: Dictionary) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]

	var h := rows.size()
	var w := rows[0].length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var line: String = rows[y]
		for x in range(w):
			var ch := line[x]
			if palette.has(ch):
				img.set_pixel(x, y, palette[ch])
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func cat_texture(has_dash: bool, pose: String = "idle") -> ImageTexture:
	var key := ("cat_v3_ready_" if has_dash else "cat_v3_spent_") + pose
	var fur_light := Color("ffb347") if has_dash else Color("8ce8ff")
	var fur_main := Color("eb8226") if has_dash else Color("4ca8d4")
	var fur_stripe := Color("a84a12") if has_dash else Color("28628a")
	var scarf := Color("e83b52") if has_dash else Color("4a6984")

	var palette := {
		"O": Color("16191e"),
		"L": fur_light,
		"B": fur_main,
		"S": fur_stripe,
		"W": Color("fff9eb"),
		"P": Color("f0788c"),
		"G": Color("58e877"),
		"R": scarf
	}

	var rows: Array[String] = []
	if pose == "run_1":
		# Zancada extendida: cuerpo inclinado adelante, bufanda ondeando atrás, patas abiertas corriendo
		rows = [
			"....OOO.......OOO...",
			"...OBPBO.....OBPBO..",
			"...OBPBBOOOOOBBPBO..",
			"...OBSLBBBBBBBLSBO..",
			"..OOBSSBLLLLLBSSBOO.",
			"..OBBBBLLLLLLBBBBBO.",
			"..OBBBOOWWWWWOOGOBO.",
			"..OBBBOOWWWWWWWOBBO.",
			"...OBBWWWPWWPWWBBO..",
			".OOOORRRRRRRRRRROO..",
			"ORRRRRRRRRRRRRRRO...",
			"OO..OOSBBWWWWWBBSOO.",
			"...OOSBBBWWWWWWBBBSO",
			"..OOBB.OBBBBBBBBO.OO",
			".OOBBO..OOOOOOO..OBO",
			".OOOO............OOO",
			"...................."
		]
	elif pose == "run_2":
		# Zancada agrupada: rebote medio de carrera con cola alta y patas recogidas bajo el pecho
		rows = [
			"....................",
			"....OOO.......OOO...",
			"...OBPBO.....OBPBO..",
			"...OBPBBOOOOOBBPBO..",
			"...OBSLBBBBBBBLSBO..",
			"..OOBSSBLLLLLBSSBOO.",
			"..OBBBBLLLLLLBBBBBO.",
			"..OBBBOOWWWWWOOGOBO.",
			"..OBBBOOWWWWWWWOBBO.",
			"...OBBWWWPWWPWWBBO..",
			"OOOOORRRRRRRRRRROO..",
			".ORRRRRRRRRRRRRRO...",
			".OOSBBBBWWWWWWBBBSO.",
			"OOBB.OBBWWWWWWBBO.OO",
			".OO...OBBBBBBBBO....",
			".......OOBBOOBOO....",
			".......OOOO.OOOO...."
		]
	elif pose == "skid":
		# Frenada / deslizamiento con momentum: cuerpo tirado hacia atrás, patas clavadas adelante frenando
		rows = [
			"..OOO........OOO....",
			".OBPBO......OBPBO...",
			".OBPBBOOOOOOBBPBO...",
			".OBSLBBBBBBBBLSBO...",
			"OOBSSBLLLLLLBSSBOO..",
			"OBBBBBLLLLLLBBBBBO..",
			"OBBOGOOWWWWWOOGOBO..",
			"OBBBOOWWWWWWWOBBBO..",
			".OBBWWWPWWPWWWBBO...",
			"..OORRRRRRRRRRRROOO.",
			"..OORRRRRRRRRRRRRROO",
			".OOSBBWWWWWWWWBBSOOO",
			"OOSBBBWWWWWWWWBBO...",
			"OBBO.OBBBBBBBBBBO...",
			".OO...OOBBBOOBBBO..O",
			".......OOOO..OOOOOOO"
		]
	else:
		rows = [
			"...OOO........OOO...",
			"..OBPBO......OBPBO..",
			"..OBPBBOOOOOOBBPBO..",
			"..OBSLBBBBBBBBLSBO..",
			".OOBSSBLLLLLLBSSBOO.",
			".OBBBBBLLLLLLBBBBBO.",
			".OBBOGOOWWWWWOOGOBO.",
			".OBBBOOWWWWWWWOBBBO.",
			"..OBBWWWPWWPWWWBBO..",
			"...OORRRRRRRRRROO...",
			"..OORRRRRRRRRRRROO..",
			".OOSBBWWWWWWWWBBSOO.",
			"OOSBBBWWWWWWWWBBBSOO",
			"OSBBBBWWWWWWWWBBBBSO",
			"O.OBBSSBBBBBBSSBBO.O",
			"..OBBBBOOOOOOBBBBO..",
			"..OBBBO......OBBBO..",
			"..OOOO........OOOO.."
		]
	return _from_ascii(key, rows, palette)

static func beetle_texture() -> ImageTexture:
	var palette := {
		"O": Color("141019"),
		"R": Color("b82c43"),
		"H": Color("eb5e70"),
		"L": Color("ffd4dc"),
		"Y": Color("ffdb63"),
		"D": Color("6b182c"),
		"C": Color("47525e")
	}
	var rows: Array[String] = [
		".............OO...",
		"............OCCO..",
		"....OOOOOOOOCCOO..",
		"..OORRRRRRRRROOO..",
		".ORRHHHHHHHHHRRRO.",
		"ORRHLLYYYYYYHHRRRO",
		"ORRHLYYYYYYYYHRCCO",
		"ORRRRRRRRRRRRRDYCO",
		"ODDDDDDDDDDDDDDOO.",
		"OOOOOOOOOOOOOOOO..",
		".OO..OO..OO..OO...",
		"OO...OO..OO...OO.."
	]
	return _from_ascii("beetle_v2", rows, palette)

static func dragonfly_texture() -> ImageTexture:
	var palette := {
		"O": Color("141c24"),
		"W": Color("d6faff"),
		"C": Color("7cd8eb"),
		"G": Color("32b868"),
		"L": Color("82f29c"),
		"Y": Color("ffe46b"),
		"D": Color("1d7543")
	}
	var rows: Array[String] = [
		".WWWWWW......WWWWWW.",
		"WCCCCCCW....WCCCCCCW",
		".WCCCCCCO..OCCCCCCW.",
		"..OOOOOOOY.YOOOOOO..",
		".WCCCCCOOGLLGOCCCCW.",
		"WCCCCCCOGLLLLGOCCCCW",
		".WWWWWW.OGDDGO.WWWW.",
		"........OGLLGO......",
		"........OGDDGO......",
		".........OGGO.......",
		".........ODDO.......",
		"..........OO........"
	]
	return _from_ascii("dragonfly_v2", rows, palette)

static func wind_wasp_texture() -> ImageTexture:
	# Enemigo Tipo 2: Avispa Eléctrica / de Viento — se mata pasándole por encima con DASH
	var palette := {
		"O": Color("141824"),
		"W": Color("e8ffff"),
		"C": Color("5ce1ff"),
		"Y": Color("ffe047"),
		"A": Color("ff9b26"),
		"R": Color("ff385c")
	}
	var rows: Array[String] = [
		"..WWWW........WWWW..",
		".WCCCCW..OO..WCCCCW.",
		"..WCCCCOOOOOOCCCCW..",
		"...OOOYAYOOYAYOOO...",
		"..OYYYYOORROOYYYYO..",
		".OYYAAYYYYYYYYAAYYO.",
		".OOYYYYOYYYYOYYYYOO.",
		"...OOOOAAOOAAOOOO...",
		".....OYYYYYYYYO.....",
		"......OOAAAAOO......",
		".......OORROO.......",
		"........OOOO........"
	]
	return _from_ascii("wind_wasp_v1", rows, palette)

static func armored_turtle_texture() -> ImageTexture:
	# Enemigo Tipo 3: Tortuga Acorazada — caparazón de roca azulada, solo muere con DASH HACIA ABAJO
	var palette := {
		"O": Color("12161f"),
		"S": Color("8aa1bd"),
		"M": Color("546a87"),
		"D": Color("324259"),
		"G": Color("479c59"),
		"Y": Color("ffe46b")
	}
	var rows: Array[String] = [
		".....OO....OO.......",
		"....OSSO..OSSO......",
		"..OOSSSSSSSSSSOO....",
		".OSSSSMMMMMMSSSSO...",
		"OSSSMMDDDDDDMMSSSO..",
		"OSSMDDDDDDDDDDMSSOOO",
		"ODDDDDDDDDDDDDDDGGYO",
		"OOOOOOOOOOOOOOOOOGGO",
		".OOGGO........OOGGO.",
		".OOOO..........OOOO."
	]
	return _from_ascii("armored_turtle_v1", rows, palette)

static func boar_texture(enraged: bool = false, jumping: bool = false) -> ImageTexture:
	var key := "boar_v2_%s_%s" % [str(enraged), str(jumping)]
	var fur_light := Color("e86852") if enraged else Color("9e684e")
	var fur_main := Color("b83535") if enraged else Color("754936")
	var fur_dark := Color("731b22") if enraged else Color("4a2c20")
	var mane := Color("ff9e47") if enraged else Color("331d16")

	var palette := {
		"O": Color("140f0d"),
		"M": mane,
		"L": fur_light,
		"F": fur_main,
		"D": fur_dark,
		"T": Color("fff8de"),
		"E": Color("ffea54"),
		"R": Color("ff2e4c"),
		"N": Color("d47a6a")
	}
	var rows: Array[String] = [
		"......OMOMOMOMOMOM........",
		"....OOMMMMMMMMMMMMOO......",
		"...OMMDDDDDDDDDDDDMMO.....",
		"..OMDDLLLLLLLLLLLLDDMO....",
		".OMDDLLLLFFFFFFLLLLDDOO...",
		".ODDLFFFFFFFFFFFFFFFDNOO..",
		"ODDDFFFFFFFFFFFFERFFFDNNO.",
		"ODDFFFFFFFFFFFFFEERFFFNNOO",
		"TTODFFFFFFFFFFFFFFFFFFNNOO",
		"TTTODDDDDDDDDDDDDDDDDDOOO.",
		".TTOOOOOOOOOOOOOOOOOOOO...",
		"..OO.OOO..OOO..OOO..OOO...",
		".....OOO..OOO..OOO..OOO...",
		".....OOO..OOO..OOO..OOO..."
	]
	return _from_ascii(key, rows, palette)
