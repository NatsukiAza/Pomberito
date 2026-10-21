extends "res://scenes/rooms/meadow_room_base.gd"

func _build_layout() -> void:
	# TORRE VERTICAL DIAGONAL (320x360): combina los 3 tipos de enemigos antes del jefe
	room_size = Vector2(320, 360)
	spawn_pos = Vector2(28, 322)
	exit_rect = Rect2(130, 10, 60, 12)
	exit_direction_label = "^ CUMBRE DEL JEFE ^"
	hint_text = "AGUJA DEL CLARO: combiná pisotón (Libélulas), Dash por arriba (Avispas) y Dash abajo (Tortugas)."

	# Piso base y espinas inferiores
	add_grass_block(Rect2(0, 330, 76, 30))
	add_spikes(Rect2(80, 352, 240, 8))

	# Zig-zag 1: libélula + repisa derecha con Tortuga Acorazada
	add_dragonfly(Vector2(118, 294), 5.0, 3.4)
	add_grass_block(Rect2(196, 272, 78, 14))
	add_armored_turtle(Vector2(234, 272), 204.0, 264.0, 24.0)

	# Zig-zag 2: columna central de pared + Avispa Eléctrica izquierda
	add_grass_block(Rect2(148, 178, 18, 76))
	add_wind_wasp(Vector2(92, 206), 4.5, 3.8)
	add_grass_block(Rect2(18, 176, 68, 14))

	# Zig-zag 3: ascenso final con libélula y avispa hacia la cumbre central
	add_dragonfly(Vector2(114, 124), 5.0, 3.6)
	add_wind_wasp(Vector2(212, 92), 4.5, 3.8)
	add_grass_block(Rect2(244, 118, 60, 14))

	# Plataforma de cumbre bajo el portal superior
	add_grass_block(Rect2(116, 44, 88, 14))
	add_beetle(Vector2(160, 44), 126.0, 194.0, 44.0)
