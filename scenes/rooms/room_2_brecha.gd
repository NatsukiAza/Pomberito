extends "res://scenes/rooms/meadow_room_base.gd"

func _build_layout() -> void:
	# SALA DE ASCENSO VERTICAL (320x340): empezás abajo de todo y tenés que trepar hasta la copa arriba
	room_size = Vector2(320, 340)
	spawn_pos = Vector2(32, 304)
	exit_rect = Rect2(246, 12, 54, 10)
	exit_direction_label = "^ SUBÍ A LA COPA ^"
	hint_text = "ASCENSO: pisá libélulas, dasheá por arriba de las Avispas [DASH] y usá Abajo+Dash en la Tortuga [DASH v]."

	# Base inferior
	add_grass_block(Rect2(0, 312, 96, 28))
	add_spikes(Rect2(100, 332, 220, 8))

	# Escalón 1 (derecha baja) con Tortuga Acorazada (Abajo+Dash te da un súper rebote hacia arriba)
	add_grass_block(Rect2(142, 274, 84, 14))
	add_armored_turtle(Vector2(182, 274), 152.0, 214.0, 22.0)

	# Pared derecha para wall-jump + Avispa de Viento hacia el centro (dasheá por encima)
	add_grass_block(Rect2(276, 196, 18, 74))
	add_wind_wasp(Vector2(214, 218), 4.5, 3.8)

	# Escalón 2 (izquierda media) con escarabajo clásico
	add_grass_block(Rect2(44, 184, 86, 14))
	add_beetle(Vector2(86, 184), 54.0, 120.0, 42.0)

	# Pared izquierda + libélula y avispa eléctrica en diagonal hacia la copa superior derecha
	add_grass_block(Rect2(16, 88, 16, 92))
	add_dragonfly(Vector2(104, 126), 5.0, 3.4)
	add_wind_wasp(Vector2(184, 82), 4.5, 4.0)

	# Plataforma de la copa superior donde está el portal de salida hacia arriba
	add_grass_block(Rect2(228, 44, 92, 16))
