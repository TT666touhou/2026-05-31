extends SceneTree

# ============================================================
# 驗證腳本 v2：直接解析 procedural_drawer.gd 輸出的 DATA: 行
# DATA 格式：DATA:frame,pt0.x,pt0.y,pt1.x,pt1.y,...
# 索引：HIPS=0,SPINE_TOP=1,HEAD=2,L_ELBOW=3,L_HAND=4,R_ELBOW=5,R_HAND=6,...
# 劍點：sw0=11(柄), sw1=12(尖)
# ============================================================

const J_SPINE_TOP = 1
const J_R_ELBOW   = 5
const J_R_HAND    = 6
const SW0 = 11
const SW1 = 12

var frames = 0
var collected: Array = []  # Array of Array[Vector2]
var main_scene

func _init():
	main_scene = load("res://levels/main.tscn").instantiate()
	root.add_child(main_scene)
	# 連接 stdout 輸出（透過 print 的回傳）
	print("=== VALIDATION TEST START ===")

func _process(_delta):
	frames += 1

	if frames == 5:
		var ev = InputEventAction.new()
		ev.action = "ui_right"
		ev.pressed = true
		Input.parse_input_event(ev)

	# 只蒐集穩定走路後的幀（跳過前 30 幀的加速期）
	if frames > 30 and frames <= 90:
		_collect_frame()

	if frames == 91:
		_run_validation()
		quit()

func _collect_frame():
	# 找到 ProceduralDrawer 節點（用腳本路徑判斷更可靠）
	var drawer = _find_by_script(main_scene, "res://entities/player/procedural_drawer.gd")
	if not drawer:
		return
	var verlet = drawer.get("verlet")
	if not verlet:
		return
	var pts: Array = verlet.get("points")
	if pts.size() < SW1 + 1:
		return
	var row: Array[Vector2] = []
	for p in pts:
		row.append(p.get("pos"))
	collected.append(row)

func _find_by_script(node: Node, script_path: String) -> Node:
	var s = node.get_script()
	if s and s.resource_path == script_path:
		return node
	for child in node.get_children():
		var r = _find_by_script(child, script_path)
		if r: return r
	return null

func _run_validation():
	print("\n=== VALIDATION RESULTS ===")
	print("資料幀數：%d" % collected.size())

	if collected.size() < 20:
		print("FAIL: 資料不足（節點搜尋失敗）")
		_fallback_parse_stdout()
		return

	_check_all(collected)

func _check_all(rows: Array):
	var n = rows.size()

	# 標準 1：R_HAND 距 sw0 < 2px
	var max_dist = 0.0
	var fail1 = 0
	for row in rows:
		if row.size() <= SW0: continue
		var d = row[J_R_HAND].distance_to(row[SW0])
		if d > max_dist: max_dist = d
		if d > 2.0: fail1 += 1
	var p1 = fail1 == 0
	print("[標準1] R_HAND↔劍柄 最大距離: %.2fpx  %s  (失敗幀: %d/%d)" % [
		max_dist, "PASS✅" if p1 else "FAIL❌", fail1, n])

	# 標準 2：右手（劍柄）在肩膀前方（向右走，facing_dir=1）
	# 劍柄（R_HAND/sw0）應在肩膀前方，這是核心要求
	var hand_front_count = 0
	var elbow_front_count = 0
	for row in rows:
		if row.size() <= J_R_ELBOW: continue
		var spine_x   = row[J_SPINE_TOP].x
		var r_hand_x  = row[J_R_HAND].x
		var r_elbow_x = row[J_R_ELBOW].x
		if r_hand_x > spine_x: hand_front_count += 1
		if r_elbow_x > spine_x: elbow_front_count += 1
	var hand_pct  = float(hand_front_count)  / float(n) * 100.0
	var elbow_pct = float(elbow_front_count) / float(n) * 100.0
	# 標準：右手（劍柄）至少 70% 時間在肩前；手肘 50% 即可（劍擺動時會帶走肘）
	var p2 = hand_pct >= 70.0
	print("[標準2] 右手(劍柄)在肩前: %.1f%%  %s" % [hand_pct, "PASS✅" if p2 else "FAIL❌"])
	print("        右肘在肩前: %.1f%%" % elbow_pct)

	# 標準 3：劍尖 Y 擺動 > 15px
	var ys: Array = []
	for row in rows:
		if row.size() > SW1: ys.append(row[SW1].y)
	var swing = (ys.max() - ys.min()) if ys.size() > 0 else 0.0
	var p3 = swing > 15.0
	print("[標準3] 劍尖Y擺動: %.2fpx  %s" % [swing, "PASS✅" if p3 else "FAIL❌"])

	print("\n=== SUMMARY: %s ===" % ("全部通過✅" if (p1 and p2 and p3) else "有標準未通過❌"))

	# 最後一幀座標
	if rows.size() > 0:
		var last = rows[-1]
		var names = ["HIPS","SPINE_TOP","HEAD","L_ELBOW","L_HAND","R_ELBOW","R_HAND",
					 "L_KNEE","L_FOOT","R_KNEE","R_FOOT","sw0(柄)","sw1(尖)"]
		print("\n[最後一幀座標]")
		for i in range(min(last.size(), names.size())):
			print("  %s: (%.1f, %.1f)" % [names[i], last[i].x, last[i].y])

func _fallback_parse_stdout():
	print("（後備模式：無法直接讀取 verlet，請目視 DATA 輸出）")
