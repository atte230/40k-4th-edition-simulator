extends Node

# DeploymentManager.gd
# Computes deployment positions for spawn zones, using board extents if available.

class_name DeploymentManager

const DEFAULT_WIDTH := 100.0
const DEFAULT_DEPTH := 100.0
const DEFAULT_DEPLOY_DISTANCE := 12.0
const EDGE_PADDING := 5.0

func _init():
	pass

# spawn_zone: string like "north", "south", "east", "west", "northeast", "opposite"
# count: number of units to position
# board_node: optional node that may expose get_width/get_depth or meta data
func get_positions(spawn_zone:String, count:int, board_node:Node=null, deploy_distance:float=DEFAULT_DEPLOY_DISTANCE) -> Array:
	var width = DEFAULT_WIDTH
	var depth = DEFAULT_DEPTH
	var y = 0.0
	if board_node != null:
		if board_node.has_meta("width"):
			width = float(board_node.get_meta("width"))
		elif board_node.has_method("get_width"):
			width = float(board_node.call("get_width"))
		if board_node.has_meta("depth"):
			depth = float(board_node.get_meta("depth"))
		elif board_node.has_method("get_depth"):
			depth = float(board_node.call("get_depth"))

	var half_w = width * 0.5
	var half_d = depth * 0.5
	var positions := []
	for i in range(count):
		var t = 0.0
		if count > 1:
			t = float(i) / float(count - 1)
		else:
			t = 0.5
		var zone = spawn_zone.to_lower()
		match zone:
			"north", "n":
				var x = lerp(-half_w + EDGE_PADDING, half_w - EDGE_PADDING, t)
				var z = half_d - deploy_distance
				positions.append(Vector3(x, y, z))
			"south", "s":
				var x = lerp(-half_w + EDGE_PADDING, half_w - EDGE_PADDING, t)
				var z = -half_d + deploy_distance
				positions.append(Vector3(x, y, z))
			"east", "e":
				var z = lerp(-half_d + EDGE_PADDING, half_d - EDGE_PADDING, t)
				var x = half_w - deploy_distance
				positions.append(Vector3(x, y, z))
			"west", "w":
				var z = lerp(-half_d + EDGE_PADDING, half_d - EDGE_PADDING, t)
				var x = -half_w + deploy_distance
				positions.append(Vector3(x, y, z))
			"northeast", "ne":
				var x = half_w - deploy_distance
				var z = half_d - deploy_distance
				positions.append(Vector3(x, y, z))
			"northwest", "nw":
				var x = -half_w + deploy_distance
				var z = half_d - deploy_distance
				positions.append(Vector3(x, y, z))
			"southeast", "se":
				var x = half_w - deploy_distance
				var z = -half_d + deploy_distance
				positions.append(Vector3(x, y, z))
			"southwest", "sw":
				var x = -half_w + deploy_distance
				var z = -half_d + deploy_distance
				positions.append(Vector3(x, y, z))
			"opposite":
				# default to north for now
				var x = lerp(-half_w + EDGE_PADDING, half_w - EDGE_PADDING, t)
				var z = half_d - deploy_distance
				positions.append(Vector3(x, y, z))
			_:
				# default to north
				var x = lerp(-half_w + EDGE_PADDING, half_w - EDGE_PADDING, t)
				var z = half_d - deploy_distance
				positions.append(Vector3(x, y, z))
	return positions
