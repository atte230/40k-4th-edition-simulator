extends Node

# FormationManager.gd (polished)
# Improved formation and spacing helper to avoid unit overlap and provide basic facing/placement for melee.

class_name FormationManager

# Arrange a group of units into non-overlapping positions preserving their current centroid
# units: Array of Node3D (Unit) objects
# spacing_margin: additional spacing to apply between models
func arrange_formation(units:Array, spacing_margin:float = 0.2) -> void:
	if units == null or units.empty():
		return
	# Compute centroid
	var centroid = Vector3.ZERO
	var count = 0
	for u in units:
		if u == null or not u.has_method("to_persistent_dict"):
			continue
		centroid += u.global_transform.origin
		count += 1
	centroid = centroid / float(max(1, count))

	# Spread units radially from centroid proportional to their index but keep current relative bearing
	var angle_step = TAU / float(max(1, count))
	var i = 0
	for u in units:
		if u == null:
			continue
		var r = float(u.get("radius", 0.5))
		var desired_dist = max(1.0, r * 3.0) # reasonable minimal distance from center
		var angle = i * angle_step
		var offset = Vector3(cos(angle) * desired_dist, 0, sin(angle) * desired_dist)
		var newpos = centroid + offset
		newpos.y = u.global_transform.origin.y
		u.global_transform = Transform(u.global_transform.basis, newpos)
		i += 1

	# resolve overlaps more thoroughly
	resolve_overlaps(units, spacing_margin, 8)

# Simple nudge apart function to be called repeatedly until overlaps are resolved
func resolve_overlaps(units:Array, spacing_margin:float = 0.2, iterations:int = 6) -> void:
	for iter in range(iterations):
		for i in range(units.size()):
			var a = units[i]
			if a == null:
				continue
			for j in range(i+1, units.size()):
				var b = units[j]
				if b == null:
					continue
				var pa = a.global_transform.origin
				var pb = b.global_transform.origin
				var diff = pa - pb
				var dist = diff.length()
				var rsum = float(a.get("radius", 0.5)) + float(b.get("radius", 0.5)) + spacing_margin
				if dist < 0.001:
					diff = Vector3(0.1,0,0)
					dist = diff.length()
				if dist < rsum:
					var overlap = rsum - dist
					var push = diff.normalized() * (overlap * 0.5)
					# Respect terrain Y by only moving on XZ plane
					pa += Vector3(push.x, 0, push.z)
					pb -= Vector3(push.x, 0, push.z)
					a.global_transform = Transform(a.global_transform.basis, pa)
					b.global_transform = Transform(b.global_transform.basis, pb)

# Basic facing enforcement: make all units face the centroid (useful for melee)
func enforce_facing_towards_centroid(units:Array) -> void:
	if units == null or units.empty():
		return
	var centroid = Vector3.ZERO
	var count = 0
	for u in units:
		if u == null or not u.has_method("to_persistent_dict"):
			continue
		centroid += u.global_transform.origin
		count += 1
	centroid = centroid / float(max(1, count))
	for u in units:
		if u == null:
			continue
		var dir = (centroid - u.global_transform.origin).normalized()
		# build a basis that faces dir on XZ plane
		var forward = Vector3(dir.x, 0, dir.z).normalized()
		var right = forward.cross(Vector3.UP).normalized()
		var basis = Basis(right, Vector3.UP, forward)
		u.global_transform = Transform(basis, u.global_transform.origin)
