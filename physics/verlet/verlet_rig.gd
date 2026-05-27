class_name VerletRig
extends Node2D

@export var global_mass: float = 1.0
@export var global_friction: float = 0.0
@export var global_drag: float = 0.90

# This rig owns its own visual nodes, but when injected, it hands their physics over to a central physics engine.
var target_physics: VerletPhysics = null

# Map visual nodes (Line2D) to lists of point indices in the target_physics
var line_point_map: Dictionary = {} # { Line2D_Node: [physics_idx_0, physics_idx_1, ...] }

func inject_into(physics: VerletPhysics) -> void:
	target_physics = physics
	
	# 1. Parse all Line2Ds
	for child in get_children():
		if child is Line2D:
			_inject_line(child)
			
	# 2. Parse Struts (internal constraints)
	for child in get_children():
		if child is VerletStrut:
			_inject_strut(child)
			
	# 3. Parse Pivots
	for child in get_children():
		if child is VerletPivot:
			_bind_pivot(child)

func _inject_line(line: Line2D) -> void:
	var indices: Array[int] = []
	var xform = line.global_transform
	
	for i in range(line.points.size()):
		var local_p = line.points[i]
		var global_p = xform * local_p
		var p_idx = target_physics.add_point(global_p)
		
		# Apply physical properties
		var p = target_physics.points[p_idx]
		p.mass = global_mass
		p.friction = global_friction
		p.drag = global_drag
		
		indices.append(p_idx)
		
		# Connect to previous point with a stick (invisible, Line2D handles drawing)
		if i > 0:
			target_physics.add_stick(indices[i-1], p_idx, -1.0, 1.0, false)
			
	line_point_map[line] = indices

func _inject_strut(strut: VerletStrut) -> void:
	var line_a = get_node_or_null(strut.node_a) as Line2D
	var line_b = get_node_or_null(strut.node_b) as Line2D
	if not line_a or not line_b: return
	if not line_point_map.has(line_a) or not line_point_map.has(line_b): return
	
	# Check bounds
	if strut.point_index_a >= line_point_map[line_a].size() or strut.point_index_b >= line_point_map[line_b].size(): return
	
	var idx_a = line_point_map[line_a][strut.point_index_a]
	var idx_b = line_point_map[line_b][strut.point_index_b]
	
	target_physics.add_stick(idx_a, idx_b, -1.0, strut.stiffness, false)

func _bind_pivot(pivot: VerletPivot) -> void:
	var pivot_pos = pivot.global_position
	var closest_idx = -1
	var closest_dist = INF
	
	for line in line_point_map:
		var indices = line_point_map[line]
		for p_idx in indices:
			var dist = pivot_pos.distance_squared_to(target_physics.points[p_idx].pos)
			if dist < closest_dist:
				closest_dist = dist
				closest_idx = p_idx
				
	pivot.physics_index = closest_idx

# Function to get a pivot by name for easy attachment
func get_pivot(p_name: String) -> VerletPivot:
	for child in get_children():
		if child is VerletPivot and child.pivot_name == p_name:
			return child
	return null

func _process(_delta: float) -> void:
	if not target_physics: return
	
	# Update visuals from physics
	for line in line_point_map:
		var indices = line_point_map[line]
		var inv_xform = line.global_transform.affine_inverse()
		for i in range(indices.size()):
			var p_idx = indices[i]
			if p_idx >= target_physics.points.size():
				continue # Safety check in case of truncation
			var global_p = target_physics.points[p_idx].pos
			# Convert back to local space for Line2D
			line.points[i] = inv_xform * global_p
