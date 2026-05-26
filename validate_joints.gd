extends SceneTree

# 驗證腳本：在 headless 模式下跑 90 幀，輸出關節座標並驗證三條標準
# 使用方式：godot --headless --path <proj> --script validate_joints.gd

var frame_count: int = 0
var drawer_node = null

const VALIDATE_AT_FRAMES = [30, 60, 90]

# 追蹤 BLADE_TIP 的 Y 座標幅度（驗證 C）
var blade_y_min: float = INF
var blade_y_max: float = -INF

func _init():
	# 載入主場景
	var scene = load("res://levels/main.tscn")
	if not scene:
		print("ERROR: 找不到 levels/main.tscn")
		quit(1)
		return
	var root_node = scene.instantiate()
	get_root().add_child(root_node)
	print("=== 關節驗證開始 ===")

func _process(_delta: float) -> bool:
	frame_count += 1
	
	# 找 ProceduralDrawer 節點
	if drawer_node == null:
		drawer_node = _find_drawer(get_root())
	
	if drawer_node == null:
		if frame_count > 10:
			print("ERROR: 找不到 ProceduralDrawer 節點")
			quit(1)
		return false
	
	# 取得 verlet 的物理資料
	var verlet = drawer_node.verlet
	if verlet == null or verlet.points.size() == 0:
		return false
	
	# 追蹤 BLADE_TIP Y 座標
	var blade_idx = drawer_node.J.BLADE_TIP
	var rhand_idx = drawer_node.J.R_HAND
	var spine_idx = drawer_node.J.SPINE_TOP
	var relbow_idx = drawer_node.J.R_ELBOW
	
	if verlet.points.size() <= blade_idx:
		return false
	
	var blade_pos = verlet.points[blade_idx].pos
	var rhand_pos = verlet.points[rhand_idx].pos
	var spine_pos = verlet.points[spine_idx].pos
	var relbow_pos = verlet.points[relbow_idx].pos
	
	blade_y_min = min(blade_y_min, blade_pos.y)
	blade_y_max = max(blade_y_max, blade_pos.y)
	
	if frame_count in VALIDATE_AT_FRAMES:
		var dist = rhand_pos.distance_to(blade_pos)
		print("=== Frame %d ===" % frame_count)
		print("  R_HAND   : (%.1f, %.1f)" % [rhand_pos.x, rhand_pos.y])
		print("  BLADE_TIP: (%.1f, %.1f)" % [blade_pos.x, blade_pos.y])
		print("  SPINE_TOP: (%.1f, %.1f)" % [spine_pos.x, spine_pos.y])
		print("  R_ELBOW  : (%.1f, %.1f)" % [relbow_pos.x, relbow_pos.y])
		print("  [驗證A] R_HAND→BLADE_TIP 距離 = %.1f (目標: 45±2)" % dist)
		
		var elbow_forward = relbow_pos.x - spine_pos.x
		print("  [驗證B] R_ELBOW.x - SPINE_TOP.x = %.1f (目標: > 5)" % elbow_forward)
	
	if frame_count >= 90:
		var blade_swing = blade_y_max - blade_y_min
		print("\n=== 最終驗證報告 ===")
		print("[驗證C] BLADE_TIP Y 擺動幅度 (幀1~90) = %.1fpx (目標: > 15px)" % blade_swing)
		
		# 最終一幀的結論
		var dist_final = verlet.points[rhand_idx].pos.distance_to(verlet.points[blade_idx].pos)
		var elbow_fwd_final = verlet.points[relbow_idx].pos.x - verlet.points[spine_idx].pos.x
		
		print("\n--- 通過/失敗 ---")
		print("驗證A (距離≈45): %s (%.1f)" % ["✓ PASS" if abs(dist_final - 45.0) < 3.0 else "✗ FAIL", dist_final])
		print("驗證B (肘在前>5): %s (%.1f)" % ["✓ PASS" if elbow_fwd_final > 5.0 else "✗ FAIL", elbow_fwd_final])
		print("驗證C (晃動>15px): %s (%.1fpx)" % ["✓ PASS" if blade_swing > 15.0 else "✗ FAIL", blade_swing])
		
		quit(0)
	
	return false

func _find_drawer(node: Node) -> Node:
	if node.get_script() != null:
		var script = node.get_script()
		if script and script.resource_path.contains("procedural_drawer"):
			return node
	for child in node.get_children():
		var result = _find_drawer(child)
		if result != null:
			return result
	return null
