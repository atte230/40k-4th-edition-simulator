extends Control
## RosterViewer: Display unit rosters for factions

class_name RosterViewer

var current_faction: String = ""
var factions: Dictionary = {}

func _ready() -> void:
	setup_factions()
	setup_viewer()

func setup_factions() -> void:
	"""Setup faction rosters"""
	factions = {
		"space_marines": {
			"name": "Space Marines",
			"description": "Elite warriors of the Imperium",
			"units": [
				{
					"name": "Tactical Marine",
					"ws": 3,
					"bs": 3,
					"s": 4,
					"t": 4,
					"w": 1,
					"i": 3,
					"a": 1,
					"ld": 8,
					"armor": 3,
					"cost": 15
				},
				{
					"name": "Sergeant",
					"ws": 4,
					"bs": 4,
					"s": 4,
					"t": 4,
					"w": 1,
					"i": 4,
					"a": 2,
					"ld": 9,
					"armor": 3,
					"cost": 20
				},
				{
					"name": "Terminator",
					"ws": 4,
					"bs": 4,
					"s": 4,
					"t": 4,
					"w": 2,
					"i": 2,
					"a": 2,
					"ld": 9,
					"armor": 2,
					"cost": 40
				}
			]
		},
		"orks": {
			"name": "Orks",
			"description": "Brutal warriors of destruction",
			"units": [
				{
					"name": "Ork Boy",
					"ws": 3,
					"bs": 2,
					"s": 5,
					"t": 4,
					"w": 1,
					"i": 2,
					"a": 1,
					"ld": 7,
					"armor": 1,
					"cost": 10
				},
				{
					"name": "Nob",
					"ws": 4,
					"bs": 3,
					"s": 5,
					"t": 5,
					"w": 2,
					"i": 2,
					"a": 3,
					"ld": 8,
					"armor": 1,
					"cost": 25
				},
				{
					"name": "Warboss",
					"ws": 5,
					"bs": 3,
					"s": 6,
					"t": 5,
					"w": 3,
					"i": 2,
					"a": 4,
					"ld": 9,
					"armor": 1,
					"cost": 50
				}
			]
		}
	}

func setup_viewer() -> void:
	"""Create roster viewer UI"""
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Background
	var background = ColorRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.05, 0.05, 0.1, 1.0)
	add_child(background)
	
	# Main container
	var main_container = VBoxContainer.new()
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.add_theme_constant_override("separation", 10)
	add_child(main_container)
	
	# Header
	var header = HBoxContainer.new()
	main_container.add_child(header)
	
	var title = Label.new()
	title.text = "UNIT ROSTERS"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(100, 0)
	header.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)
	
	# Faction tabs
	var tabs_container = HBoxContainer.new()
	tabs_container.custom_minimum_size = Vector2(0, 50)
	main_container.add_child(tabs_container)
	
	for faction_id in factions.keys():
		var btn = Button.new()
		btn.text = factions[faction_id]["name"]
		btn.custom_minimum_size = Vector2(200, 40)
		btn.pressed.connect(func(): _show_faction_roster(faction_id))
		tabs_container.add_child(btn)
	
	# Roster display
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 500)
	main_container.add_child(scroll)
	
	var roster_text = TextEdit.new()
	roster_text.read_only = true
	roster_text.wrap_mode = TextEdit.LINE_WRAPPING_WORD
	scroll.add_child(roster_text)
	
	# Show first faction by default
	_show_faction_roster("space_marines")

func _show_faction_roster(faction_id: String) -> void:
	"""Display roster for a faction"""
	current_faction = faction_id
	var faction = factions[faction_id]
	
	# Find scroll container and text edit
	var scroll = find_child("*", true, false)
	if scroll is ScrollContainer:
		var roster_text = scroll.get_child(0)
		if roster_text is TextEdit:
			roster_text.clear()
			roster_text.text = "=== %s ===\n" % faction["name"].to_upper()
			roster_text.text += "%s\n\n" % faction["description"]
			roster_text.text += "AVAILABLE UNITS:\n"
			roster_text.text += "=" * 80 + "\n\n"
			
			for unit in faction["units"]:
				roster_text.text += "[%s] - %d pts\n" % [unit["name"], unit["cost"]]
				roster_text.text += "  WS:%d BS:%d S:%d T:%d W:%d I:%d A:%d Ld:%d Armor:%d+\n\n" % [
					unit["ws"], unit["bs"], unit["s"], unit["t"], unit["w"],
					unit["i"], unit["a"], unit["ld"], unit["armor"]
				]

func _on_close_pressed() -> void:
	"""Close roster viewer"""
	queue_free()
