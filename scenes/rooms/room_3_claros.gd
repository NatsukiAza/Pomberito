extends "res://scenes/rooms/meadow_room_base.gd"

func _build_layout() -> void:
	# SALA DE DESCENSO VERTICAL (320x340): ideal para encadenar DASH HACIA ABAJO sobre Tortugas Acorazadas
	room_size = Vector2(320, 340)
	spawn_pos = Vector2(28, 36)
	exit_rect = Rect2(132, 326, 56, 12)
	exit_direction_label = "v BAJÁ AL SUMIDERO v"
	hint_text = "RAÍCES PROFUNDAS: usá Dash hacia abajo [Abajo + X] para partir Tortugas [DASH v] y Dash por arriba en Avispas [DASH]."

	# Repisa superior de entrada + Avispa de Viento para cruzar con dash hacia la derecha
	add_grass_block(Rect2(0, 44, 78, 16))
	add_wind_wasp(Vector2(128, 62), 4.5, 3.8)

	# Repisa derecha alta con Tortuga Acorazada
	add_grass_block(Rect2(194, 86, 126, 16))
	add_armored_turtle(Vector2(246, 86), 206.0, 296.0, 24.0)
	add_spikes(Rect2(0, 132, 138, 8))
	add_grass_block(Rect2(0, 140, 144, 14))

	# Tramo medio: libélula + Tortuga Acorazada en el escalón medio
	add_dragonfly(Vector2(174, 152), 5.0, 3.4)
	add_grass_block(Rect2(42, 206, 94, 14))
	add_armored_turtle(Vector2(88, 206), 52.0, 126.0, 24.0)

	# Espinas derechas en el tramo bajo
	add_spikes(Rect2(180, 236, 140, 8))
	add_grass_block(Rect2(176, 244, 144, 14))

	# Embudo final hacia el portal inferior central
	add_dragonfly(Vector2(156, 276), 4.0, 3.2)
	add_grass_block(Rect2(0, 316, 118, 24))
	add_grass_block(Rect2(202, 316, 118, 24))
	add_spikes(Rect2(24, 308, 72, 8))
	add_spikes(Rect2(224, 308, 72, 8))
