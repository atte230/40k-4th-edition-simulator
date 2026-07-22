extends Control
## MainMenu: Main game menu for navigation

class_name MainMenu

var game_manager: GameManager
var selected_faction: String = ""

# UI References
var menu_title: Label
var buttons_container: VBoxContainer
var faction_selector: Control

func _ready() -> void:
	setup_menu()

func setup_menu() -> void:
	"""Initialize main menu UI"""
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Create background
	var background = ColorRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.05, 0.05, 0.1, 1.0)
	add_child(background)
	
	# Create main container
	var main_container = CenterContainer.new()
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	add_child(main_container)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 300)
	main_container.add_child(vbox)
	
	# Title
	menu_title = Label.new()
	menu_title.text = "WARHAMMER 40K 4th EDITION"
	menu_title.add_theme_font_size_override("font_size", 36)
	menu_title.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(menu_title)
	
	var subtitle = Label.new()
	subtitle.text = "Tabletop Simulator"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	vbox.add_child(subtitle)
	
	# Spacer
	vbox.add_child(Control.new())
	
	# Buttons
	buttons_container = VBoxContainer.new()
	buttons_container.custom_minimum_size = Vector2(300, 0)
	vbox.add_child(buttons_container)
	
	_create_button("New Campaign", _on_new_campaign_pressed)
	_create_button("View Rosters", _on_view_rosters_pressed)
	_create_button("Rules Reference", _on_rules_reference_pressed)
	_create_button("Quit", _on_quit_pressed)
	
	print("Main menu initialized")

func _create_button(text: String, callback: Callable) -> void:
	"""Create a menu button"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 50)
	button.pressed.connect(callback)
	buttons_container.add_child(button)

func _on_new_campaign_pressed() -> void:
	"""Handle new campaign selection"""
	print("New Campaign selected")
	_show_faction_selector()

func _on_view_rosters_pressed() -> void:
	"""Handle view rosters"""
	print("View Rosters selected")
	_show_roster_viewer()

func _on_rules_reference_pressed() -> void:
	"""Handle rules reference"""
	print("Rules Reference selected")
	_show_rules_viewer()

func _on_quit_pressed() -> void:
	"""Quit the game"""
	get_tree().quit()

func _show_faction_selector() -> void:
	"""Show faction selection dialog"""
	var dialog = FactionSelector.new()
	dialog.faction_selected.connect(_on_faction_selected)
	add_child(dialog)

func _show_roster_viewer() -> void:
	"""Show roster viewer"""
	var viewer = RosterViewer.new()
	add_child(viewer)

func _show_rules_viewer() -> void:
	"""Show rules reference"""
	# TODO: Implement rules viewer
	print("Rules viewer not yet implemented")

func _on_faction_selected(faction: String) -> void:
	"""Handle faction selection"""
	selected_faction = faction
	print("Faction selected: %s" % faction)
	# Load the scenario with selected faction
	_start_campaign(faction)

func _start_campaign(faction: String) -> void:
	"""Start a campaign with the selected faction"""
	# Switch to game scene
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
