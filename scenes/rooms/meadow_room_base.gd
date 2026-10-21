extends Node2D

signal room_exited()
signal boss_victory()

const CatScene := preload("res://scenes/player/cat.tscn")
const BeetleScript := preload("res://scenes/enemies/beetle.gd")
const DragonflyScript := preload("res://scenes/enemies/dragonfly.gd")
const WindWaspScript := preload("res://scenes/enemies/wind_wasp.gd")
const ArmoredTurtleScript := preload("res://scenes/enemies/armored_turtle.gd")
const BoarBossScript := preload("res://scenes/enemies/boar_boss.gd")
const ShrineScript := preload("res://scenes/rooms/reward_shrine.gd")

@export var room_size: Vector2 = Vector2(320, 180)
@export var spawn_pos: Vector2 = Vector2(24, 146)
@export var exit_rect: Rect2 = Rect2(310, 70, 10, 84)
@export var exit_direction_label: String = "SALIDA ->"
@export var hint_text: String = ""

var _cat: CharacterBody2D
var _exit_locked: bool = false
var _exit_gate_visual: ColorRect

func _ready() -> void:
	_build_layout()
	_build_meadow_backdrop()
	_build_screen_bounds()
	_spawn_cat()
	_build_exit_trigger()
	if hint_text != "":
		_build_hint_label(hint_text)

func _build_layout() -> void:
	pass

func get_cat() -> CharacterBody2D:
	return _cat

func get_room_size() -> Vector2:
	return room_size

func _build_meadow_backdrop() -> void:
	var w := room_size.x
	var h := room_size.y

	# Cielo crema de pradera cubriendo toda la altura vertical de la sala
	var sky := ColorRect.new()
	sky.color = Color("dff6e4")
	sky.position = Vector2(-24, -24)
	sky.size = Vector2(w + 48, h + 48)
	sky.z_index = -20
	add_child(sky)

	# Banda superior de cielo más fresco en salas altas
	var upper_sky := ColorRect.new()
	upper_sky.color = Color("c9eed4")
	upper_sky.position = Vector2(-24, -24)
	upper_sky.size = Vector2(w + 48, h * 0.48)
	upper_sky.z_index = -19
	add_child(upper_sky)

	# Sol suave con halo
	var sun_halo := ColorRect.new()
	sun_halo.color = Color(1.0, 0.97, 0.78, 0.45)
	sun_halo.position = Vector2(w - 76, 18)
	sun_halo.size = Vector2(34, 34)
	sun_halo.z_index = -19
	add_child(sun_halo)

	var sun := ColorRect.new()
	sun.color = Color("fff3b0")
	sun.position = Vector2(w - 70, 24)
	sun.size = Vector2(22, 22)
	sun.z_index = -18
	add_child(sun)

	# Nubes pixeladas a distintas alturas para dar referencia al subir/bajar
	var cloud_y := 28.0
	var c_idx := 0
	while cloud_y < h - 90.0:
		var cx := 34.0 if c_idx % 2 == 0 else 192.0
		var cloud := ColorRect.new()
		cloud.color = Color(1.0, 1.0, 0.96, 0.75)
		cloud.position = Vector2(cx, cloud_y)
		cloud.size = Vector2(46, 8)
		cloud.z_index = -18
		add_child(cloud)
		cloud_y += 74.0
		c_idx += 1

	# Colinas lejanas y cercanas apoyadas en la base de la sala
	var far_hills := Polygon2D.new()
	far_hills.color = Color("a8dbb4")
	far_hills.polygon = PackedVector2Array([
		Vector2(0, h), Vector2(0, h - 68), Vector2(58, h - 96),
		Vector2(132, h - 70), Vector2(214, h - 104), Vector2(286, h - 74),
		Vector2(w, h - 88), Vector2(w, h)
	])
	far_hills.z_index = -17
	add_child(far_hills)

	var near_hills := Polygon2D.new()
	near_hills.color = Color("7bc489")
	near_hills.polygon = PackedVector2Array([
		Vector2(0, h), Vector2(0, h - 44), Vector2(84, h - 66),
		Vector2(168, h - 48), Vector2(248, h - 70), Vector2(w, h - 52),
		Vector2(w, h)
	])
	near_hills.z_index = -16
	add_child(near_hills)

func _build_screen_bounds() -> void:
	var w := room_size.x
	var h := room_size.y
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)

	var left_col := CollisionShape2D.new()
	var left_shape := RectangleShape2D.new()
	left_shape.size = Vector2(8, h + 60)
	left_col.shape = left_shape
	left_col.position = Vector2(-4, h * 0.5)
	body.add_child(left_col)

	var right_col := CollisionShape2D.new()
	var right_shape := RectangleShape2D.new()
	right_shape.size = Vector2(8, h + 60)
	right_col.shape = right_shape
	right_col.position = Vector2(w + 4, h * 0.5)
	body.add_child(right_col)

	var top_col := CollisionShape2D.new()
	var top_shape := RectangleShape2D.new()
	top_shape.size = Vector2(w + 40, 8)
	top_col.shape = top_shape
	top_col.position = Vector2(w * 0.5, -4)
	body.add_child(top_col)

func add_grass_block(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = rect.position + rect.size * 0.5
	add_child(body)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	body.add_child(col)

	# Tierra con vetas más detalladas
	var dirt := ColorRect.new()
	dirt.color = Color("7a4e37")
	dirt.position = rect.position
	dirt.size = rect.size
	add_child(dirt)

	var mid_band := ColorRect.new()
	mid_band.color = Color("69412c")
	mid_band.position = Vector2(rect.position.x + 2, rect.position.y + minf(6.0, rect.size.y * 0.5))
	mid_band.size = Vector2(maxf(0.0, rect.size.x - 4), maxf(2.0, rect.size.y * 0.35))
	add_child(mid_band)

	var shade := ColorRect.new()
	shade.color = Color("4f2f1f")
	shade.position = Vector2(rect.position.x, rect.position.y + rect.size.y - 3)
	shade.size = Vector2(rect.size.x, 3)
	add_child(shade)

	# Capa de pasto verde arriba + flecos
	var grass := ColorRect.new()
	grass.color = Color("469c4b")
	grass.position = rect.position
	grass.size = Vector2(rect.size.x, mini(4, int(rect.size.y)))
	add_child(grass)

	var highlight := ColorRect.new()
	highlight.color = Color("6ed46e")
	highlight.position = rect.position
	highlight.size = Vector2(rect.size.x, 1)
	add_child(highlight)

	# Flores coral y amarillas
	var x := rect.position.x + 6.0
	var idx := 0
	while x < rect.position.x + rect.size.x - 6.0:
		var stem := ColorRect.new()
		stem.color = Color("347a38")
		stem.position = Vector2(x, rect.position.y - 2)
		stem.size = Vector2(2, 2)
		add_child(stem)

		if idx % 2 == 0:
			var petal := ColorRect.new()
			petal.color = Color("f26d6d") if idx % 4 == 0 else Color("ffd86b")
			petal.position = Vector2(x - 1, rect.position.y - 4)
			petal.size = Vector2(3, 2)
			add_child(petal)
		x += 18.0
		idx += 1

func add_spikes(rect: Rect2) -> void:
	var area := Area2D.new()
	area.collision_layer = 8
	area.collision_mask = 2
	area.position = rect.position + rect.size * 0.5
	add_child(area)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	area.add_child(col)

	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			RunState.damage_player(1, true)
	)

	var x := rect.position.x
	while x < rect.position.x + rect.size.x:
		var tri := Polygon2D.new()
		tri.color = Color("d9415d")
		tri.polygon = PackedVector2Array([
			Vector2(x, rect.position.y + rect.size.y),
			Vector2(x + 3, rect.position.y),
			Vector2(x + 6, rect.position.y + rect.size.y)
		])
		add_child(tri)
		x += 6.0

func add_beetle(pos: Vector2, left_x: float, right_x: float, spd: float = 38.0) -> Area2D:
	var b: Area2D = BeetleScript.new()
	b.position = pos
	b.patrol_left_x = left_x
	b.patrol_right_x = right_x
	b.speed = spd
	add_child(b)
	return b

func add_dragonfly(pos: Vector2, amp: float = 6.0, spd: float = 3.2) -> Area2D:
	var d: Area2D = DragonflyScript.new()
	d.position = pos
	d.hover_amplitude = amp
	d.hover_speed = spd
	add_child(d)
	return d

func add_wind_wasp(pos: Vector2, amp: float = 5.0, spd: float = 4.0) -> Area2D:
	var w: Area2D = WindWaspScript.new()
	w.position = pos
	w.hover_amplitude = amp
	w.hover_speed = spd
	add_child(w)
	return w

func add_armored_turtle(pos: Vector2, left_x: float, right_x: float, spd: float = 24.0) -> Area2D:
	var t: Area2D = ArmoredTurtleScript.new()
	t.position = pos
	t.patrol_left_x = left_x
	t.patrol_right_x = right_x
	t.speed = spd
	add_child(t)
	return t

func add_boar_boss(pos: Vector2, left_x: float, right_x: float) -> Area2D:
	var boss: Area2D = BoarBossScript.new()
	boss.position = pos
	boss.arena_left_x = left_x
	boss.arena_right_x = right_x
	add_child(boss)
	return boss

func add_reward_shrine(pos: Vector2) -> Node2D:
	var s: Node2D = ShrineScript.new()
	s.position = pos
	add_child(s)
	return s

func set_exit_locked(locked: bool) -> void:
	_exit_locked = locked
	if _exit_gate_visual != null:
		_exit_gate_visual.visible = locked

func _spawn_cat() -> void:
	_cat = CatScene.instantiate()
	_cat.position = spawn_pos
	_cat.call("set_fall_limit", room_size.y + 24.0)
	add_child(_cat)

func _build_exit_trigger() -> void:
	# Portal/arco dorado en exit_rect (puede estar arriba, abajo o a la derecha)
	var arch := ColorRect.new()
	arch.color = Color(1.0, 0.90, 0.42, 0.88)
	arch.position = exit_rect.position
	arch.size = exit_rect.size
	add_child(arch)

	var tag := Label.new()
	tag.text = exit_direction_label
	tag.position = exit_rect.position + Vector2(-28, -12)
	tag.add_theme_font_size_override("font_size", 7)
	tag.add_theme_color_override("font_color", Color("1f3824"))
	add_child(tag)

	_exit_gate_visual = ColorRect.new()
	_exit_gate_visual.color = Color("c93b4b")
	_exit_gate_visual.position = exit_rect.position
	_exit_gate_visual.size = exit_rect.size
	_exit_gate_visual.visible = _exit_locked
	add_child(_exit_gate_visual)

	var exit_area := Area2D.new()
	exit_area.collision_layer = 0
	exit_area.collision_mask = 2
	exit_area.position = exit_rect.position + exit_rect.size * 0.5
	add_child(exit_area)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = exit_rect.size + Vector2(6, 6)
	col.shape = shape
	exit_area.add_child(col)

	exit_area.body_entered.connect(func(body: Node2D) -> void:
		if not _exit_locked and body.is_in_group("player"):
			room_exited.emit()
	)

func _build_hint_label(txt: String) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.position = Vector2(8, spawn_pos.y - 44.0 if room_size.y > 200.0 and spawn_pos.y > 180.0 else 20.0)
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.add_theme_color_override("font_color", Color("1f3824"))
	add_child(lbl)
