extends "res://scenes/rooms/meadow_room_base.gd"

func _build_layout() -> void:
	# Arena de dos pisos (320x250) para pelear contra el Jabalí Saltarín
	room_size = Vector2(320, 250)
	spawn_pos = Vector2(32, 168)
	exit_rect = Rect2(310, 168, 10, 56)
	exit_direction_label = "VICTORIA ->"
	hint_text = "JEFE JABALÍ: esquivá su SALTO y las ondas con Dash Diagonal [Arriba+Der/Izq] y pisalo al bajar (4 golpes)."
	set_exit_locked(true)

	# Piso principal de la arena y paredes altas para wall-jump
	add_grass_block(Rect2(0, 224, 320, 26))
	add_grass_block(Rect2(0, 44, 14, 180))
	add_grass_block(Rect2(306, 44, 14, 180))

	# Nivel medio de repisas
	add_grass_block(Rect2(24, 176, 54, 10))
	add_grass_block(Rect2(242, 176, 54, 10))

	# Nivel alto central y libélulas laterales para recargar dash en el aire
	add_grass_block(Rect2(124, 128, 72, 10))
	add_dragonfly(Vector2(68, 114), 5.0, 3.2)
	add_dragonfly(Vector2(252, 114), 5.0, 3.2)

	var boss := add_boar_boss(Vector2(220, 224), 28.0, 292.0)
	boss.connect("boss_defeated", func() -> void:
		set_exit_locked(false)
		boss_victory.emit()
	)
