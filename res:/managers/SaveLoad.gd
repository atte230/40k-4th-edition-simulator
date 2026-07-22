extends Node

# SaveLoad.gd
# Minimal, robust JSON-based save/load for campaigns.
# Saves to: user://campaigns/<campaign_id>.json
# Includes a top-level "version" field and a simple backup-on-save.

const SAVE_DIR := "user://campaigns"
const ENGINE_VERSION := Engine.get_version_info().get("major", 0)
const CURRENT_SAVE_VERSION := 1

func _ensure_save_dir() -> void:
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		DirAccess.make_dir_recursive(SAVE_DIR)

func _campaign_path(campaign_id:String) -> String:
	return "%s/%s.json" % [SAVE_DIR, campaign_id]

func save_campaign(campaign:Dictionary) -> bool:
	if campaign.empty():
		push_error("Empty campaign cannot be saved")
		return false
	_ensure_save_dir()
	var campaign_id = campaign.get("id", null)
	if campaign_id == null:
		push_error("Campaign has no id")
		return false
	# Add metadata
	var to_save = campaign.duplicate(true)
	to_save["save_version"] = CURRENT_SAVE_VERSION
	to_save["saved_at"] = OS.get_unix_time()
	to_save["engine_major"] = ENGINE_VERSION
	var path = _campaign_path(campaign_id)
	# Backup old file if exists
	if FileAccess.file_exists(path):
		var backup_path = "%s.bak.%s" % [path, str(OS.get_unix_time())]
		DirAccess.copy(path, backup_path)
	# Write
	var f = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if f == null:
		push_error("Failed to open save file for writing: %s" % path)
		return false
	var json_text = JSON.print(to_save)
	f.store_string(json_text)
	f.close()
	return true

func load_campaign(campaign_id:String) -> Dictionary:
	var path = _campaign_path(campaign_id)
	if not FileAccess.file_exists(path):
		push_error("Save file not found: %s" % path)
		return null
	var f = FileAccess.open(path, FileAccess.ModeFlags.READ)
	if f == null:
		push_error("Failed to open save file: %s" % path)
		return null
	var txt = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if parsed.error != OK:
		push_error("Failed to parse JSON for campaign %s" % campaign_id)
		return null
	var data: Dictionary = parsed.result
	# Handle simple migrations
	var ver = data.get("save_version", 0)
	if ver < CURRENT_SAVE_VERSION:
		data = _migrate_save(data, ver)
	return data

func _migrate_save(data:Dictionary, from_version:int) -> Dictionary:
	# For now, there's nothing to migrate. Add migration logic here as format evolves.
	print("Migrating campaign from v%d to v%d" % [from_version, CURRENT_SAVE_VERSION])
	data["save_version"] = CURRENT_SAVE_VERSION
	return data

func list_saves() -> Array:
	var out := []
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	var fname = dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			out.append(fname.replace(".json", ""))
		fname = dir.get_next()
	return out
