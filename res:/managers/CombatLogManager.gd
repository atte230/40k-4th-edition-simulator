extends CanvasLayer

# CombatLogManager.gd
# Full-featured combat log with icons, replay integration, sound mapping, animation, filtering, export, and prefs persistence.

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
var ui_lines := [] # parallel list of HBoxContainers created for events

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

# prefs
var prefs_path := "user://prefs.cfg"
var prefs := {}

func _ready() -> void:
	self.name = "CombatLogManager"
	self.layer = 10
	self.pause_mode = Node.PAUSE_MODE_PROCESS
	_compact = compact_default
	_build_ui()
	_load_prefs()
	# ensure replay manager exists
	var rm = get_tree().get_root().get_node_or_null("ReplayManager")
	if rm == null and ResourceLoader.exists("res://managers/ReplayManager.gd"):
		rm = load("res://managers/ReplayManager.gd").new()
		rm.name = "ReplayManager"
		get_tree().get_root().add_child(rm)
	_replay_manager = rm
	# connect to replay signals for animation
	if _replay_manager != null and _replay_manager.has_signal("command_applied"):
		_replay_manager.connect("command_applied", Callable(self, "_on_command_applied"))

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

	# volume slider
	var vol_label = Label.new(); vol_label.text = "Vol"; btns.add_child(vol_label)
	var vol_slider = HSlider.new(); vol_slider.min_value = 0.0; vol_slider.max_value = 1.0; vol_slider.step = 0.01; vol_slider.value = 0.6; vol_slider.size_flags_horizontal = Control.SIZE_FILL
	vol_slider.connect("value_changed", Callable(self, "_on_volume_changed"))
	btns.add_child(vol_slider)

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
	var next_rule = Button.new(); next_rule.text = "Next Rule"; next_rule.connect("pressed", Callable(self, "_on_next_rule_pressed")); replay_box.add_child(next_rule)
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
	_audio_player.volume_db = _volume_to_db(0.6)
	add_child(_audio_player)

func _volume_to_db(vol:float) -> float:
	# map 0..1 -> -40..0 dB
	return lerp(-40.0, 0.0, clamp(vol, 0.0, 1.0))

func _on_volume_changed(val:float) -> void:
	_audio_player.volume_db = _volume_to_db(val)
	prefs["volume"] = val
	_save_prefs()

func _on_sample_sfx_toggled(pressed:bool) -> void:
	_use_sample_sfx = pressed
	prefs["use_sample_sfx"] = pressed
	_save_prefs()
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

func log_event(event) -> void:
	var ev = _normalize_event(event)
	events.append(ev)
	# create UI line and store
	_create_log_line(ev)
	# Auto-open panel
	var panel = get_node("CombatLogPanel")
	if panel:
		panel.visible = true
	# record command if present
	if ev.has("command") and _replay_manager != null and _replay_manager.has_method("record_command"):
		_replay_manager.call("record_command", ev.get("command"))
	# send rolls to dice tray
	if ev.has("rolls") and _dice_tray != null and _dice_tray.has_method("show_rolls"):
		_dice_tray.call("show_rolls", ev.get("rolls"))
	# play sound
	_play_event_sound(ev)
	# pause game if needed
	if ev.get("pause", false):
		_pause_game_for_duration(pause_on_rule_duration)

func _create_log_line(ev:Dictionary) -> void:
	var content = _vbox.get_node("LogContent")
	# respect filters: only add if passes currently
	if not _passes_filters(ev):
		# still create line but hide it so filters can be toggled on/off
		var hidden = true
	else:
		var hidden = false
	var line = HBoxContainer.new()
	line.name = "EventLine_%d" % ui_lines.size()
	# icon
	var icon_name = ev.get("icon", ev.get("type", "combat"))
	var tex = IconFactory.get_icon(icon_name)
	var tr = TextureRect.new()
	tr.texture = tex
	tr.rect_min_size = Vector2(20,20)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tr.name = "Icon"
	line.add_child(tr)
	# label
	var lbl = Label.new()
	lbl.text = ev.get("message", "")
	if font != null:
		lbl.add_theme_font_override("font", font)
	line.add_child(lbl)
	# details
	var details = Button.new(); details.text = "Details"; details.connect("pressed", Callable(self, "_on_details_pressed"), [ev]); line.add_child(details)
	# metadata for matching with replay events
	line.set_meta("event_json", JSON.print(ev))
	line.visible = not hidden
	content.add_child(line)
	ui_lines.append(line)

func _normalize_event(event) -> Dictionary:
	var ev = {}
	if typeof(event) == TYPE_STRING:
		ev["message"] = event
		ev["type"] = "message"
		return ev
	if typeof(event) == TYPE_DICTIONARY:
		ev = event.duplicate(true)
		ev["message"] = ev.get("message", str(ev))
		ev["type"] = ev.get("type", ev.get("event_type", "combat"))
		if ev.has("attacker") and ev["attacker"] is Node:
			ev["actor_name"] = ev["attacker"].name
		elif ev.has("attacker_name"):
			ev["actor_name"] = ev["attacker_name"]
		if ev.has("target") and ev["target"] is Node:
			ev["target_name"] = ev["target"].name
		elif ev.has("target_name"):
			ev["target_name"] = ev["target_name"]
		return ev
	ev["message"] = str(event)
	ev["type"] = "message"
	return ev

func _passes_filters(ev:Dictionary) -> bool:
	if filter_text != "":
		if ev.get("message", "").to_lower().find(filter_text.to_lower()) == -1:
			return false
	if filter_actor != "":
		if ev.get("actor_name", "") != filter_actor:
			return false
	if filter_target != "":
		if ev.get("target_name", "") != filter_target:
			return false
	if filter_type != "":
		if ev.get("type", "") != filter_type:
			return false
	return true

func _on_search_changed(text:String) -> void:
	filter_text = text
	_refresh_log_visibility()

func _on_actor_changed(text:String) -> void:
	filter_actor = text
	_refresh_log_visibility()

func _on_target_changed(text:String) -> void:
	filter_target = text
	_refresh_log_visibility()

func _on_type_changed(text:String) -> void:
	filter_type = text
	_refresh_log_visibility()

func _refresh_log_visibility() -> void:
	var content = _vbox.get_node("LogContent")
	for i in range(events.size()):
		var ev = events[i]
		var line = ui_lines[i]
		if _passes_filters(ev):
			line.visible = true
		else:
			line.visible = false

func _on_details_pressed(ev:Dictionary) -> void:
	var popup = WindowDialog.new()
	popup.title = "Event Details"
	popup.rect_min_size = Vector2(400, 300)
	var tb = TextEdit.new()
	tb.readonly = true
	if typeof(ev) == TYPE_STRING:
		tb.text = ev
	else:
		tb.text = JSON.print(ev, "\t")
	popup.add_child(tb)
	var btn = Button.new(); btn.text = "Center Camera"; btn.connect("pressed", Callable(self, "_on_center_camera_pressed"), [ev]); popup.add_child(btn)
	add_child(popup)
	popup.popup_centered()

func _on_center_camera_pressed(ev:Dictionary) -> void:
	var uid = ""
	if typeof(ev) == TYPE_DICTIONARY:
		uid = ev.get("attacker_id", ev.get("target_id", ev.get("actor_id", ev.get("target_name", ""))))
	if uid == "":
		uid = ev.get("actor_name", ev.get("target_name", ""))
	if uid != "":
		var unit = _find_unit_by_name_or_id(uid)
		if unit != null:
			var cam = get_tree().get_root().get_node_or_null("MainCamera")
			if cam != null and cam.has_method("global_transform"):
				cam.global_transform.origin = unit.global_transform.origin + Vector3(0,5,10)

func _find_unit_by_name_or_id(uid:String) -> Node:
	for node in get_tree().get_root().get_children():
		if node is Node and node.has_method("to_persistent_dict"):
			var d = node.call("to_persistent_dict")
			if d.get("unit_id", "") == uid or node.name == uid:
				return node
	return null

func _on_play_pressed() -> void:
	if _replay_manager and _replay_manager.has_method("play"):
		_replay_manager.call("play")

func _on_pause_pressed() -> void:
	if _replay_manager and _replay_manager.has_method("pause"):
		_replay_manager.call("pause")

func _on_step_forward() -> void:
	if _replay_manager and _replay_manager.has_method("step_forward"):
		_replay_manager.call("step_forward")

func _on_step_back() -> void:
	if _replay_manager and _replay_manager.has_method("step_backward"):
		_replay_manager.call("step_backward")

func _on_next_rule_pressed() -> void:
	if _replay_manager and _replay_manager.has_method("jump_to_next_rule"):
		_replay_manager.call("jump_to_next_rule")

func _on_speed_changed(val:float) -> void:
	if _replay_manager and _replay_manager.has_method("set_play_speed"):
		_replay_manager.call("set_play_speed", val)

func _pause_game_for_duration(duration:float) -> void:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = duration
	timer.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(timer)
	get_tree().paused = true
	timer.connect("timeout", Callable(self, "_on_pause_timeout"), [timer])
	timer.start()

func _on_pause_timeout(timer:Timer) -> void:
	get_tree().paused = false
	if is_instance_valid(timer):
		timer.queue_free()

func _generate_blip_stream() -> AudioStream:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 44100
	return gen

func _play_event_sound(ev:Dictionary) -> void:
	if not enable_sound or _audio_player == null:
		return
	# choose pitch scale based on event type
	var pitch = 1.0
	if ev.has("rule"):
		pitch = 1.6
	elif ev.get("type","") == "combat":
		# damage vs wound vs save
		if ev.has("damage_dealt") and int(ev.get("damage_dealt",0)) > 0:
			pitch = 0.9
		elif ev.has("wounded") and ev.get("wounded"):
			pitch = 1.2
		else:
			pitch = 1.0
	else:
		pitch = 1.0
	_audio_player.pitch_scale = pitch
	# stream selection handled by toggle (sampled vs procedural)
	_audio_player.play()

func _on_command_applied(ev:Dictionary, cmd_index:int) -> void:
	# Find matching UI line by comparing JSON payloads
	var ev_json = JSON.print(ev)
	for i in range(events.size()):
		var stored = events[i]
		var stored_json = JSON.print(stored)
		if stored_json == ev_json:
			# animate UI line at index i
			_animate_line(ui_lines[i])
			# play mapped sound for this event as well
			_play_event_sound(ev)
			return
	# fallback: try matching by attacker_id + target_id
	var atk = ev.get("attacker_id", "")
	var tgt = ev.get("target_id", "")
	for i in range(events.size()):
		var s = events[i]
		if s.get("attacker_id", "") == atk and s.get("target_id", "") == tgt:
			_animate_line(ui_lines[i])
			_play_event_sound(ev)
			return

func _animate_line(line:HBoxContainer) -> void:
	if line == null:
		return
	# animate the icon child if present
	var icon = line.get_node_or_null("Icon")
	if icon != null:
		# subtle pulse
		var tween = create_tween()
		icon.scale = Vector2(1,1)
		tween.tween_property(icon, "scale", Vector2(1.4,1.4), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(icon, "scale", Vector2(1,1), 0.18).set_delay(0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		# quick modulate flash
		var orig = icon.modulate
		tween.tween_property(icon, "modulate", Color(1,1,0.8,1), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(icon, "modulate", orig, 0.18).set_delay(0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func clear() -> void:
	events.clear()
	var content = _vbox.get_node("LogContent")
	content.clear()
	ui_lines.clear()

func toggle_compact() -> void:
	_compact = not _compact
	prefs["compact"] = _compact
	_save_prefs()
	# no major layout change currently — refresh to apply
	_refresh_log_visibility()

func export_text() -> void:
	var text = ""
	for ev in events:
		text += ev.get("message", "") + "\n"
	OS.clipboard = text
	_print_temp_message("Combat log copied to clipboard (text)")

func export_json() -> void:
	var j = JSON.print(events)
	OS.clipboard = j
	_print_temp_message("Combat log copied to clipboard (JSON)")

func _print_temp_message(msg:String) -> void:
	var nm = get_tree().get_root().get_node_or_null("NotificationManager")
	if nm and nm.has_method("show_message"):
		nm.call("show_message", msg)

# prefs load/save
func _load_prefs() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(prefs_path)
	if err == OK:
		prefs["compact"] = cfg.get_value("ui", "compact", compact_default)
		prefs["use_sample_sfx"] = cfg.get_value("audio", "use_sample_sfx", false)
		prefs["volume"] = cfg.get_value("audio", "volume", 0.6)
		# apply
		_compact = prefs["compact"]
		_use_sample_sfx = prefs["use_sample_sfx"]
		_audio_player.volume_db = _volume_to_db(float(prefs["volume"]))
	else:
		# defaults
		prefs["compact"] = compact_default
		prefs["use_sample_sfx"] = false
		prefs["volume"] = 0.6

func _save_prefs() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("ui", "compact", prefs.get("compact", _compact))
	cfg.set_value("audio", "use_sample_sfx", prefs.get("use_sample_sfx", _use_sample_sfx))
	cfg.set_value("audio", "volume", prefs.get("volume", 0.6))
	cfg.save(prefs_path)
