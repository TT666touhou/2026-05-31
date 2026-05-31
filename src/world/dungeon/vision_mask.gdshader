// vision_mask.gdshader
// Darkwood 風格視野後處理 Shader
// 效果：動態檢測螢幕亮度，在暗處自動進行「脫飽和」與「冷色調偏移」；全域疊加膠片噪點與暗角。
// 不需要複雜的 SubViewport，效能極高且相容性完美。

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

// 調整參數
uniform float darkness_outside   : hint_range(0.0, 1.0) = 0.65;  // 視野外亮度倍率（配合 CanvasModulate）
uniform float saturation_outside : hint_range(0.0, 1.0) = 0.05;  // 視野外飽和度
uniform float brightness_dark = 0.11;                          // 判定為黑暗的亮度閾值
uniform float brightness_lit = 0.28;                           // 判定為亮區的亮度閾值
uniform vec4  outside_tint : source_color = vec4(0.04, 0.06, 0.10, 0.0); // 視野外冷藍偏移
uniform float grain_strength     : hint_range(0.0, 0.3) = 0.06;  // 膠片噪點強度

// 偽隨機噪音噪音生成器
float random_noise(vec2 uv, float time) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233) + time * 0.01)) * 43758.5453);
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	
	// ── 依亮度動態計算視野強度 (Vision Intensity) ──
	// 擷取原始像素的最大通道亮度
	float max_rgb = max(color.r, max(color.g, color.b));
	
	// 當亮度在 [brightness_dark, brightness_lit] 之間時平滑過渡
	float vision = smoothstep(brightness_dark, brightness_lit, max_rgb);
	
	// 灰階化（計算亮度）
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	
	// 脫飽和混合（光照外幾乎無彩色，光照內保留色彩）
	vec3 processed = mix(vec3(luminance), color.rgb, saturation_outside + vision * (1.0 - saturation_outside));
	
	// 微調光照外的亮度
	processed = mix(processed * darkness_outside, processed, vision);
	
	// 冷藍偏移（視野外輕微藍色調）
	processed = mix(processed + outside_tint.rgb * (1.0 - vision), processed, vision);
	
	// ── 膠片噪點 (Film Grain) ──
	float noise_val = random_noise(SCREEN_UV, TIME);
	processed += vec3((noise_val - 0.5) * grain_strength);
	
	// ── 螢幕暗角 (Vignette) ──
	vec2 uv_dist = SCREEN_UV - vec2(0.5);
	float vignette = smoothstep(0.85, 0.35, length(uv_dist));
	processed *= mix(0.40, 1.0, vignette);
	
	COLOR = vec4(processed, color.a);
}
