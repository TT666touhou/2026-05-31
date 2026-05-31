shader_type canvas_item;
uniform float vignette_intensity = 0.8;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.9;
uniform vec4 vignette_rgb : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV;
	uv -= 0.5;
	float dist = length(uv);
	float vignette = smoothstep(0.3, vignette_intensity, dist);
	COLOR = vec4(vignette_rgb.rgb, vignette * vignette_opacity);
}
