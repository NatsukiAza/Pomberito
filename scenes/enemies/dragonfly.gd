extends Area2D

const PixelArt := preload("res://scenes/pixel_art.gd")

@export var hover_amplitude: float = 6.0
@export var hover_speed: float = 3.2

var _base_pos: Vector2
var _time: float = 0.0
var _sprite: Sprite2D
var _dead: bool = false

func _ready() -> void:
	_base_pos = position
	collision_layer = 4
	collision_mask = 2
	monitoring = true

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 14)
	col.shape = rect
	col.position = Vector2(0, -6)
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -6)
	_sprite.texture = PixelArt.dragonfly_texture()
	add_child(_sprite)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_time += delta * hover_speed
	position.y = _base_pos.y + sin(_time) * hover_amplitude

	for body in get_overlapping_bodies():
		if body is Node2D:
			_resolve_player_contact(body)

func _on_body_entered(body: Node2D) -> void:
	_resolve_player_contact(body)

func _resolve_player_contact(body: Node2D) -> void:
	if _dead or not body.is_in_group("player"):
		return
	# Tipo 1 aéreo (Libélula): muy permisiva al pisarla o cruzarla desde arriba
	if body.call("is_above_enemy", global_position, 7.0) or body.call("is_down_dashing"):
		_dead = true
		body.call("bounce_from_stomp", -224.0)
		queue_free()
	elif not body.call("has_stomp_grace"):
		body.call("take_contact_hit", global_position.x)
