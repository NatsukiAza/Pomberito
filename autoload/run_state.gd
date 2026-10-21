extends Node

signal stats_changed()
signal room_restart_requested()
signal run_reset_requested()
signal camera_shake_requested(strength: float)
signal reward_chosen(upgrade_id: String)

const ROOM_PATHS: Array[String] = [
	"res://scenes/rooms/room_1_pradera.tscn",
	"res://scenes/rooms/room_2_brecha.tscn",
	"res://scenes/rooms/room_3_claros.tscn",
	"res://scenes/rooms/room_4_santuario.tscn",
	"res://scenes/rooms/room_5_prueba.tscn",
	"res://scenes/rooms/room_6_jabali.tscn"
]

const ROOM_TITLES: Array[String] = [
	"1/6 — PRADERA DEL CLARO (->)",
	"2/6 — COPA DEL CEIBO (SUBÍ ^)",
	"3/6 — SUMIDERO DE RAÍCES (BAJÁ v)",
	"4/6 — SANTUARIO DE PIEDRA (->)",
	"5/6 — AGUJA DIAGONAL (SUBÍ ^)",
	"6/6 — JEFE: JABALÍ SALTARÍN"
]

const BASE_MAX_HP: int = 3
const BASE_MAX_DASHES: int = 1
const BASE_MOVE_SPEED: float = 112.0
const BASE_JUMP_SPEED: float = 225.0

var max_hp: int = BASE_MAX_HP
var hp: int = BASE_MAX_HP
var max_dashes: int = BASE_MAX_DASHES
var dashes_left: int = BASE_MAX_DASHES
var move_speed: float = BASE_MOVE_SPEED
var jump_speed: float = BASE_JUMP_SPEED

var current_room_index: int = 0
var chosen_upgrade: String = ""
var total_stomps: int = 0
var run_completed: bool = false

var _sfx_player: AudioStreamPlayer
var _sfx_bank: Dictionary = {}

func _ready() -> void:
	_setup_audio()
	reset_run()

func reset_run() -> void:
	max_hp = BASE_MAX_HP
	hp = BASE_MAX_HP
	max_dashes = BASE_MAX_DASHES
	dashes_left = BASE_MAX_DASHES
	move_speed = BASE_MOVE_SPEED
	jump_speed = BASE_JUMP_SPEED
	current_room_index = 0
	chosen_upgrade = ""
	total_stomps = 0
	run_completed = false
	stats_changed.emit()

func refill_dashes() -> void:
	if dashes_left != max_dashes:
		dashes_left = max_dashes
		stats_changed.emit()

func refund_one_dash() -> void:
	var next := mini(dashes_left + 1, max_dashes)
	if next != dashes_left:
		dashes_left = next
	stats_changed.emit()

func consume_dash() -> bool:
	if dashes_left <= 0:
		return false
	dashes_left -= 1
	stats_changed.emit()
	return true

func register_stomp() -> void:
	total_stomps += 1
	refund_one_dash()
	play_sfx("stomp")
	camera_shake_requested.emit(3.5)

func apply_upgrade(upgrade_id: String) -> void:
	chosen_upgrade = upgrade_id
	match upgrade_id:
		"extra_dash":
			max_dashes = 2
			dashes_left = max_dashes
		"extra_heart":
			max_hp = 4
			hp = max_hp
		"light_paws":
			move_speed = 142.0
			jump_speed = 250.0
	play_sfx("upgrade")
	stats_changed.emit()
	reward_chosen.emit(upgrade_id)

func damage_player(amount: int = 1, is_hazard_pit_or_spike: bool = false) -> void:
	hp = maxi(0, hp - amount)
	play_sfx("hurt")
	camera_shake_requested.emit(4.5)
	stats_changed.emit()

	if hp <= 0:
		reset_run()
		run_reset_requested.emit()
	elif is_hazard_pit_or_spike:
		dashes_left = max_dashes
		stats_changed.emit()
		room_restart_requested.emit()

func _setup_audio() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.volume_db = -6.0
	add_child(_sfx_player)
	_sfx_bank["jump"] = _make_tone(320.0, 560.0, 0.09)
	_sfx_bank["dash"] = _make_tone(540.0, 210.0, 0.11)
	_sfx_bank["stomp"] = _make_tone(240.0, 680.0, 0.12)
	_sfx_bank["hurt"] = _make_tone(190.0, 95.0, 0.18)
	_sfx_bank["upgrade"] = _make_tone(400.0, 880.0, 0.22)

func play_sfx(key: String) -> void:
	if _sfx_bank.has(key) and _sfx_player != null:
		_sfx_player.stream = _sfx_bank[key]
		_sfx_player.play()

func _make_tone(f0: float, f1: float, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	for i in range(count):
		var u := float(i) / float(count)
		var f: float = lerpf(f0, f1, u)
		phase += (TAU * f) / float(rate)
		var env := 1.0 - u
		var sample := (1.0 if sin(phase) >= 0.0 else -1.0) * 0.22 * env
		bytes.encode_s16(i * 2, int(sample * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav
