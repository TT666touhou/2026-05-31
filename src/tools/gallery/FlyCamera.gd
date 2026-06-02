extends Camera3D

@export var fly_speed: float = 10.0
@export var fast_fly_speed: float = 30.0
@export var mouse_sensitivity: float = 0.002

var rotation_x: float = 0.0
var rotation_y: float = 0.0
var is_mouse_captured: bool = false

signal model_hovered(model_info: Dictionary)

func _ready():
    capture_mouse()

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and not is_mouse_captured:
            # Only capture if we didn't click on UI
            var click_pos = event.position
            if click_pos.y > 80: # Below top UI bar
                capture_mouse()
                
    if event is InputEventMouseMotion and is_mouse_captured:
        rotation_y -= event.relative.x * mouse_sensitivity
        rotation_x -= event.relative.y * mouse_sensitivity
        rotation_x = clamp(rotation_x, -HALF_PI_FLOAT(), HALF_PI_FLOAT())
        
        transform.basis = Basis.from_euler(Vector3(rotation_x, rotation_y, 0))

    if event.is_action_pressed("ui_cancel"): # Escape key
        release_mouse()

func HALF_PI_FLOAT() -> float:
    return PI / 2.0

func capture_mouse():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    is_mouse_captured = true

func release_mouse():
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    is_mouse_captured = false

func _process(delta):
    # Movement
    var speed = fast_fly_speed if Input.is_key_pressed(KEY_SHIFT) else fly_speed
    var input_dir = Vector3.ZERO
    
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        input_dir.z -= 1
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        input_dir.z += 1
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        input_dir.x -= 1
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        input_dir.x += 1
    if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE):
        input_dir.y += 1
    if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_CTRL):
        input_dir.y -= 1
        
    input_dir = input_dir.normalized()
    var forward = -global_transform.basis.z
    var right = global_transform.basis.x
    var up = Vector3.UP
    
    var move_dir = (forward * -input_dir.z + right * input_dir.x + up * input_dir.y).normalized()
    if input_dir.length() > 0:
        global_translate(move_dir * speed * delta)
        
    # Raycast to detect models
    perform_raycast()

func perform_raycast():
    var space_state = get_world_3d().direct_space_state
    var mouse_pos = get_viewport().get_mouse_position()
    
    var origin = project_ray_origin(mouse_pos)
    var normal = project_ray_normal(mouse_pos)
    var end = origin + normal * 100.0
    
    var query = PhysicsRayQueryParameters3D.create(origin, end)
    query.collide_with_areas = true
    query.collide_with_bodies = true
    
    var result = space_state.intersect_ray(query)
    if result and result.collider:
        var collider = result.collider
        if collider.has_meta("model_name"):
            emit_signal("model_hovered", {
                "name": collider.get_meta("model_name"),
                "path": collider.get_meta("model_path"),
                "pack": collider.get_meta("model_pack")
            })
            return
            
    emit_signal("model_hovered", {})
