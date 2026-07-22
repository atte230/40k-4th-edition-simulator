extends Node

# CampaignManager.gd
# Responsibilities:
# - Hold current campaign state in memory
# - Create, load, save campaigns
# - Apply scenario results to campaign roster (XP, wounds, injuries)
# - Expose simple API used by UI and GameLoop

const SAVELOAD_PATH := "res://managers/SaveLoad.gd" # optional reference

var current_campaign: Dictionary = {}

func new_campaign(definition: Dictionary) -> void:
	# Expected minimal definition keys: id, player_faction, roster (array)
	current_campaign = {
		"version": 1,
		"id": definition.get("id", "campaign_%s" % str(OS.get_unix_time())),
		"player_faction": definition.get("player_faction", "Unknown"),
		"roster": definition.get("roster", []),
		"current_scenario": definition.get("current_scenario", "first_blood"),
		"completed_scenarios": [],
		"flags": {},
		"created_at": OS.get_unix_time()
	}

func load_campaign(campaign_id:String) -> bool:
	var sl = preload("res://managers/SaveLoad.gd").new()
	var data = sl.load_campaign(campaign_id)
	if data == null:
		return false
	current_campaign = data
	return true

func save_campaign() -> bool:
	if current_campaign.empty():
		push_error("No campaign loaded to save")
		return false
	var sl = preload("res://managers/SaveLoad.gd").new()
	return sl.save_campaign(current_campaign)

func apply_scenario_result(result: Dictionary) -> void:
	# result should contain: scenario_id, rewards, roster_updates, casualties
	var sid = result.get("scenario_id", "")
	if sid != "":
		current_campaign.completed_scenarios.append(sid)
	# Apply simple XP updates to roster
	var updates = result.get("roster_updates", [])
	for upd in updates:
		var uid = upd.get("unit_id", null)
		if uid == null:
			continue
		for i in range(current_campaign.roster.size()):
			if current_campaign.roster[i].get("unit_id", "") == uid:
				# merge xp/wounds/injuries
				current_campaign.roster[i].xp = current_campaign.roster[i].get("xp", 0) + upd.get("xp", 0)
				current_campaign.roster[i].wounds = current_campaign.roster[i].get("wounds", 0) + upd.get("wounds", 0)
				var inj = upd.get("injuries", [])
				if inj.size() > 0:
					current_campaign.roster[i].injuries = current_campaign.roster[i].get("injuries", []) + inj
	# Save after applying results
	save_campaign()

func get_roster() -> Array:
	return current_campaign.get("roster", [])
