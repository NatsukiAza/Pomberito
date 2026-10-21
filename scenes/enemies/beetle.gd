extends Area2D

const PixelArt := preload("res://scenes/pixel_art.gd")

@export var patrol_left_x: float = 100.0
@export var patrol_right_x: float = 180.0
@export var speed: float = 38.0

var _dir: float = 1.0
var _sprite: Sprite2D
var _dead: bool = false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true

	# Hitbox amplia y más alta en el lomo para que el pisotón entre siempre limpio
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 13)
	col.shape = rect
	col.position = Vector2(0, -6.5)
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -6)
	_sprite.texture = PixelArt.beetle_texture()
	add_child(_sprite)

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
	# Tipo 1 (Escarabajo): muere si le caés encima (salto o dash hacia abajo)
	if body.call("is_above_enemy", global_position, 5.0) or body.call("is_down_dashing"):
		_dead = true
		body.call("bounce_from_stomp")
		queue_free()
	elif not body.call("has_stomp_grace"):
		body.call("take_contact_hit", global_position.x)
