extends CharacterBody2D

class_name PlayerController

@export var move_speed: float = 80.0
@export var dash_speed: float = 250.0

var dash_timer: float = 0.0
var current_dash_dir: Vector2 = Vector2.ZERO
var current_aim_direction: Vector2 = Vector2.RIGHT
var _was_shift_pressed: bool = false

var inv_mgr # Untyped to prevent parse errors before cache update
var inv_ui # Untyped
var active_hotbar_index: int = 0
var current_equipped_item = null # Type ItemData
var drawer: Node2D

@onready var state_machine = get_node_or_null("StateMachine")
@onready var hurtbox = $HurtboxComponent
@onready var health = $HealthComponent
@onready var stamina = $StaminaComponent
@onready var mana = $ManaComponent
@onready var vision_light = get_node_or_null("VisionLight")

func _ready() -> void:
	add_to_group("player")
	drawer = get_node_or_null("ProceduralDrawer")
	
	if health:
		health.health_changed.connect(_on_health_changed)
		health.died.connect(_on_died)
	

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
	
	# 向 VisionManager 注册玩家与视野光源
	if vision_light:
		var vm := get_node_or_null("/root/VisionManager") as VisionManagerSingleton
		if vm:
			vm.register_player(self, vision_light)
	
	# Setup Inventory System
	var InventoryManagerClass = preload("res://src/systems/inventory/InventoryManager.gd")
	inv_mgr = InventoryManagerClass.new()
	inv_mgr.inventory_changed.connect(_on_inventory_changed)
	add_child(inv_mgr)
	
	# CanvasLayer for UI
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	# Setup HUD
	var hud_scene = preload("res://src/ui/hud/PlayerHUD.tscn")
	if hud_scene:
		var hud = hud_scene.instantiate()
		canvas.add_child(hud)
		hud.setup(health, stamina, mana)
	
	var ui_scene = preload("res://src/ui/inventory/InventoryUI.tscn")
	if ui_scene:
		inv_ui = ui_scene.instantiate()
		inv_ui.set_manager(inv_mgr)
		inv_ui.item_dropped_outside.connect(_on_item_dropped_outside)
		inv_ui.visible = true
		canvas.add_child(inv_ui)
		
	# Populate some initial items for testing
	var ItemDataClass = preload("res://src/systems/inventory/ItemData.gd")
	if ItemDataClass:
		var sword_data = ItemDataClass.new()
		sword_data.id = "sword"
		sword_data.item_name = "Procedural Sword"
		sword_data.grid_size = Vector2i(1, 3)
		sword_data.stamina_cost = 15.0
		sword_data.weapon_scene = preload("res://src/items/weapons/sword.tscn")
		var s_lines: Array[PackedVector2Array] = [
			PackedVector2Array([Vector2(0, -0.4), Vector2(0, 0.4)]),
			PackedVector2Array([Vector2(-0.2, 0.2), Vector2(0.2, 0.2)])
		]
		sword_data.icon_lines = s_lines
		inv_mgr.set_hotbar_item(0, sword_data)
		
		var bow_data = ItemDataClass.new()
		bow_data.id = "bow"
		bow_data.item_name = "Procedural Bow"
		bow_data.grid_size = Vector2i(2, 3)
		bow_data.stamina_cost = 10.0
		bow_data.weapon_scene = preload("res://src/items/weapons/bow.tscn")
		var b_lines: Array[PackedVector2Array] = [
			PackedVector2Array([Vector2(0, -0.4), Vector2(-0.2, 0), Vector2(0, 0.4)]), # Bow body
			PackedVector2Array([Vector2(0, -0.4), Vector2(0, 0.4)]) # String
		]
		bow_data.icon_lines = b_lines
		inv_mgr.set_hotbar_item(1, bow_data)
		
		_equip_hotbar_slot(0)

func _on_item_dropped_outside(item_data: ItemData, _global_mouse_pos: Vector2) -> void:
	var drop_pos = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	_drop_item(item_data, drop_pos)

func _drop_item(data, pos: Vector2 = global_position) -> void:
	var drop_scene = preload("res://src/items/drops/ItemDrop.tscn")
	if drop_scene and data:
		var drop = drop_scene.instantiate()
		get_parent().add_child(drop) # Add to world
		drop.global_position = pos
		drop.setup(data)

func _on_inventory_changed() -> void:
	_equip_hotbar_slot(active_hotbar_index)

func _equip_hotbar_slot(idx: int) -> void:
	active_hotbar_index = idx
	if inv_ui:
		inv_ui.active_hotbar_index = idx
		inv_ui.queue_redraw()
	
	if not drawer: return
	
	var item = inv_mgr.hotbar_items[idx]
	var new_item_data = item.data if item else null
	
	if current_equipped_item == new_item_data:
		return # No change in this slot
		
	current_equipped_item = new_item_data
	
	if new_item_data and new_item_data.weapon_scene:
		drawer.equip(new_item_data.weapon_scene)
	else:
		drawer.equip(preload("res://src/items/weapons/unarmed.tscn")) # Default to fists when empty

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_E:
			if inv_ui:
				inv_ui.toggle_backpack()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1: _equip_hotbar_slot(0)
		elif event.keycode == KEY_2: _equip_hotbar_slot(1)
		elif event.keycode == KEY_3: _equip_hotbar_slot(2)
		elif event.keycode == KEY_4: _equip_hotbar_slot(3)
		elif event.keycode == KEY_Q:
			# Drop current equipped item
			var item = inv_mgr.hotbar_items[active_hotbar_index]
			if item:
				_drop_item(item.data, global_position)
				inv_mgr.remove_from_hotbar(active_hotbar_index)
				drawer.unequip()
		elif event.keycode == KEY_F:
			# Pick up nearby items
			for node in get_parent().get_children():
				if node is ItemDrop and node.global_position.distance_to(global_position) < 50.0:
					if inv_mgr.auto_add_to_backpack(node.item_data):
						node.queue_free()
						break # Pick up one at a time
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_idx = (active_hotbar_index - 1) % 4
			if new_idx < 0: new_idx += 4
			_equip_hotbar_slot(new_idx)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_idx = (active_hotbar_index + 1) % 4
			_equip_hotbar_slot(new_idx)
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = current_dash_dir * dash_speed
	else:
		var input_dir = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)
		
		# 相容原本寫死的 WASD
		if input_dir == Vector2.ZERO:
			if Input.is_key_pressed(KEY_D): input_dir.x += 1
			if Input.is_key_pressed(KEY_A): input_dir.x -= 1
			if Input.is_key_pressed(KEY_S): input_dir.y += 1
			if Input.is_key_pressed(KEY_W): input_dir.y -= 1
			
		if input_dir.length_squared() > 1.0:
			input_dir = input_dir.normalized()
			
		var is_shift = Input.is_key_pressed(KEY_SHIFT)
		if Input.is_action_just_pressed("dash") or (is_shift and not _was_shift_pressed):
			if input_dir != Vector2.ZERO:
				if not stamina or stamina.consume(15.0): # Dash costs 15 stamina
					dash_timer = 0.2
					current_dash_dir = input_dir
					velocity = current_dash_dir * dash_speed
		
		_was_shift_pressed = is_shift
				
		velocity = input_dir * move_speed
		
	move_and_slide()
	
	# 對剛體施加推力 (真實物理感)
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is RigidBody2D:
			# 施加在碰撞點上的衝量 (這樣推邊緣會有槓桿效應轉得比較快)
			var push_force = 800.0
			var offset = c.get_position() - collider.global_position
			collider.apply_impulse(-c.get_normal() * push_force, offset)
	
	var mouse_pos = get_global_mouse_position()
	current_aim_direction = (mouse_pos - global_position).normalized()
	
	if vision_light:
		vision_light.rotation = current_aim_direction.angle()
	
	# 處理攻擊輸入 (若 UI 開啟則阻擋攻擊，除非需要)
	if inv_ui and inv_ui.backpack_open: return
	
	if Input.is_action_just_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if drawer and drawer.current_weapon_rig:
			var weapon = drawer.current_weapon_rig.get_node_or_null("WeaponController")
			if not weapon:
				weapon = drawer.current_weapon_rig
			
			if weapon and weapon.has_method("start_attack"):
				var cost = 0.0
				if current_equipped_item != null:
					cost = current_equipped_item.stamina_cost
				
				if cost <= 0.0 or not stamina or stamina.has_enough(cost):
					if weapon.start_attack(get_global_mouse_position()):
						if stamina and cost > 0.0:
							stamina.consume(cost)
	
	if Input.is_action_just_released("attack") or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if drawer and drawer.current_weapon_rig:
			var weapon = drawer.current_weapon_rig.get_node_or_null("WeaponController")
			if not weapon:
				weapon = drawer.current_weapon_rig
			
			if weapon and weapon.has_method("end_attack"):
				weapon.end_attack(get_global_mouse_position())

func _on_hit_received(_damage: float, knockback: Vector2) -> void:
	# knockback points away from the source, push the player backwards
	velocity += knockback
	
func _on_health_changed(old_val: float, new_val: float) -> void:
	var dmg = old_val - new_val
	
	# Spawn damage number for player
	var label = Label.new()
	label.text = str(round(dmg))
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_font_size_override("font_size", 12)
	label.global_position = global_position + Vector2(randf_range(-20, 20), -60)
	get_tree().current_scene.add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -50), 0.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.tween_callback(label.queue_free)

func _on_died() -> void:
	print("Player died! ")
	get_tree().reload_current_scene()
