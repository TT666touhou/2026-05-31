extends "res://addons/gut/test.gd"

func test_viewport_width_is_640() -> void:
    var width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
    assert_eq(width, 640, "Viewport width must be exactly 640")

func test_viewport_height_is_360() -> void:
    var height: int = ProjectSettings.get_setting("display/window/size/viewport_height")
    assert_eq(height, 360, "Viewport height must be exactly 360")

func test_stretch_mode_is_viewport() -> void:
    var mode: String = ProjectSettings.get_setting("display/window/stretch/mode")
    assert_eq(mode, "viewport", "Stretch mode must be 'viewport'")

func test_texture_filter_is_nearest() -> void:
    var filter_mode: int = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
    assert_eq(filter_mode, 0, "Default texture filter must be 0 (Nearest)")

# EOF
