extends SceneTree

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	print("=== VERIFICANDO MISHI V3: HITBOX SUPERIOR + 3 TIPOS DE ENEMIGOS ===")
	var run_state := root.get_node("RunState")
	assert(run_state != null, "RunState autoload debe existir")

	var demo_packed: PackedScene = load("res://scenes/demo_run.tscn")
	assert(demo_packed != null, "DemoRun debe cargar")
	var demo := demo_packed.instantiate()
	root.add_child(demo)
	await process_frame
	await process_frame

	# 1. Recorrer las 6 salas y comprobar que cargan con los nuevos enemigos
	var expected_heights: Array[float] = [180.0, 340.0, 340.0, 180.0, 360.0, 250.0]
	for idx in range(run_state.ROOM_PATHS.size()):
		demo.call("load_room", idx)
		await process_frame
		await process_frame
		var room: Node2D = demo.get("_current_room")
		var rsize: Vector2 = room.call("get_room_size")
		assert(is_equal_approx(rsize.y, expected_heights[idx]), "Altura de sala inesperada en sala " + str(idx))
		print("[OK] Sala verificada (", rsize, "): ", run_state.ROOM_TITLES[idx])

	var room: Node2D = demo.get("_current_room")
	var cat: CharacterBody2D = room.call("get_cat")
	assert(cat != null, "El gato debe existir en la sala")

	# 2. Verificar hitbox superior generosa (aunque en el frame actual el pie haya penetrado 3px dentro del enemigo)
	var enemy_pos := Vector2(120.0, 150.0)
	cat.set("prev_global_position", Vector2(120.0, 141.0))
	cat.global_position = Vector2(120.0, 151.0) # Ya penetró dentro del cuerpo por velocidad alta
	cat.velocity = Vector2(0.0, 220.0)
	assert(cat.call("is_above_enemy", enemy_pos, 5.0) == true, "Debe detectar pisotón aunque haya penetrado en un frame")
	print("[OK] Hitbox superior con prev_global_position verificada sin falsos daños.")

	# 3. Verificar Avispa de Viento (muere dasheando por encima)
	var wasp_script: GDScript = load("res://scenes/enemies/wind_wasp.gd")
	var wasp: Area2D = wasp_script.new()
	wasp.position = Vector2(150.0, 120.0)
	room.add_child(wasp)
	await process_frame
	cat.global_position = Vector2(150.0, 118.0)
	cat.call("_start_dash", Vector2(1.0, 0.0))
	wasp.call("_resolve_player_contact", cat)
	assert(wasp.get("_dead") == true, "La Avispa debe morir al pasarle con dash por encima")
	print("[OK] Enemigo Tipo 2 (Avispa de Viento - matar con Dash por encima) verificado.")

	# 4. Verificar Tortuga Acorazada (rebota con salto normal y muere con Dash hacia abajo)
	var turtle_script: GDScript = load("res://scenes/enemies/armored_turtle.gd")
	var turtle: Area2D = turtle_script.new()
	turtle.position = Vector2(180.0, 150.0)
	room.add_child(turtle)
	await process_frame

	# Salto normal: no muere ni hace daño
	cat.set("_dash_time", 0.0)
	cat.set("_dash_post_grace", 0.0)
	cat.set("prev_global_position", Vector2(180.0, 140.0))
	cat.global_position = Vector2(180.0, 145.0)
	cat.velocity = Vector2(0.0, 120.0)
	var hp_before: int = run_state.hp
	turtle.call("_resolve_player_contact", cat)
	assert(turtle.get("_dead") == false, "La Tortuga NO debe morir con un salto común")
	assert(run_state.hp == hp_before, "Saltar sobre el caparazón de la Tortuga no debe hacer daño")

	# Dash hacia abajo: rompe el caparazón y la mata
	cat.set("prev_global_position", Vector2(180.0, 140.0))
	cat.global_position = Vector2(180.0, 146.0)
	cat.call("_start_dash", Vector2(0.0, 1.0))
	turtle.call("_resolve_player_contact", cat)
	assert(turtle.get("_dead") == true, "La Tortuga debe morir con Dash hacia abajo")
	print("[OK] Enemigo Tipo 3 (Tortuga Acorazada - matar con Dash hacia abajo) verificado.")

	# 5. Verificar animación de correr (run_1 / run_2) y deslizamiento con momentum (skid)
	var pixel_art: GDScript = load("res://scenes/pixel_art.gd")
	var tex_run1: ImageTexture = pixel_art.call("cat_texture", true, "run_1")
	var tex_run2: ImageTexture = pixel_art.call("cat_texture", true, "run_2")
	var tex_skid: ImageTexture = pixel_art.call("cat_texture", true, "skid")
	assert(tex_run1 != null and tex_run2 != null and tex_skid != null, "Texturas de carrera y derrape deben existir")

	cat.set("_is_skidding", true)
	cat.velocity = Vector2(95.0, 0.0)
	cat.call("_update_cat_animation", 0.016, Vector2.ZERO)
	assert(cat.call("get_anim_pose") == "skid", "Debe entrar en pose skid al deslizarse por momentum")
	print("[OK] Animación de carrera (run_1/run_2) y deslizamiento con momentum (skid + polvo) verificados.")

	demo.queue_free()
	await process_frame
	print("=== TODAS LAS PRUEBAS DE MISHI V3 PASARON CON EXITO ===")
	quit(0)
