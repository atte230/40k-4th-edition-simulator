extends Control

# CampaignScreen.gd
# Minimal UI script to create/load/save campaigns via CampaignManager/SaveLoad

@export_node_path(NodePath) var campaign_manager_path: NodePath = NodePath("/root/CampaignManager")

var campaign_manager: Node = null

func _ready() -> void:
	if has_node(campaign_manager_path):
		campaign_manager = get_node(campaign_manager_path)
	else:
		print("CampaignManager not found at %s — you can set campaign_manager_path in the inspector." % campaign_manager_path)

func create_new_campaign(id:String, faction:String, roster:Array) -> void:
	if campaign_manager == null:
		push_error("No CampaignManager configured")
		return
	var def = {
		"id": id,
		"player_faction": faction,
		"roster": roster,
		"current_scenario": "first_blood"
	}
	campaign_manager.new_campaign(def)
	campaign_manager.save_campaign()
	print("Created and saved campaign: %s" % id)

func load_campaign(id:String) -> void:
	if campaign_manager == null:
		push_error("No CampaignManager configured")
		return
	var ok = campaign_manager.load_campaign(id)
	if ok:
		print("Loaded campaign: %s" % id)
	else:
		push_error("Failed to load campaign: %s" % id)

func save_current_campaign() -> void:
	if campaign_manager == null:
		push_error("No CampaignManager configured")
		return
	var ok = campaign_manager.save_campaign()
	if ok:
		print("Campaign saved")
	else:
		push_error("Failed to save campaign")
