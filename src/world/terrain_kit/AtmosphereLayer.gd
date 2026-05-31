@tool
extends CanvasLayer
class_name AtmosphereLayer

## Darkwood-style atmosphere layer.
## Renders a fullscreen vignette (black radial gradient from edges inward)
## and a subtle color overlay to deepen the horror mood.

@export var vignette_strength: float = 0.75
@export var vignette_radius: float = 0.55
@export var tint_color: Color = Color(0.04, 0.05, 0.03, 0.18)

var _canvas: ColorRect

func _ready() -> void:
	layer = 100  # Above everything except UI
	# Build a full-screen ColorRect with a shader for vignette
	_canvas = ColorRect.new()
	_canvas.anchor_left = 0.0
	_canvas.anchor_top = 0.0
	_canvas.anchor_right = 1.0
	_canvas.anchor_bottom = 1.0
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.color = Color(0, 0, 0, 0)  # transparent, shader handles alpha
	
	var mat = ShaderMaterial.new()
	mat.shader = _build_vignette_shader()
	mat.set_shader_parameter("vignette_strength", vignette_strength)
	mat.set_shader_parameter("vignette_radius", vignette_radius)
	mat.set_shader_parameter("tint_color", tint_color)
	_canvas.material = mat
	
	add_child(_canvas)

func _build_vignette_shader() -> Shader:
	var s := Shader.new()
	s.code = """
shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.75;
uniform float vignette_radius : hint_range(0.1, 1.0) = 0.55;
uniform vec4 tint_color : source_color = vec4(0.04, 0.05, 0.03, 0.18);

void fragment() {
	vec2 uv = UV;
	vec2 centered = uv - vec2(0.5);
	float dist = length(centered);
	float vignette = smoothstep(vignette_radius, vignette_radius - 0.15, dist);
	float darkness = (1.0 - vignette) * vignette_strength;
	
	// Tint overlay first
	COLOR = tint_color;
	// Then add vignette darkening on top
	COLOR.a = max(COLOR.a, darkness * 0.9);
}
"""
	return s
