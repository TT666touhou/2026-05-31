shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform sampler2D vision_mask : hint_default_black, filter_linear;

// 調整參數
uniform float darkness_outside   : hint_range(0.0, 1.0) = 0.20;  // 視野外亮度倍率 (非 0)
uniform float saturation_outside : hint_range(0.0, 1.0) = 0.05;  // 視野外飽和度
uniform float edge_softness      : hint_range(0.0, 0.5) = 0.15;  // 邊緣柔化程度
uniform vec4  outside_tint : source_color = vec4(0.1, 0.12, 0.18, 0.0); // 視野外冷藍偏移

// 統一雜訊參數 (Film Grain)
uniform float noise_amount       : hint_range(0.0, 1.0) = 0.08;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.8;

// 隨機數生成 (基於 UV 和時間)
float rand(vec2 co, float time) {
    return fract(sin(dot(co.xy + time, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	
	// 從視野遮罩取得此像素的可見度（0 = 陰影/視野外，1 = 完全可見）
	float vision = texture(vision_mask, SCREEN_UV).r;
	
	// 邊緣柔化
	vision = smoothstep(0.0, edge_softness, vision);
	
	// 灰階化（計算亮度）
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	
	// 脫飽和混合（vision = 1 時完全彩色，vision = 0 時幾乎灰階）
	vec3 desaturated = mix(vec3(luminance), color.rgb, saturation_outside + vision * (1.0 - saturation_outside));
	
	// 視野外冷藍偏移
	desaturated = mix(desaturated + outside_tint.rgb * (1.0 - vision) * luminance, desaturated, vision);
	
	// 暗化（視野外亮度降低）
	desaturated *= mix(darkness_outside, 1.0, vision);
	
	// ── 統一雜訊 (Film Grain) ──
	float noise = rand(SCREEN_UV, TIME) - 0.5; // -0.5 到 0.5
	desaturated += noise * noise_amount * (0.5 + luminance * 0.5); // 亮處雜訊稍強
	
	// ── 暗角 (Vignette) ──
	vec2 center_uv = SCREEN_UV - 0.5;
	float dist = length(center_uv);
	float vignette = smoothstep(0.7, 0.2, dist * vignette_intensity);
	desaturated *= vignette;
	
	COLOR = vec4(desaturated, color.a);
}
