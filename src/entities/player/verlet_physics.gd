class_name VerletPhysics
extends RefCounted

class VPoint:
	var pos: Vector2
	var old_pos: Vector2
	var locked: bool = false
	var mass: float = 1.0
	var friction: float = 0.0
	var drag: float = 0.90
	var collide_terrain: bool = true
	var collision_mask: int = 1
	var radius: float = 5.0
	var accumulated_force: Vector2 = Vector2.ZERO
	
	func _init(start_pos: Vector2):
		pos = start_pos
		old_pos = start_pos

class VStick:
	var pA: int
	var pB: int
	var length: float
	var stiffness: float = 1.0
	var visible: bool = true
	var collide_terrain: bool = false
	var collision_mask: int = 1
	
	func _init(a: int, b: int, l: float, s: float = 1.0, vis: bool = true):
		pA = a
		pB = b
		length = l
		stiffness = s
		visible = vis

class VMotor:
	var p_idx: int
	var target_func: Callable
	var stiffness: float
	var axis: Vector2
	
	func _init(idx: int, t_func: Callable, s: float, ax: Vector2 = Vector2.ONE):
		p_idx = idx
		target_func = t_func
		stiffness = s
		axis = ax

class VAntiFlip:
	var pA: int
	var pPivot: int
	var pC: int
	var target_sign: int
	
	func _init(a: int, pivot: int, c: int, sign_val: int):
		pA = a
		pPivot = pivot
		pC = c
		target_sign = sign_val

var points: Array[VPoint] = []
var sticks: Array[VStick] = []
var motors: Array[VMotor] = []
var anti_flips: Array[VAntiFlip] = []

var _query_shape: CircleShape2D = CircleShape2D.new()
var _query_params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()

func add_point(pos: Vector2) -> int:
	points.append(VPoint.new(pos))
	return points.size() - 1

func add_stick(pA: int, pB: int, length: float = -1.0, stiffness: float = 1.0, visible: bool = true) -> int:
	if length < 0:
		length = points[pA].pos.distance_to(points[pB].pos)
	sticks.append(VStick.new(pA, pB, length, stiffness, visible))
	return sticks.size() - 1

func add_motor(p_idx: int, target_func: Callable, stiffness: float, axis: Vector2 = Vector2.ONE) -> int:
	motors.append(VMotor.new(p_idx, target_func, stiffness, axis))
	return motors.size() - 1

func add_anti_flip(pA: int, pPivot: int, pC: int) -> int:
	var vA = points[pA].pos - points[pPivot].pos
	var vC = points[pC].pos - points[pPivot].pos
	var sign_val = sign(vA.cross(vC))
	if sign_val == 0: sign_val = 1
	anti_flips.append(VAntiFlip.new(pA, pPivot, pC, sign_val))
	return anti_flips.size() - 1

func enforce_anti_stuck(origin: Vector2, max_dist: float = 120.0, min_dist: float = 80.0) -> void:
	for p in points:
		var dist = p.pos.distance_to(origin)
		if dist > max_dist:
			p.collide_terrain = false
		elif dist < min_dist:
			p.collide_terrain = true

func simulate(delta: float, space_state: PhysicsDirectSpaceState2D = null, collision_mask: int = 1, exclude_rids: Array[RID] = []):
	if space_state != null:
		_query_params.collide_with_areas = true
		_query_params.collide_with_bodies = true
		_query_params.collision_mask = collision_mask
		_query_params.exclude = exclude_rids

	# 1. 積分與受力計算 (Integration with Swept Circle Collision)
	for i in range(points.size()):
		var p = points[i]
		if p.locked:
			p.accumulated_force = Vector2.ZERO
			continue
			
		var velocity = p.pos - p.old_pos
		velocity *= p.drag
		
		var force = p.accumulated_force
		p.accumulated_force = Vector2.ZERO
		
		for m in motors:
			if m.p_idx == i:
				var target_pos = m.target_func.call()
				force += (target_pos - p.pos) * m.axis * m.stiffness
				
		var intended_motion = velocity + (force * delta * delta) / p.mass
		p.old_pos = p.pos
		
		if space_state != null and p.collide_terrain and intended_motion.length_squared() > 0.0001:
			_query_shape.radius = p.radius
			_query_params.shape_rid = _query_shape.get_rid()
			_query_params.transform = Transform2D(0, p.pos)
			_query_params.motion = intended_motion
			
			var fractions = space_state.cast_motion(_query_params)
			if fractions.size() == 2 and fractions[0] < 1.0:
				var hit_fraction = fractions[0]
				_query_params.transform = Transform2D(0, p.pos + intended_motion * hit_fraction)
				var rest = space_state.get_rest_info(_query_params)
				
				if not rest.is_empty():
					var normal = rest.normal
					var collider_id = rest.collider_id
					var collider = instance_from_id(collider_id) if collider_id != 0 else null
					
					if collider is Area2D:
						var body = collider.get_parent()
						if body and "velocity" in body:
							body.velocity -= normal * 1000.0 * delta
					elif collider is RigidBody2D:
						collider.apply_central_impulse(-normal * 20.0)
					
					var remaining_motion = intended_motion * (1.0 - hit_fraction)
					var slide_motion = remaining_motion.slide(normal)
					p.pos += intended_motion * hit_fraction + slide_motion
					
					var vel = p.pos - p.old_pos
					var tangent = Vector2(-normal.y, normal.x)
					var vel_tangent = vel.project(tangent)
					p.old_pos = p.pos - (vel_tangent * (1.0 - p.friction))
				else:
					p.pos += intended_motion
			else:
				p.pos += intended_motion
		else:
			p.pos += intended_motion

	# 2. 距離約束求解 (Constraints Resolution with Swept Circle)
	for iter in range(10):
		for stick in sticks:
			var pA = points[stick.pA]
			var pB = points[stick.pB]
			
			var delta_pos = pB.pos - pA.pos
			var dist = delta_pos.length()
			if dist == 0: continue
				
			var diff = (dist - stick.length) / dist
			var offset = delta_pos * diff * 0.5 * stick.stiffness
			
			if not pA.locked:
				if space_state != null and pA.collide_terrain and stick.collide_terrain:
					_query_shape.radius = pA.radius
					_query_params.shape_rid = _query_shape.get_rid()
					_query_params.transform = Transform2D(0, pA.pos)
					_query_params.motion = offset
					var fractions = space_state.cast_motion(_query_params)
					if fractions.size() == 2:
						pA.pos += offset * fractions[0]
				else:
					pA.pos += offset
					
			if not pB.locked:
				if space_state != null and pB.collide_terrain and stick.collide_terrain:
					_query_shape.radius = pB.radius
					_query_params.shape_rid = _query_shape.get_rid()
					_query_params.transform = Transform2D(0, pB.pos)
					_query_params.motion = -offset
					var fractions = space_state.cast_motion(_query_params)
					if fractions.size() == 2:
						pB.pos -= offset * fractions[0]
				else:
					pB.pos -= offset
				
		for af in anti_flips:
			var pA = points[af.pA]
			var pPivot = points[af.pPivot]
			var pC = points[af.pC]
			
			var vA = pA.pos - pPivot.pos
			var vC = pC.pos - pPivot.pos
			var current_cross = vA.cross(vC)
			
			if sign(current_cross) != af.target_sign:
				var push_dir = (vA - vC).normalized().rotated(PI/2) * af.target_sign
				var push_offset = push_dir * 5.0
				
				if not pA.locked:
					if space_state != null and pA.collide_terrain:
						_query_shape.radius = pA.radius
						_query_params.shape_rid = _query_shape.get_rid()
						_query_params.transform = Transform2D(0, pA.pos)
						_query_params.motion = push_offset
						var fractions = space_state.cast_motion(_query_params)
						if fractions.size() == 2: pA.pos += push_offset * fractions[0]
					else: pA.pos += push_offset
					
				if not pC.locked:
					if space_state != null and pC.collide_terrain:
						_query_shape.radius = pC.radius
						_query_params.shape_rid = _query_shape.get_rid()
						_query_params.transform = Transform2D(0, pC.pos)
						_query_params.motion = -push_offset
						var fractions = space_state.cast_motion(_query_params)
						if fractions.size() == 2: pC.pos -= push_offset * fractions[0]
					else: pC.pos -= push_offset
