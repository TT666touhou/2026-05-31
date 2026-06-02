@tool
extends SceneTree

const MODELS_DIR = "res://assets/models"
const OUTPUT_PATH = "res://dungeon_library.tres"

# Mapping from pack folder name to short prefix
const PREFIX_MAP = {
	"psx_bunkers": "bnk_",
	"psx_comfortable_chair": "chr_",
	"psx_creatures": "cre_",
	"psx_debug_stuff": "dbg_",
	"psx_gifts_misc": "gft_",
	"psx_kidnapper_van": "van_",
	"psx_mega_pack": "mp1_",
	"psx_mega_pack_2": "mp2_",
	"psx_nature": "nat_",
	"psx_nature_branches_separated": "brn_",
	"psx_paintings": "pnt_",
	"psx_projector_flashlights": "lgt_",
	"psx_stinky_thoughts": "stk_",
	"psx_tech": "tch_"
}

func _init():
	print("=========================================")
	print("GENERATING GODOT MESHLIBRARY WITH CLEAN NAMES...")
	print("=========================================")
	
	var ml = MeshLibrary.new()
	var glb_files = get_all_glb_files(MODELS_DIR)
	print("Found ", glb_files.size(), " GLB files.")
	
	var item_id = 0
	var success_count = 0
	
	for file_path in glb_files:
		# Extract the pack name and the file base name
		var relative_path = file_path.replace(MODELS_DIR + "/", "")
		var parts = relative_path.split("/")
		if parts.size() == 0:
			continue
		
		var pack_name = parts[0]
		var file_name = file_path.get_file().get_basename()
		
		# Determine clean name
		var prefix = PREFIX_MAP.get(pack_name, "")
		if prefix == "":
			prefix = pack_name.substr(0, 3) + "_"
		
		var clean_name = prefix + file_name
		
		# Load GLB
		var scene = load(file_path)
		if not scene:
			print("  [Skip] Failed to load: ", file_path)
			continue
			
		var instance = scene.instantiate()
		if not instance:
			print("  [Skip] Failed to instantiate: ", file_path)
			continue
			
		# Find mesh instance recursively
		var mesh_inst = find_mesh_instance(instance)
		if not mesh_inst:
			instance.free()
			continue
			
		var mesh = mesh_inst.mesh
		if not mesh:
			instance.free()
			continue
			
		# Create item
		ml.create_item(item_id)
		ml.set_item_name(item_id, clean_name)
		ml.set_item_mesh(item_id, mesh)
		
		# Collision shape
		var shape = mesh.create_trimesh_shape()
		if shape:
			ml.set_item_shapes(item_id, [shape, Transform3D.IDENTITY])
			
		instance.free()
		
		success_count += 1
		item_id += 1
		
		if success_count % 100 == 0:
			print("Processed ", success_count, " items...")
			
	var err = ResourceSaver.save(ml, OUTPUT_PATH)
	if err == OK:
		print("=========================================")
		print("SUCCESS: MeshLibrary saved to: ", OUTPUT_PATH)
		print("Saved ", success_count, " items.")
		print("=========================================")
	else:
		print("ERROR: Failed to save MeshLibrary: ", err)
		
	quit()

func get_all_glb_files(path: String) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					files.append_array(get_all_glb_files(path.path_join(file_name)))
			else:
				if file_name.ends_with(".glb"):
					files.append(path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	return files

func find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var res = find_mesh_instance(child)
		if res:
			return res
	return null
