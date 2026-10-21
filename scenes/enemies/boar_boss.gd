extends Area2D

signal boss_defeated()

const PixelArt := preload("res://scenes/pixel_art.gd")

enum BossState {
	CHARGE,
	LEAP_WINDUP,
	LEAP_AIR,
	LAND_RECOVERY,
	STUNNED
}

@export var arena_left_x: float = 34.0
@export var arena_right_x: float = 286.0
@export var floor_y: float = 224.0

var hp: int = 4
var _state: BossState = BossState.CHARGE
var _dir: float = -1.0
var _state_timer: float = 0.0
var _charge_timer: float = 1.35
var _vel: Vector2 = Vector2.ZERO
var _sprite: Sprite2D
var _hp_label: Label
var _state_hint: Label
var _dead: bool = false

func _ready() -> void:
	floor_y = position.y
	collision_layer = 4
	collision_mask = 2
	monitoring = true

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 15)
	col.shape = rect
	col.position = Vector2(0, -7.5)
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -7)
	_sprite.texture = PixelArt.boar_texture(false, false)
	add_child(_sprite)

	_hp_label = Label.new()
	_hp_label.position = Vector2(-30, -30)
	_hp_label.add_theme_font_size_override("font_size", 8)
	_hp_label.add_theme_color_override("font_color", Color("fff3d1"))
	add_child(_hp_label)

	_state_hint = Label.new()
	_state_hint.position = Vector2(-26, -40)
	_state_hint.add_theme_font_size_override("font_size", 7)
	_state_hint.add_theme_color_override("font_color", Color("ff6b7a"))
	add_child(_state_hint)

	_update_label()
	body_entered.connect(_on_body_entered)

func _is_enraged() -> bool:
	return hp <= 2

func _update_label() -> void:
	if _hp_label:
		_hp_label.text = "JABALÍ: " + "♦".repeat(hp)

func _physics_process(delta: float) -> void:
	if _dead:
		return

	match _state:
		BossState.CHARGE:
			_process_charge(delta)
		BossState.LEAP_WINDUP:
			_process_leap_windup(delta)
		BossState.LEAP_AIR:
			_process_leap_air(delta)
		BossState.LAND_RECOVERY:
			_process_land_recovery(delta)
		BossState.STUNNED:
			pass

	if _state == BossState.STUNNED:
		_state_timer -= delta
		_sprite.scale = _sprite.scale.lerp(Vector2.ONE, delta * 10.0)
		if _state_timer <= 0.0:
			_start_leap_windup()

	for body in get_overlapping_bodies():
		if body is Node2D:
			_on_body_entered(body)

func _process_charge(delta: float) -> void:
	_state_hint.text = ""
	var speed := 92.0 + float(4 - hp) * 24.0
	position.x += _dir * speed * delta
	_charge_timer -= delta

	if position.x <= arena_left_x:
		position.x = arena_left_x
		_dir = 1.0
		_sprite.flip_h = true
		RunState.camera_shake_requested.emit(2.0)
	elif position.x >= arena_right_x:
		position.x = arena_right_x
		_dir = -1.0
		_sprite.flip_h = false
		RunState.camera_shake_requested.emit(2.0)

	if _charge_timer <= 0.0:
		_start_leap_windup()

func _start_leap_windup() -> void:
	_state = BossState.LEAP_WINDUP
	_state_timer = 0.42 if _is_enraged() else 0.56
	_sprite.scale = Vector2(1.30, 0.72)
	_state_hint.text = "¡VA A SALTAR!"

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		_dir = 1.0 if player.global_position.x >= global_position.x else -1.0
		_sprite.flip_h = (_dir > 0.0)

func _process_leap_windup(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		_state = BossState.LEAP_AIR
		_state_hint.text = "¡EMBESTIDA AÉREA!"
		_sprite.scale = Vector2(0.78, 1.32)
		_sprite.texture = PixelArt.boar_texture(_is_enraged(), true)
		RunState.play_sfx("jump")

		# Apunta hacia la posición del gato para obligarlo a usar el dash diagonal
		var target_vx := _dir * (145.0 if _is_enraged() else 122.0)
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			var dx := clampf(player.global_position.x - global_position.x, -155.0, 155.0)
			target_vx = dx * 1.45
		_vel = Vector2(target_vx, -285.0 if _is_enraged() else -258.0)

func _process_leap_air(delta: float) -> void:
	_vel.y += 560.0 * delta
	position += _vel * delta

	if position.x <= arena_left_x:
		position.x = arena_left_x
		_vel.x = absf(_vel.x) * 0.75
		_sprite.flip_h = true
	elif position.x >= arena_right_x:
		position.x = arena_right_x
		_vel.x = -absf(_vel.x) * 0.75
		_sprite.flip_h = false

	if _vel.y > 0.0:
		_state_hint.text = "¡PISALO AHORA!"

	if position.y >= floor_y:
		position.y = floor_y
		_vel = Vector2.ZERO
		_state = BossState.LAND_RECOVERY
		_state_timer = 0.65 if _is_enraged() else 0.85
		_sprite.scale = Vector2(1.34, 0.70)
		_sprite.texture = PixelArt.boar_texture(_is_enraged(), false)
		_state_hint.text = "¡PISALO!"
		RunState.camera_shake_requested.emit(4.2)
		RunState.play_sfx("hurt")
		_spawn_ground_shockwaves()

func _process_land_recovery(delta: float) -> void:
	_state_timer -= delta
	_sprite.scale = _sprite.scale.lerp(Vector2.ONE, delta * 10.0)
	if _state_timer <= 0.0:
		_state = BossState.CHARGE
		_charge_timer = 1.05 if _is_enraged() else 1.45
		_state_hint.text = ""

func _spawn_ground_shockwaves() -> void:
	if get_parent() == null:
		return
	for dir_sign in [-1.0, 1.0]:
		var wave := Area2D.new()
		wave.collision_layer = 8
		wave.collision_mask = 2
		wave.position = Vector2(position.x + dir_sign * 14.0, floor_y - 5.0)
		get_parent().add_child(wave)

		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(10, 10)
		col.shape = shape
		wave.add_child(col)

		var rock := ColorRect.new()
		rock.color = Color("d9415d")
		rock.position = Vector2(-5, -5)
		rock.size = Vector2(10, 10)
		wave.add_child(rock)

		wave.body_entered.connect(func(body: Node2D) -> void:
			if body.is_in_group("player") and not body.call("has_stomp_grace"):
				body.call("take_contact_hit", wave.global_position.x)
		)

		var tw := wave.create_tween()
		tw.tween_property(wave, "position:x", wave.position.x + dir_sign * 145.0, 0.75)
		tw.tween_callback(wave.queue_free)

func _on_body_entered(body: Node2D) -> void:
	if _dead or not body.is_in_group("player"):
		return

	# Mientras el jabalí sube en pleno salto con los colmillos hacia arriba, no es pisable
	var rising_in_jump := (_state == BossState.LEAP_AIR and _vel.y < -35.0)

	if not rising_in_jump and (body.call("is_above_enemy", global_position, 8.0) or body.call("is_down_dashing")):
		body.call("bounce_from_stomp", -238.0)
		if _state != BossState.STUNNED:
			hp -= 1
			_state = BossState.STUNNED
			_state_timer = 0.50
			_state_hint.text = "¡GOLPEADO!"
			_sprite.texture = PixelArt.boar_texture(_is_enraged(), false)
			_update_label()
			if hp <= 0:
				_dead = true
				boss_defeated.emit()
				queue_free()
	elif not body.call("has_stomp_grace"):
		body.call("take_contact_hit", global_position.x)
