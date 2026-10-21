extends CanvasLayer

var _hp_label: Label
var _dash_label: Label
var _room_label: Label
var _upgrade_label: Label
var _victory_panel: PanelContainer
var _victory_stats: Label

func _ready() -> void:
	layer = 20
	_build_hud()
	RunState.stats_changed.connect(refresh)
	refresh()

func _build_hud() -> void:
	var top_bar := ColorRect.new()
	top_bar.color = Color(0.08, 0.14, 0.10, 0.78)
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(320, 16)
	add_child(top_bar)

	_hp_label = Label.new()
	_hp_label.position = Vector2(6, 2)
	_hp_label.add_theme_font_size_override("font_size", 8)
	_hp_label.add_theme_color_override("font_color", Color("ff6b7a"))
	add_child(_hp_label)

	_dash_label = Label.new()
	_dash_label.position = Vector2(88, 2)
	_dash_label.add_theme_font_size_override("font_size", 8)
	_dash_label.add_theme_color_override("font_color", Color("73e8ff"))
	add_child(_dash_label)

	_upgrade_label = Label.new()
	_upgrade_label.position = Vector2(158, 2)
	_upgrade_label.add_theme_font_size_override("font_size", 8)
	_upgrade_label.add_theme_color_override("font_color", Color("ffe37d"))
	add_child(_upgrade_label)

	_room_label = Label.new()
	_room_label.position = Vector2(214, 2)
	_room_label.add_theme_font_size_override("font_size", 8)
	_room_label.add_theme_color_override("font_color", Color("d8f7dc"))
	add_child(_room_label)

	# Placa final al vencer al Jabalí del Claro
	_victory_panel = PanelContainer.new()
	_victory_panel.position = Vector2(44, 38)
	_victory_panel.size = Vector2(232, 104)
	_victory_panel.visible = false

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.12, 0.09, 0.95)
	sb.border_color = Color("ffe37d")
	sb.set_border_width_all(2)
	sb.set_content_margin_all(8)
	_victory_panel.add_theme_stylebox_override("panel", sb)
	add_child(_victory_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_victory_panel.add_child(vbox)

	var title := Label.new()
	title.text = "¡CLARO COMPLETADO! — DEMO SUPERADA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color("ffe37d"))
	vbox.add_child(title)

	_victory_stats = Label.new()
	_victory_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_victory_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_victory_stats.add_theme_font_size_override("font_size", 8)
	_victory_stats.add_theme_color_override("font_color", Color("e6faea"))
	vbox.add_child(_victory_stats)

	var restart_btn := Button.new()
	restart_btn.text = "Jugar otra corrida [R]"
	restart_btn.add_theme_font_size_override("font_size", 8)
	restart_btn.pressed.connect(func() -> void:
		_victory_panel.visible = false
		RunState.reset_run()
		RunState.run_reset_requested.emit()
	)
	vbox.add_child(restart_btn)

func refresh() -> void:
	var hearts_full := "♥".repeat(RunState.hp)
	var hearts_empty := "·".repeat(maxi(0, RunState.max_hp - RunState.hp))
	_hp_label.text = "VIDA " + hearts_full + hearts_empty

	var dashes_full := "⚡".repeat(RunState.dashes_left)
	var dashes_empty := "·".repeat(maxi(0, RunState.max_dashes - RunState.dashes_left))
	_dash_label.text = "DASH " + dashes_full + dashes_empty

	var up_txt := ""
	match RunState.chosen_upgrade:
		"extra_dash":
			up_txt = "[2xDash]"
		"extra_heart":
			up_txt = "[+Vida]"
		"light_paws":
			up_txt = "[Veloz]"
	_upgrade_label.text = up_txt

	if RunState.current_room_index >= 0 and RunState.current_room_index < RunState.ROOM_TITLES.size():
		_room_label.text = RunState.ROOM_TITLES[RunState.current_room_index]

func show_victory_banner() -> void:
	RunState.run_completed = true
	_victory_stats.text = "Derrotaste al Jabalí del Monte a pisotón limpio.\nPisotones en la corrida: %d | Vida restante: %d/%d\nPresioná [R] o el botón para reiniciar la ruta." % [
		RunState.total_stomps,
		RunState.hp,
		RunState.max_hp
	]
	_victory_panel.visible = true
