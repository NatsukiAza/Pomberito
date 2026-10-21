extends Node2D

const HudScript := preload("res://scenes/hud.gd")

var _room_holder: Node2D
var _current_room: Node2D
var _camera: Camera2D
var _hud: CanvasLayer
var _shake_amount: float = 0.0
var _transition_lock: bool = false

func _ready() -> void:
	_room_holder = Node2D.new()
	add_child(_room_holder)

	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	_camera.position = Vector2.ZERO
	_camera.enabled = true
	add_child(_camera)

	_hud = HudScript.new()
	add_child(_hud)

	RunState.room_restart_requested.connect(_on_room_restart)
	RunState.run_reset_requested.connect(_on_run_reset)
	RunState.camera_shake_requested.connect(_on_camera_shake)

	load_room(RunState.current_room_index)

func _process(delta: float) -> void:
	if _current_room != null and _current_room.has_method("get_cat"):
		var cat: Node2D = _current_room.call("get_cat")
		var rsize: Vector2 = _current_room.call("get_room_size")
		if cat != null:
			var target_x := clampf(cat.global_position.x - 160.0, 0.0, maxf(0.0, rsize.x - 320.0))
			var target_y := clampf(cat.global_position.y - 96.0, 0.0, maxf(0.0, rsize.y - 180.0))
			_camera.position.x = lerpf(_camera.position.x, roundf(target_x), delta * 10.0)
			_camera.position.y = lerpf(_camera.position.y, roundf(target_y), delta * 10.0)

	if _shake_amount > 0.01:
		_shake_amount = lerpf(_shake_amount, 0.0, delta * 14.0)
		_camera.offset = Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
	else:
		_camera.offset = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			RunState.reset_run()
			_on_run_reset()

func load_room(index: int) -> void:
	_transition_lock = true
	RunState.current_room_index = clampi(index, 0, RunState.ROOM_PATHS.size() - 1)
	RunState.refill_dashes()
	RunState.stats_changed.emit()

	if _current_room != null:
		_current_room.queue_free()
		_current_room = null

	var packed: PackedScene = load(RunState.ROOM_PATHS[RunState.current_room_index])
	_current_room = packed.instantiate()
	_room_holder.add_child(_current_room)

	if _current_room.has_method("get_cat"):
		var cat: Node2D = _current_room.call("get_cat")
		var rsize: Vector2 = _current_room.call("get_room_size")
		if cat != null:
			_camera.position = Vector2(
				clampf(cat.position.x - 160.0, 0.0, maxf(0.0, rsize.x - 320.0)),
				clampf(cat.position.y - 96.0, 0.0, maxf(0.0, rsize.y - 180.0))
			)

	_current_room.connect("room_exited", _on_room_exited)
	_current_room.connect("boss_victory", _on_boss_victory)
	call_deferred("_unlock_transition")

func _unlock_transition() -> void:
	_transition_lock = false

func _on_room_exited() -> void:
	if _transition_lock:
		return
	var next_idx := RunState.current_room_index + 1
	if next_idx < RunState.ROOM_PATHS.size():
		call_deferred("load_room", next_idx)
	else:
		_on_boss_victory()

func _on_boss_victory() -> void:
	RunState.play_sfx("upgrade")
	_hud.call("show_victory_banner")

func _on_room_restart() -> void:
	call_deferred("load_room", RunState.current_room_index)

func _on_run_reset() -> void:
	call_deferred("load_room", 0)

func _on_camera_shake(strength: float) -> void:
	_shake_amount = maxf(_shake_amount, strength)
