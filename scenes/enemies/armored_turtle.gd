extends Area2D

# ENEMIGO TIPO 3: TORTUGA ACORAZADA DE ROCA
# Tiene caparazón duro: un salto normal rebota sin matarla.
# Solo muere si le hacés DASH HACIA ABAJO (Abajo + X o diagonal Abajo+Der/Izq + X).

const PixelArt := preload("res://scenes/pixel_art.gd")

@export var patrol_left_x: float = 100.0
@export var patrol_right_x: float = 180.0
@export var speed: float = 24.0

var _dir: float = 1.0
var _sprite: Sprite2D
var _tag: Label
var _dead: bool = false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 13)
	col.shape = rect
	col.position = Vector2(0, -6.5)
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -5)
	_sprite.texture = PixelArt.armored_turtle_texture()
	add_child(_sprite)

	_tag = Label.new()
	_tag.text = "DASH v"
	_tag.position = Vector2(-14, -20)
	_tag.add_theme_font_size_override("font_size", 6)
	_tag.add_theme_color_override("font_color", Color("324259"))
	add_child(_tag)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	position.x += _dir * speed * delta
	if position.x >= patrol_right_x:
		position.x = patrol_right_x
		_dir = -1.0
		_sprite.flip_h = true
	elif position.x <= patrol_left_x:
		position.x = patrol_left_x
		_dir = 1.0
		_sprite.flip_h = false

	for body in get_overlapping_bodies():
		if body is Node2D:
			_resolve_player_contact(body)

func _on_body_entered(body: Node2D) -> void:
	_resolve_player_contact(body)

func _resolve_player_contact(body: Node2D) -> void:
	if _dead or not body.is_in_group("player"):
		return

	if body.call("is_down_dashing") and body.call("is_above_enemy", global_position, 8.0):
		_dead = true
		# Súper rebote al romper el caparazón con dash hacia abajo
		body.call("bounce_from_stomp", -242.0)
		queue_free()
	elif body.call("is_above_enemy", global_position, 6.0):
		# Salto normal sobre el caparazón: rebota sin matarla y sin hacerte daño
		body.call("harmless_shell_bounce")
		_tag.text = "¡USÁ DASH ABAJO!"
	elif not body.call("has_stomp_grace"):
		body.call("take_contact_hit", global_position.x)
