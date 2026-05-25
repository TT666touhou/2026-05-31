class_name VerletPhysics
extends RefCounted

class VPoint:
	var pos: Vector2
	var old_pos: Vector2
	var locked: bool = false
	var mass: float = 1.0
	var friction: float = 0.0
	var drag: float = 0.90
	var accumulated_force: Vector2 = Vector2.ZERO
	
	func _init(start_pos: Vector2):
		pos = start_pos
		old_pos = start_pos

class VStick:
	var pA: int
	var pB: int
	var length: float
	var stiffness: float = 1.0
	
	func _init(a: int, b: int, l: float, s: float = 1.0):
		pA = a
		pB = b
		length = l
		stiffness = s

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

var points: Array[VPoint] = []
var sticks: Array[VStick] = []
var motors: Array[VMotor] = []

func add_point(pos: Vector2) -> int:
	points.append(VPoint.new(pos))
	return points.size() - 1

func add_stick(pA: int, pB: int, length: float = -1.0, stiffness: float = 1.0) -> int:
	if length < 0:
		length = points[pA].pos.distance_to(points[pB].pos)
	sticks.append(VStick.new(pA, pB, length, stiffness))
	return sticks.size() - 1

func add_motor(p_idx: int, target_func: Callable, stiffness: float, axis: Vector2 = Vector2.ONE) -> int:
	motors.append(VMotor.new(p_idx, target_func, stiffness, axis))
	return motors.size() - 1

func simulate(delta: float, gravity: Vector2, global_floor_y: float):
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
		
		var force = gravity * p.mass + p.accumulated_force
		p.accumulated_force = Vector2.ZERO
		
		# 馬達彈簧牽引力
		for m in motors:
			if m.p_idx == i:
				var target_pos = m.target_func.call()
				force += (target_pos - p.pos) * m.axis * m.stiffness
				
		p.pos += velocity + (force * delta * delta) / p.mass
		
		# 地板碰撞與摩擦力
		if p.pos.y > global_floor_y:
			p.pos.y = global_floor_y
			var v_x = p.pos.x - p.old_pos.x
			p.pos.x -= v_x * p.friction

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
