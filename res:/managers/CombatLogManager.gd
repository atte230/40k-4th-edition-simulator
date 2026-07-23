extends CanvasLayer

# CombatLogManager.gd (updated with remote SFX loader toggle)
# Provides a scrollable combat log UI where systems can append structured combat messages.
# Supports compact mode, event-based pausing, dice tray integration, sound, export (text + JSON), filtering and search.

class_name CombatLogManager

@export var font: Font
@export var max_lines := 1000
@export var default_color: Color = Color(0.95, 0.95, 0.95)
@export var compact_default: bool = true
@export var pause_on_rule_duration: float = 3.0
@export var enable_sound: bool = true

var _vbox: VBoxContainer
var _compact: bool
var _dice_tray: Node = null
var _audio_player: AudioStreamPlayer = null
var _replay_manager: Node = null

var events := []

var filter_text := ""
var filter_actor := ""
var filter_target := ""
var filter_type := ""

var IconFactory = preload("res://ui/PixelIconFactory.gd")
var ICON_MAP = preload("res://ui/icon_map.gd").ICON_MAP

# remote sfx
var _use_sample_sfx := false
var _sfx_loader_path := "res://managers/SFXLoader.gd"
var _sample_url := "https://cdn.pixabay.com/audio/2022/03/15/audio_115208.mp3"

func _ready() -> void:
	self.name = "CombatLogManager"
	self.layer = 10
	self.pause_mode = Node.PAUSE_MODE_PROCESS
	_compact = compact_default
	_build_ui()
	# ensure replay manager exists
	var rm = get_tree().get_root().get_node_or_null("ReplayManager")
	if rm == null and ResourceLoader.exists("res://managers/ReplayManager.gd"):
		rm = load("res://managers/ReplayManager.gd").new()
		rm.name = "ReplayManager"
		get_tree().get_root().add_child(rm)
	_replay_manager = rm

func _build_ui() -> void:
	# Right-side panel
	var panel = Panel.new()
	panel.name = "CombatLogPanel"
	panel.anchor_left = 0.7
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.margin_left = 6
	vbox.margin_top = 6
	vbox.margin_right = -6
	vbox.margin_bottom = -6
	panel.add_child(vbox)
	_vbox = vbox

	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "Combat Log"
	if font != null:
		title.add_theme_font_override("font", font)
	header.add_child(title)

	var btns = HBoxContainer.new()
	var clear_btn = Button.new()
	clear_btn.text = "Clear"
	clear_btn.connect("pressed", Callable(self, "clear"))
	btns.add_child(clear_btn)

	var export_txt = Button.new()
	export_txt.text = "Export TXT"
	export_txt.connect("pressed", Callable(self, "export_text"))
	btns.add_child(export_txt)

	var export_json = Button.new()
	export_json.text = "Export JSON"
	export_json.connect("pressed", Callable(self, "export_json"))
	btns.add_child(export_json)

	var toggle_view = Button.new()
	toggle_view.text = "Toggle View"
	toggle_view.connect("pressed", Callable(self, "toggle_compact"))
	btns.add_child(toggle_view)

	# Sample SFX toggle
	var sample_toggle = CheckBox.new()
	sample_toggle.text = "Use Sample SFX"
	sample_toggle.pressed = _use_sample_sfx
	sample_toggle.connect("toggled", Callable(self, "_on_sample_sfx_toggled"))
	btns.add_child(sample_toggle)

	header.add_child(btns)
	vbox.add_child(header)

	# Filters row
	var filter_row = HBoxContainer.new()
	var search_label = Label.new(); search_label.text = "Search:"; filter_row.add_child(search_label)
	var search_input = LineEdit.new(); search_input.name = "SearchInput"; search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_input.connect("text_changed", Callable(self, "_on_search_changed"))
	filter_row.add_child(search_input)

	var actor_label = Label.new(); actor_label.text = "Actor:"; filter_row.add_child(actor_label)
	var actor_input = LineEdit.new(); actor_input.name = "ActorInput"; actor_input.connect("text_changed", Callable(self, "_on_actor_changed"))
	actor_input.size_flags_horizontal = Control.SIZE_FILL
	filter_row.add_child(actor_input)

	var target_label = Label.new(); target_label.text = "Target:"; filter_row.add_child(target_label)
	var target_input = LineEdit.new(); target_input.name = "TargetInput"; target_input.connect("text_changed", Callable(self, "_on_target_changed"))
	filter_row.add_child(target_input)

	var type_label = Label.new(); type_label.text = "Type:"; filter_row.add_child(type_label)
	var type_input = LineEdit.new(); type_input.name = "TypeInput"; type_input.connect("text_changed", Callable(self, "_on_type_changed"))
	filter_row.add_child(type_input)

	vbox.add_child(filter_row)

	# Replay controls
	var replay_box = HBoxContainer.new()
	var play_btn = Button.new(); play_btn.text = "Play"; play_btn.connect("pressed", Callable(self, "_on_play_pressed")); replay_box.add_child(play_btn)
	var pause_btn = Button.new(); pause_btn.text = "Pause"; pause_btn.connect("pressed", Callable(self, "_on_pause_pressed")); replay_box.add_child(pause_btn)
	var step_fwd = Button.new(); step_fwd.text = ">"; step_fwd.connect("pressed", Callable(self, "_on_step_forward")); replay_box.add_child(step_fwd)
	var step_back = Button.new(); step_back.text = "<"; step_back.connect("pressed", Callable(self, "_on_step_back")); replay_box.add_child(step_back)
	var speed_label = Label.new(); speed_label.text = "Speed"; replay_box.add_child(speed_label)
	var speed_slider = HSlider.new(); speed_slider.min_value = 0.25; speed_slider.max_value = 2.0; speed_slider.step = 0.25; speed_slider.value = 1.0; speed_slider.connect("value_changed", Callable(self, "_on_speed_changed")); replay_box.add_child(speed_slider)
	vbox.add_child(replay_box)

	var scroll = ScrollContainer.new()
	scroll.v_size_flags = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.name = "LogContent"
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	scroll.add_child(content)

	# Dice tray
	var dt_scene = load("res://ui/DiceTray.tscn")
	if dt_scene:
		_dice_tray = dt_scene.instantiate()
		_dice_tray.name = "DiceTray"
		add_child(_dice_tray)

	# Audio player
	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "CombatLogAudio"
	_audio_player.pause_mode = Node.PAUSE_MODE_PROCESS
	_audio_player.stream = _generate_blip_stream()
	add_child(_audio_player)

func _on_sample_sfx_toggled(pressed:bool) -> void:
	_use_sample_sfx = pressed
	if pressed:
		# start download + load
		load_remote_sfx(_sample_url)
	else:
		# revert to procedural blip
		_audio_player.stream = _generate_blip_stream()

func load_remote_sfx(url:String) -> void:
	if not ResourceLoader.exists(_sfx_loader_path):
		print("SFXLoader script missing: %s" % _sfx_loader_path)
		return
	var loader = load(_sfx_loader_path).new()
	add_child(loader)
	loader.connect("sfx_ready", Callable(self, "_on_sfx_ready"))
	loader.download(url)

func _on_sfx_ready(audio_stream) -> void:
	if audio_stream != null and audio_stream is AudioStream:
		_audio_player.stream = audio_stream
		_print_temp_message("Sample SFX loaded")
	else:
		_print_temp_message("Failed to load sample SFX; staying with procedural blip")

# rest of CombatLogManager methods remain unchanged (omitted for brevity)
# The file includes the previously implemented functions: log_event, _normalize_event, _refresh_log, etc.

func _generate_blip_stream() -> AudioStream:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 44100
	return gen
