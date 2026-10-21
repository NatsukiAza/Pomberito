extends Node2D

signal upgrade_selected(upgrade_id: String)

var _panel: PanelContainer
var _buttons: Array[Button] = []

const UPGRADES := [
	{
		"id": "extra_dash",
		"title": "[1] Pluma de Viento (+1 Dash)",
		"desc": "Subís a 2 cargas de dash en el aire. Pisar enemigos sigue devolviendo 1."
	},
	{
		"id": "extra_heart",
		"title": "[2] Fruto del Monte (+1 Corazón)",
		"desc": "Aumenta tu vida máxima a 4 corazones y te cura por completo."
	},
	{
		"id": "light_paws",
		"title": "[3] Patas Ligeras (+Velocidad y Salto)",
		"desc": "Corrés más rápido por el pasto y ganás más altura en cada salto."
	}
]

func _ready() -> void:
	_build_pedestal()
	_build_choice_ui()
	if RunState.chosen_upgrade != "":
		_mark_already_chosen()

func _build_pedestal() -> void:
	var stone := ColorRect.new()
	stone.color = Color("7b8480")
	stone.position = Vector2(-18, -22)
	stone.size = Vector2(36, 22)
	add_child(stone)

	var moss := ColorRect.new()
	moss.color = Color("4eb857")
	moss.position = Vector2(-20, -24)
	moss.size = Vector2(40, 4)
	add_child(moss)

func _build_choice_ui() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(-128, -118)
	_panel.size = Vector2(256, 86)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.11, 0.92)
	sb.border_color = Color("7de086")
	sb.set_border_width_all(1)
	sb.set_content_margin_all(5)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_panel.add_child(vbox)

	var header := Label.new()
	header.text = "SANTUARIO DEL CLARO — Elegí 1 bendición (teclas 1, 2, 3 o click):"
	header.add_theme_font_size_override("font_size", 8)
	header.add_theme_color_override("font_color", Color("ffe787"))
	vbox.add_child(header)

	for u in UPGRADES:
		var btn := Button.new()
		btn.text = u["title"] + " — " + u["desc"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 7)
		var uid: String = u["id"]
		btn.pressed.connect(func() -> void:
			_choose(uid)
		)
		vbox.add_child(btn)
		_buttons.append(btn)

func _unhandled_input(event: InputEvent) -> void:
	if RunState.chosen_upgrade != "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				_choose("extra_dash")
			KEY_2, KEY_KP_2:
				_choose("extra_heart")
			KEY_3, KEY_KP_3:
				_choose("light_paws")

func _choose(upgrade_id: String) -> void:
	if RunState.chosen_upgrade != "":
		return
	RunState.apply_upgrade(upgrade_id)
	_mark_already_chosen()
	upgrade_selected.emit(upgrade_id)

func _mark_already_chosen() -> void:
	for b in _buttons:
		b.disabled = true
	if _panel:
		var lbl := Label.new()
		lbl.text = "Bendición activa: avanzá a la derecha ->"
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", Color("8ef59c"))
		_panel.get_child(0).add_child(lbl)
