extends Control
## MainMenu: Main game menu for navigation

class_name MainMenu

var selected_faction: String = ""
var faction_selector_scene = preload("res://scenes/menu/faction_selector.tscn")
var roster_viewer_scene = preload("res://scripts/ui/roster_viewer.gd")

@onready var vbox_container = $VBoxContainer
@onready var new_campaign_btn = $VBoxContainer/NewCampaignBtn
@onready var view_rosters_btn = $VBoxContainer/ViewRostersBtn
@onready var rules_reference_btn = $VBoxContainer/RulesReferenceBtn
@onready var quit_btn = $VBoxContainer/QuitBtn

func _ready() -> void:
	# Connect button signals
	new_campaign_btn.pressed.connect(_on_new_campaign_pressed)
	view_rosters_btn.pressed.connect(_on_view_rosters_pressed)
	rules_reference_btn.pressed.connect(_on_rules_reference_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	print("Main menu initialized - Phase 4 menu system ready")

func _on_new_campaign_pressed() -> void:
	"""Handle new campaign selection"""
	print("New Campaign selected - showing faction selector")
	_show_faction_selector()

func _on_view_rosters_pressed() -> void:
	"""Handle view rosters"""
	print("View Rosters selected")
	_show_roster_viewer()

func _on_rules_reference_pressed() -> void:
	"""Handle rules reference"""
	print("Rules Reference selected")
	# TODO: Implement rules viewer in Phase 6
	print("Rules viewer - coming in Phase 6 (Polish & Performance)")

func _on_quit_pressed() -> void:
	"""Quit the game"""
	print("Quitting game...")
	get_tree().quit()

func _show_faction_selector() -> void:
	"""Show faction selection dialog"""
	var selector = faction_selector_scene.instantiate()
	selector.faction_selected.connect(_on_faction_selected)
	add_child(selector)
	print("Faction selector opened")

func _show_roster_viewer() -> void:
	"""Show roster viewer"""
	var viewer = RosterViewer.new()
	add_child(viewer)
	print("Roster viewer opened")

func _on_faction_selected(faction: String) -> void:
	"""Handle faction selection and start campaign"""
	selected_faction = faction
	print("Faction selected: %s - loading campaign" % faction)
	_start_campaign(faction)

func _start_campaign(faction: String) -> void:
	"""Start a campaign with the selected faction"""
	# Store faction in global state for the game scene to access
	# TODO: Implement global game state manager in Phase 5
	print("Starting campaign with faction: %s" % faction)
	
	# For now, pass faction as metadata to the next scene
	# Change to game scene (placeholder path - will implement in Phase 5)
	# get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	print("Campaign start - loading main game scene")
	print("TODO: Integrate with ScenarioManager to load scenario with faction: %s" % faction)
