extends CharacterBody2D

const PixelArt := preload("res://scenes/pixel_art.gd")

const GRAVITY_UP: float = 550.0
const GRAVITY_DOWN: float = 780.0
const MAX_FALL: float = 245.0
const ACCEL_GROUND: float = 980.0
const ACCEL_AIR: float = 720.0
const FRICTION_GROUND: float = 1080.0
const FRICTION_SKID: float = 310.0
const ACCEL_SKID_TURN: float = 540.0
const MOMENTUM_MIN_SPEED: float = 54.0
const MOMENTUM_BUILD_RATE: float = 4.2
const COYOTE_TIME: float = 0.11
const JUMP_BUFFER_TIME: float = 0.12
const DASH_SPEED: float = 252.0
const DIAGONAL_DASH_BOOST: float = 1.08
const DASH_DURATION: float = 0.16
const DASH_CORNER_WINDOW: float = 0.045
const WALL_SLIDE_MAX: float = 54.0
const WALL_JUMP_X: float = 152.0
const STOMP_BOUNCE_Y: float = -216.0

var prev_global_position: Vector2 = Vector2.ZERO
var _sprite: Sprite2D
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_post_grace: float = 0.0
var _dash_elapsed: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _trail_cooldown: float = 0.0
var _facing: int = 1
var _invuln_timer: float = 0.0
var _stomp_grace_timer: float = 0.0
var _was_on_floor: bool = false
var _fall_limit_y: float = 220.0
var _run_momentum: float = 0.0
var _is_skidding: bool = false
var _anim_pose: String = "idle"
var _run_cycle: float = 0.0
var _skid_dust_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	prev_global_position = global_position

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 14)
	col.shape = rect
	col.position = Vector2(0, -7)
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -9)
	_sprite.texture = PixelArt.cat_texture(true)
	add_child(_sprite)

	RunState.stats_changed.connect(_sync_sprite)
	_sync_sprite()

func set_fall_limit(limit_y: float) -> void:
	_fall_limit_y = limit_y

func _sync_sprite() -> void:
	if _sprite != null:
		_sprite.texture = PixelArt.cat_texture(RunState.dashes_left > 0, _anim_pose)

func is_skidding() -> bool:
	return _is_skidding

func get_anim_pose() -> String:
	return _anim_pose

# --- Consultas de combate para los 3 tipos de enemigos ---

func is_dashing() -> bool:
	return _dash_timer > 0.0 or _dash_post_grace > 0.0

func is_down_dashing() -> bool:
	# Dash hacia abajo (Abajo puro o diagonal Abajo-Derecha / Abajo-Izquierda)
	return (_dash_timer > 0.0 or _dash_post_grace > 0.0) and _dash_dir.y > 0.35

func is_above_enemy(enemy_global_pos: Vector2, tolerance_px: float = 6.0) -> bool:
	# Verifica de forma súper generosa si el gato viene por encima del enemigo:
	# 1) Estaba por encima en el frame anterior, o
	# 2) Sus pies están arriba del centro-bajo del enemigo, o
	# 3) El centro del gato está más alto que el enemigo
	var was_above_prev := prev_global_position.y <= enemy_global_pos.y + 3.0
	var feet_above_now := global_position.y <= enemy_global_pos.y + tolerance_px
	var cat_center_above := (global_position.y - 7.0) <= (enemy_global_pos.y + 1.0)
	var moving_down_or_dashing := velocity.y >= -55.0 or is_down_dashing() or is_dashing()
	return (was_above_prev or feet_above_now or cat_center_above) and moving_down_or_dashing

func is_dash_slashing_over(enemy_global_pos: Vector2) -> bool:
	# Para enemigos que mueren dasheando por encima: estar en dash y pasar por su mitad superior o sobre su cabeza
	if not is_dashing():
		return false
	return (global_position.y - 4.0) <= (enemy_global_pos.y + 6.0)

func has_stomp_grace() -> bool:
	return _stomp_grace_timer > 0.0 or _invuln_timer > 0.0

func bounce_from_stomp(custom_bounce_y: float = STOMP_BOUNCE_Y) -> void:
	_dash_timer = 0.0
	_dash_post_grace = 0.0
	velocity.y = custom_bounce_y
	_stomp_grace_timer = 0.24
	_sprite.scale = Vector2(1.34, 0.70)
	_sprite.rotation = 0.0
	RunState.register_stomp()

func dash_slash_boost() -> void:
	# Cuando matás a un enemigo dasheando por encima, recargás dash y mantenés vuelo con un pequeño impulso arriba
	_stomp_grace_timer = 0.24
	if velocity.y > -125.0:
		velocity.y = -135.0
	_sprite.scale = Vector2(1.30, 0.74)
	RunState.register_stomp()

func harmless_shell_bounce() -> void:
	# Si saltás normal sobre una Tortuga Acorazada sin hacer dash hacia abajo, rebotás sin recibir daño
	_dash_timer = 0.0
	velocity.y = -175.0
	_stomp_grace_timer = 0.20
	_sprite.scale = Vector2(1.22, 0.80)
	RunState.play_sfx("jump")

func take_contact_hit(from_x: float) -> void:
	if _invuln_timer > 0.0 or _stomp_grace_timer > 0.0:
		return
	_invuln_timer = 0.80
	_dash_timer = 0.0
	_dash_post_grace = 0.0
	_sprite.rotation = 0.0
	var dir_x := -1.0 if global_position.x < from_x else 1.0
	velocity = Vector2(dir_x * 138.0, -148.0)
	RunState.damage_player(1, false)

func _physics_process(delta: float) -> void:
	prev_global_position = global_position

	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		_sprite.modulate.a = 0.45 if int(_invuln_timer * 20.0) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0

	if _stomp_grace_timer > 0.0:
		_stomp_grace_timer -= delta
	if _dash_post_grace > 0.0:
		_dash_post_grace -= delta

	var input_vec := _read_move_input()
	if input_vec.x != 0.0:
		_facing = 1 if input_vec.x > 0.0 else -1
		_sprite.flip_h = (_facing < 0)

	if is_on_floor():
		if not _was_on_floor:
			_sprite.scale = Vector2(1.26, 0.76)
		_coyote_timer = COYOTE_TIME
		if _dash_timer <= 0.0:
			RunState.refill_dashes()
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
	_was_on_floor = is_on_floor()

	if _pressed_jump_just_now():
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

	# 1. Dash en 8 direcciones con soporte explícito de las 4 esquinas
	if _pressed_dash_just_now() and RunState.consume_dash():
		_start_dash(input_vec)

	if _dash_timer > 0.0:
		_dash_elapsed += delta
		_dash_timer -= delta

		if _dash_elapsed <= DASH_CORNER_WINDOW and input_vec.x != 0.0 and input_vec.y != 0.0:
			_set_dash_direction(input_vec)

		var spd := DASH_SPEED * (DIAGONAL_DASH_BOOST if (_dash_dir.x != 0.0 and _dash_dir.y != 0.0) else 1.0)
		velocity = _dash_dir * spd
		move_and_slide()

		_trail_cooldown -= delta
		if _trail_cooldown <= 0.0:
			_spawn_dash_afterimage()
			_trail_cooldown = 0.032

		if _dash_timer <= 0.0:
			_dash_post_grace = 0.08
			_sprite.rotation = 0.0
			if _dash_dir.y < 0.0:
				velocity.y *= 0.68
				velocity.x *= 0.85

		_recover_squash(delta)
		return

	# 2. Movimiento horizontal con aceleración, momentum de carrera y deslizamiento al frenar (skid)
	var target_vx := input_vec.x * RunState.move_speed
	var accel := ACCEL_GROUND if is_on_floor() else ACCEL_AIR
	_is_skidding = false

	if absf(input_vec.x) > 0.01:
		var reversing_on_floor := is_on_floor() and (input_vec.x * velocity.x < -25.0) and _run_momentum >= 0.24
		if reversing_on_floor:
			# Frenada derrapando al cambiar de dirección tras haber ganado momentum
			_is_skidding = true
			velocity.x = move_toward(velocity.x, target_vx, ACCEL_SKID_TURN * delta)
		else:
			velocity.x = move_toward(velocity.x, target_vx, accel * delta)
			if is_on_floor() and absf(velocity.x) >= MOMENTUM_MIN_SPEED:
				_run_momentum = minf(1.0, _run_momentum + MOMENTUM_BUILD_RATE * delta)
	elif is_on_floor():
		if _run_momentum >= 0.22 and absf(velocity.x) > 16.0:
			# Al soltar la tecla tras correr con momentum, se desliza un poquito antes de frenar
			_is_skidding = true
			velocity.x = move_toward(velocity.x, 0.0, FRICTION_SKID * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION_GROUND * delta)
			_run_momentum = 0.0
		if absf(velocity.x) <= 16.0:
			_run_momentum = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, (ACCEL_AIR * 0.42) * delta)
		if absf(velocity.x) >= MOMENTUM_MIN_SPEED:
			_run_momentum = minf(1.0, _run_momentum + (MOMENTUM_BUILD_RATE * 0.65) * delta)

	# 3. Gravedad y deslizamiento en pared
	var on_wall_sliding := is_on_wall_only() and velocity.y > 0.0 and input_vec.x != 0.0
	if not is_on_floor():
		var grav := GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN
		velocity.y = minf(velocity.y + grav * delta, WALL_SLIDE_MAX if on_wall_sliding else MAX_FALL)

	# 4. Salto con coyote time, jump buffer y wall jump
	if _jump_buffer_timer > 0.0:
		if _coyote_timer > 0.0:
			_jump_buffer_timer = 0.0
			_coyote_timer = 0.0
			velocity.y = -RunState.jump_speed
			_sprite.scale = Vector2(0.76, 1.32)
			RunState.play_sfx("jump")
		elif is_on_wall_only():
			_jump_buffer_timer = 0.0
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x * WALL_JUMP_X
			velocity.y = -RunState.jump_speed * 0.95
			_sprite.scale = Vector2(0.76, 1.32)
			RunState.play_sfx("jump")

	# 5. Salto corto si soltás el botón mientras subís
	if _released_jump_just_now() and velocity.y < -60.0:
		velocity.y *= 0.52

	move_and_slide()
	_update_cat_animation(delta, input_vec)
	_recover_squash(delta)

	if global_position.y > _fall_limit_y:
		RunState.damage_player(1, true)

func _start_dash(input_vec: Vector2) -> void:
	_dash_elapsed = 0.0
	_dash_timer = DASH_DURATION
	_dash_post_grace = 0.08
	_trail_cooldown = 0.0
	_is_skidding = false
	_run_momentum = 1.0
	_set_dash_direction(input_vec)
	var is_diag := absf(_dash_dir.x) > 0.1 and absf(_dash_dir.y) > 0.1
	velocity = _dash_dir * DASH_SPEED * (DIAGONAL_DASH_BOOST if is_diag else 1.0)
	_sprite.scale = Vector2(1.36, 0.68)
	RunState.play_sfx("dash")
	RunState.camera_shake_requested.emit(2.2)
	_spawn_dash_afterimage()

func _set_dash_direction(input_vec: Vector2) -> void:
	var sx := signf(input_vec.x)
	var sy := signf(input_vec.y)
	if sx == 0.0 and sy == 0.0:
		_dash_dir = Vector2(float(_facing), 0.0)
	else:
		_dash_dir = Vector2(sx, sy).normalized()

	if sx != 0.0 and sy != 0.0:
		_sprite.rotation = deg_to_rad(14.0 * sx * sy)
	else:
		_sprite.rotation = 0.0

func _spawn_dash_afterimage() -> void:
	if get_parent() == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = _sprite.texture
	ghost.flip_h = _sprite.flip_h
	ghost.global_position = _sprite.global_position
	ghost.rotation = _sprite.rotation
	ghost.modulate = Color(0.55, 0.92, 1.0, 0.68) if (_dash_dir.x != 0.0 and _dash_dir.y != 0.0) else Color(1.0, 0.78, 0.45, 0.58)
	ghost.z_index = -1
	get_parent().add_child(ghost)

	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tw.tween_callback(ghost.queue_free)

func _recover_squash(delta: float) -> void:
	_sprite.scale.x = lerpf(_sprite.scale.x, 1.0, delta * 12.0)
	_sprite.scale.y = lerpf(_sprite.scale.y, 1.0, delta * 12.0)

func _update_cat_animation(delta: float, input_vec: Vector2) -> void:
	var new_pose := "idle"
	if _is_skidding:
		new_pose = "skid"
		# Mirar hacia el sentido en el que se viene deslizando y clavar las patas adelante
		if absf(velocity.x) > 6.0:
			_sprite.flip_h = (velocity.x < 0.0)
		_sprite.rotation = deg_to_rad(-7.0 * signf(velocity.x))
		_sprite.position.y = -8.0
		_skid_dust_timer -= delta
		if _skid_dust_timer <= 0.0:
			_spawn_skid_dust()
			_skid_dust_timer = 0.055
	elif not is_on_floor():
		new_pose = "run_1" if absf(velocity.x) > 28.0 else "idle"
		_sprite.rotation = deg_to_rad(clampf(velocity.x * 0.035, -6.0, 6.0))
		_sprite.position.y = -9.0
	elif absf(velocity.x) > 14.0 and absf(input_vec.x) > 0.01:
		var speed_ratio := clampf(absf(velocity.x) / maxf(1.0, RunState.move_speed), 0.55, 1.45)
		_run_cycle += delta * 11.5 * speed_ratio
		var frame_idx := int(_run_cycle) % 2
		new_pose = "run_1" if frame_idx == 0 else "run_2"
		_sprite.rotation = deg_to_rad(4.0 * signf(velocity.x))
		_sprite.position.y = -9.0 - (0.8 if frame_idx == 1 else 0.0)
	else:
		_run_cycle = 0.0
		new_pose = "idle"
		_sprite.rotation = 0.0
		_sprite.position.y = -9.0

	if new_pose != _anim_pose:
		_anim_pose = new_pose
		_sync_sprite()

func _spawn_skid_dust() -> void:
	if get_parent() == null:
		return
	var puff := ColorRect.new()
	puff.color = Color(0.95, 0.93, 0.82, 0.85)
	var slide_dir := signf(velocity.x) if absf(velocity.x) > 1.0 else float(_facing)
	puff.position = global_position + Vector2(slide_dir * 5.0 - 2.0, -3.0)
	puff.size = Vector2(3, 3)
	get_parent().add_child(puff)

	var tw := puff.create_tween()
	tw.set_parallel(true)
	tw.tween_property(puff, "position", puff.position + Vector2(-slide_dir * 6.0, -5.0), 0.18)
	tw.tween_property(puff, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(puff.queue_free)

func _read_move_input() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0
	if Input.is_key_pressed(KEY_Q):
		v = Vector2(-1.0, -1.0)
	elif Input.is_key_pressed(KEY_E):
		v = Vector2(1.0, -1.0)
	return v

var _prev_jump_down: bool = false
var _prev_dash_down: bool = false

func _is_jump_held() -> bool:
	return Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_C)

func _is_dash_held() -> bool:
	return Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_E)

func _pressed_jump_just_now() -> bool:
	var held := _is_jump_held()
	var just := held and not _prev_jump_down
	_prev_jump_down = held
	return just

func _released_jump_just_now() -> bool:
	return not _is_jump_held()

func _pressed_dash_just_now() -> bool:
	var held := _is_dash_held()
	var just := held and not _prev_dash_down
	_prev_dash_down = held
	return just
