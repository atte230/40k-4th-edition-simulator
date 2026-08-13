extends Node
## CampaignData: Global campaign state manager
## Stores selected faction, scenario progress, and campaign settings

class_name CampaignData

# Singleton pattern
static var instance: CampaignData

# Campaign state
var selected_faction: String = ""
var current_scenario: String = "first_blood"
var completed_scenarios: Array[String] = []
var player_roster: Array = []
var enemy_roster: Array = []

func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()

static func get_instance() -> CampaignData:
	if instance == null:
		var campaign_data = CampaignData.new()
		Engine.get_main_loop().root.add_child(campaign_data)
	return instance

func set_faction(faction: String) -> void:
	"""Set the player's faction"""
	selected_faction = faction
	print("CampaignData: Faction set to %s" % faction)

func get_faction() -> String:
	"""Get the player's faction"""
	return selected_faction

func set_scenario(scenario_id: String) -> void:
	"""Set the current scenario"""
	current_scenario = scenario_id
	print("CampaignData: Scenario set to %s" % scenario_id)

func get_scenario() -> String:
	"""Get the current scenario"""
	return current_scenario

func mark_scenario_complete(scenario_id: String) -> void:
	"""Mark a scenario as completed"""
	if scenario_id not in completed_scenarios:
		completed_scenarios.append(scenario_id)
		print("CampaignData: Marked %s as complete" % scenario_id)

func get_completed_scenarios() -> Array[String]:
	"""Get all completed scenarios"""
	return completed_scenarios

func set_player_roster(roster: Array) -> void:
	"""Set the player's unit roster"""
	player_roster = roster
	print("CampaignData: Player roster set with %d units" % roster.size())

func get_player_roster() -> Array:
	"""Get the player's unit roster"""
	return player_roster

func set_enemy_roster(roster: Array) -> void:
	"""Set the enemy's unit roster"""
	enemy_roster = roster
	print("CampaignData: Enemy roster set with %d units" % roster.size())

func get_enemy_roster() -> Array:
	"""Get the enemy's unit roster"""
	return enemy_roster

func reset() -> void:
	"""Reset campaign to defaults"""
	selected_faction = ""
	current_scenario = "first_blood"
	completed_scenarios.clear()
	player_roster.clear()
	enemy_roster.clear()
	print("CampaignData: Campaign reset")
