extends NavigationRegion2D

func _ready() -> void:
	# Enable parsing of static colliders
	var nav_poly = NavigationPolygon.new()
	nav_poly.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_poly.agent_radius = 15.0 # Give zombies some clearance
	nav_poly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	
	# Add a precise base outline that traces the interior of the rooms.
	# This prevents Geometry2D Clipper bugs caused by subtracting overlapping wall segments.
	var outline = PackedVector2Array([
		Vector2(-400, -300), # West Room Top-Left
		Vector2(400, -300),  # West Room Top-Right
		Vector2(400, -20),   # Door Top-Left
		Vector2(410, -20),   # Door Top-Right
		Vector2(410, -200),  # East Room Top-Left
		Vector2(1000, -200), # East Room Top-Right
		Vector2(1000, 200),  # East Room Bottom-Right
		Vector2(410, 200),   # East Room Bottom-Left
		Vector2(410, 20),    # Door Bottom-Right
		Vector2(400, 20),    # Door Bottom-Left
		Vector2(400, 300),   # West Room Bottom-Right
		Vector2(-400, 300)   # West Room Bottom-Left
	])
	nav_poly.add_outline(outline)
	
	navigation_polygon = nav_poly
	
	# Delay baking to next frame to ensure all collision shapes are initialized
	call_deferred("bake_navigation_polygon")

func rebuild_nav() -> void:
	bake_navigation_polygon()
