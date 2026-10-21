extends "res://scenes/rooms/meadow_room_base.gd"

func _build_layout() -> void:
	room_size = Vector2(320, 180)
	spawn_pos = Vector2(22, 148)
	exit_rect = Rect2(310, 88, 10, 48)
	exit_direction_label = "SALIDA ->"
	hint_text = "3 ENEMIGOS: 1) Escarabajo = PISALO. 2) Avispa [DASH] = DASHEÁ por arriba. 3) Tortuga [DASH v] = Abajo+Dash [X]."

	add_grass_block(Rect2(0, 154, 76, 26))
	add_grass_block(Rect2(92, 146, 98, 34))
	add_grass_block(Rect2(210, 136, 110, 44))

	# 1) Escarabajo rojo: muere saltándole encima
	add_beetle(Vector2(138, 146), 102.0, 178.0, 36.0)
	# 2) Avispa eléctrica en la brecha: matala pasándole por encima con DASH [X]
	add_wind_wasp(Vector2(198, 118), 4.0, 3.8)
	# 3) Tortuga acorazada: matala saltando y haciendo DASH HACIA ABAJO [Abajo + X]
	add_armored_turtle(Vector2(262, 136), 224.0, 294.0, 22.0)
