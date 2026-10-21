extends "res://scenes/rooms/meadow_room_base.gd"

func _build_layout() -> void:
	room_size = Vector2(320, 180)
	spawn_pos = Vector2(28, 148)
	exit_rect = Rect2(310, 96, 10, 56)
	exit_direction_label = "SALIDA ->"
	hint_text = ""

	add_grass_block(Rect2(0, 154, 320, 26))

	var shrine := add_reward_shrine(Vector2(160, 154))
	if RunState.chosen_upgrade == "":
		set_exit_locked(true)
		shrine.connect("upgrade_selected", func(_id: String) -> void:
			set_exit_locked(false)
		)
