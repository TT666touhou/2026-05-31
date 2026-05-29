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
	# 1. 積分與受力計算
	for i in range(points.size()):
		var p = points[i]
		if p.locked:
			# 即使是 locked，也把累積的力清空避免殘留
			p.accumulated_force = Vector2.ZERO
			continue
			
		var velocity = p.pos - p.old_pos
		p.old_pos = p.pos
		
		# 基本空氣阻尼
		velocity *= p.drag
		
		var force = p.accumulated_force
		p.accumulated_force = Vector2.ZERO
		
		# 馬達彈簧牽引力
		for m in motors:
			if m.p_idx == i:
				var target_pos = m.target_func.call()
				force += (target_pos - p.pos) * m.axis * m.stiffness
				
		p.pos += velocity + (force * delta * delta) / p.mass

	# 2. 距離約束求解 (Constraints Resolution)
	for iter in range(10):
		for stick in sticks:
			var pA = points[stick.pA]
			var pB = points[stick.pB]
			
			var delta_pos = pB.pos - pA.pos
			var dist = delta_pos.length()
			if dist == 0:
				continue
				
			var diff = (dist - stick.length) / dist
			# 使用 stiffness 來決定約束的剛硬程度 (預設 1.0 = 完全剛硬)
			var offset = delta_pos * diff * 0.5 * stick.stiffness
			
			if not pA.locked:
				pA.pos += offset
			if not pB.locked:
				pB.pos -= offset
				
		for af in anti_flips:
			var pA = points[af.pA]
			var pPivot = points[af.pPivot]
			var pC = points[af.pC]
			
			var vA = pA.pos - pPivot.pos
			var vC = pC.pos - pPivot.pos
			var current_cross = vA.cross(vC)
			
			if sign(current_cross) != af.target_sign:
				# 發現翻轉！強制將 A 與 C 互相排斥以解開交叉
				var push_dir = (vA - vC).normalized().rotated(PI/2) * af.target_sign
				if not pA.locked: pA.pos += push_dir * 5.0
				if not pC.locked: pC.pos -= push_dir * 5.0

	# 3. 地形射線碰撞 (Terrain Collision)
	if space_state != null:
		for i in range(points.size()):
			var p = points[i]
			if p.locked or p.pos == p.old_pos or not p.collide_terrain: continue
			var query = PhysicsRayQueryParameters2D.create(p.old_pos, p.pos, collision_mask)
			query.collide_with_areas = true
			query.collide_with_bodies = true
			query.exclude = exclude_rids
			var result = space_state.intersect_ray(query)
			
			if result:
				var normal = result.normal
				
				var collider = result.collider
				if collider is Area2D:
					var body = collider.get_parent()
					if body and "velocity" in body:
						body.velocity -= normal * 1000.0 * delta
				elif collider is RigidBody2D:
					collider.apply_central_impulse(-normal * 20.0)
						
				p.pos = result.position + normal * p.radius
				
				var vel = p.pos - p.old_pos
				var tangent = Vector2(-normal.y, normal.x)
				var vel_tangent = vel.project(tangent)
				p.old_pos = p.pos - (vel_tangent * (1.0 - p.friction))
	
	# 4. 線段地形碰撞 (Stick vs Terrain Collision)
	if space_state != null:
		for stick in sticks:
			if not stick.collide_terrain: continue
			var pA = points[stick.pA]
			var pB = points[stick.pB]
			
			# 如果兩點都在同一個位置，忽略
			if pA.pos.distance_squared_to(pB.pos) < 1.0: continue
			
			var query = PhysicsRayQueryParameters2D.create(pA.pos, pB.pos, collision_mask)
			query.collide_with_areas = true
			query.collide_with_bodies = true
			query.exclude = exclude_rids
			# 允許從內部射出時命中，這樣可以檢測線段橫穿過碰撞體的情況
			query.hit_from_inside = true
			var result = space_state.intersect_ray(query)
			
			if result:
				var normal = result.normal
				# 有些時候 hit_from_inside 會給出 Vector2.ZERO 法線
				if normal.length_squared() < 0.1:
					normal = (pA.pos - pB.pos).normalized().rotated(PI/2)
					
				var collider = result.collider
				if collider is Area2D:
					var body = collider.get_parent()
					if body and "velocity" in body:
						body.velocity -= normal * 1500.0 * delta
				elif collider is RigidBody2D:
					collider.apply_central_impulse(-normal * 30.0)
					
				# 根據穿透點與兩端的距離，按比例分配推力
				var dist_A = pA.pos.distance_to(result.position)
				var dist_B = pB.pos.distance_to(result.position)
				var total = dist_A + dist_B
				
				if total > 0:
					# 越靠近碰撞點的端點，受到的推力越大
					var weight_A = 1.0 - (dist_A / total)
					var weight_B = 1.0 - (dist_B / total)
					
					# 施加向外推擠的力 (調整係數控制滑出牆角的速度，1.5 比較平緩不彈跳)
					var push_strength = 1.5
					if not pA.locked:
						pA.pos += normal * weight_A * push_strength
					if not pB.locked:
						pB.pos += normal * weight_B * push_strength
