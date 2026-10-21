extends Area2D

# ENEMIGO TIPO 2: AVISPA DE VIENTO
# Solo muere cuando le pasás por encima haciendo DASH (horizontal o diagonal).
# Si le saltás encima sin dash, rebotás suave sin matarla y sin recibir daño.

const PixelArt := preload("res://scenes/pixel_art.gd")

@export var hover_amplitude: float = 5.0
@export var hover_speed: float = 4.0

var _base_pos: Vector2
var _time: float = 0.0
var _sprite: Sprite2D
var _tag: Label
var _dead: bool = false

func _ready() -> void:
	_base_pos = position
	collision_layer = 4
	collision_mask = 2
	monitoring = true

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 15)
	col.shape = rect
	col.position = Vector2(0, -6)
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -6)
	_sprite.texture = PixelArt.wind_wasp_texture()
	add_child(_sprite)

	_tag = Label.new()
	_tag.text = "DASH"
	_tag.position = Vector2(-12, -21)
	_tag.add_theme_font_size_override("font_size", 6)
	_tag.add_theme_color_override("font_color", Color("266e8a"))
	add_child(_tag)

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

	if body.call("is_dash_slashing_over", global_position):
		_dead = true
		body.call("dash_slash_boost")
		queue_free()
	elif body.call("is_above_enemy", global_position, 6.0):
		# Si le caés encima sin estar dasheando, rebotás sin daño para poder preparar el dash
		body.call("harmless_shell_bounce")
	elif not body.call("has_stomp_grace"):
		body.call("take_contact_hit", global_position.x)
