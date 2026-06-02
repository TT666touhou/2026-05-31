extends Node3D

@export var spacing_x: float = 6.0
@export var spacing_z: float = 6.0
@export var columns: int = 15

var all_models: Array = [] # List of Dictionary: { "path": String, "name": String, "pack": String }
var current_instances: Array = []

signal loading_progress(current: int, total: int)
signal loading_completed()

func _ready():
    scan_assets()
    generate_gallery("", "All")

func scan_assets():
    all_models.clear()
    var root_path = "res://assets/models"
    if not DirAccess.dir_exists_absolute(root_path):
        return
        
    var dir = DirAccess.open(root_path)
    if dir:
        dir.list_dir_begin()
        var pack_name = dir.get_next()
        while pack_name != "":
            if dir.current_is_dir() and pack_name != "." and pack_name != "..":
                scan_pack_dir(root_path.path_join(pack_name), pack_name)
            pack_name = dir.get_next()
        dir.list_dir_end()

func scan_pack_dir(path: String, pack_name: String):
    var files_list = []
    scan_dir_recursive(path, files_list)
    for f in files_list:
        var filename = f.get_file().get_basename()
        all_models.append({
            "path": f,
            "name": filename,
            "pack": pack_name
        })

func scan_dir_recursive(path: String, out_list: Array):
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                if file_name != "." and file_name != "..":
                    scan_dir_recursive(path.path_join(file_name), out_list)
            else:
                if file_name.ends_with(".glb"):
                    out_list.append(path.path_join(file_name))
            file_name = dir.get_next()
        dir.list_dir_end()

func generate_gallery(search_filter: String, pack_filter: String):
    # Clean old instances
    for inst in current_instances:
        if is_instance_valid(inst):
            inst.queue_free()
    current_instances.clear()
    
    # Filter list
    var filtered = []
    for m in all_models:
        var match_search = search_filter.strip_edges() == "" or search_filter.to_lower() in m.name.to_lower()
        var match_pack = pack_filter == "All" or m.pack == pack_filter
        if match_search and match_pack:
            filtered.append(m)
            
    print("Generating gallery with ", len(filtered), " models (Filter search: '", search_filter, "', pack: '", pack_filter, "')")
    
    # Spawn in grid
    var total = len(filtered)
    for i in range(total):
        var model_info = filtered[i]
        
        var col = i % columns
        var row = i / columns
        
        # Calculate grid position
        var pos = Vector3(col * spacing_x, 0.0, -row * spacing_z)
        
        var wrapper = Node3D.new()
        wrapper.name = "Model_" + model_info.name
        wrapper.position = pos
        add_child(wrapper)
        current_instances.append(wrapper)
        
        # Spawn the actual GLB
        var glb_scene = load(model_info.path)
        if glb_scene:
            var glb_instance = glb_scene.instantiate()
            wrapper.add_child(glb_instance)
            
            # Combine AABBs to set label and collision shape
            var aabb = get_combined_aabb(glb_instance)
            
            # 1. Create Collision Area3D
            var area = Area3D.new()
            area.name = "CollisionArea"
            area.set_meta("model_name", model_info.name)
            area.set_meta("model_path", model_info.path)
            area.set_meta("model_pack", model_info.pack)
            wrapper.add_child(area)
            
            var col_shape = CollisionShape3D.new()
            var box_shape = BoxShape3D.new()
            box_shape.size = Vector3(
                max(aabb.size.x, 0.4),
                max(aabb.size.y, 0.4),
                max(aabb.size.z, 0.4)
            )
            col_shape.shape = box_shape
            # Center of AABB
            col_shape.position = aabb.position + aabb.size / 2.0
            area.add_child(col_shape)
            
            # 2. Create Floating Label3D
            var label = Label3D.new()
            label.text = model_info.name
            label.billboard = Label3D.BILLBOARD_ENABLED
            label.font_size = 32
            label.outline_size = 8
            label.pixel_size = 0.005
            
            # Position it above the top of the AABB
            var top_y = aabb.position.y + aabb.size.y
            label.position = Vector3(0, max(top_y + 0.3, 1.0), 0)
            wrapper.add_child(label)
            
        emit_signal("loading_progress", i + 1, total)
        
    emit_signal("loading_completed")

func get_combined_aabb(node: Node) -> AABB:
    var combined = AABB()
    var first = true
    
    var meshes = []
    find_meshes_recursive(node, meshes)
    
    # We must make sure the node is in the tree and has transforms updated
    # Since we just instanced it, we can calculate transforms manually.
    for mesh in meshes:
        var local_aabb = mesh.get_aabb()
        
        # Calculate local transform relative to node (the GLB root)
        var t = mesh.transform
        var parent = mesh.get_parent()
        while parent != null and parent != node:
            t = parent.transform * t
            parent = parent.get_parent()
            
        var node_local_aabb = t * local_aabb
        if first:
            combined = node_local_aabb
            first = false
        else:
            combined = combined.merge(node_local_aabb)
            
    if first:
        # Default small box if no meshes found
        combined = AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
        
    return combined

func find_meshes_recursive(node: Node, out_list: Array):
    if node is MeshInstance3D:
        out_list.append(node)
    for child in node.get_children():
        find_meshes_recursive(child, out_list)

func get_pack_list() -> Array:
    var packs = ["All"]
    var root_path = "res://assets/models"
    if DirAccess.dir_exists_absolute(root_path):
        var dir = DirAccess.open(root_path)
        if dir:
            dir.list_dir_begin()
            var pack_name = dir.get_next()
            while pack_name != "":
                if dir.current_is_dir() and pack_name != "." and pack_name != "..":
                    packs.append(pack_name)
                pack_name = dir.get_next()
            dir.list_dir_end()
    return packs
