// vision_mask.gdshader
// Darkwood 風格視野遮罩 Shader
// 效果：視野內正常顯示；視野外脫飽和 + 暗化（不是純黑！）
// 生物在視野外的不可見性由 GDScript 控制（visible = false）

shader_type canvas_item;

// 由 VisionSystem.gd 每幀更新的視野遮罩貼圖（紅通道 = 亮度）
uniform sampler2D vision_mask : hint_default_black, filter_linear;

// 調整參數
uniform float darkness_outside   : hint_range(0.0, 1.0) = 0.22;  // 視野外亮度倍率
uniform float saturation_outside : hint_range(0.0, 1.0) = 0.08;  // 視野外飽和度
uniform float edge_softness      : hint_range(0.0, 0.5) = 0.12;  // 邊緣柔化程度
uniform vec4  outside_tint : source_color = vec4(0.08, 0.09, 0.12, 0.0); // 視野外冷藍偏移

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	// 從視野遮罩取得此像素的可見度（0 = 不可見，1 = 完全可見）
	float vision = texture(vision_mask, SCREEN_UV).r;
	
	// 邊緣柔化（避免硬邊）
	vision = smoothstep(edge_softness, edge_softness + 0.1, vision);
	
	// 灰階化（計算亮度）
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	
	// 脫飽和混合（vision = 1 時完全彩色，vision = 0 時幾乎灰階）
	vec3 desaturated = mix(vec3(luminance), color.rgb, saturation_outside + vision * (1.0 - saturation_outside));
	
	// 暗化（視野外亮度降低）
	desaturated *= mix(darkness_outside, 1.0, vision);
	
	// 冷藍偏移（視野外輕微藍綠色調）
	desaturated = mix(desaturated + outside_tint.rgb * (1.0 - vision), desaturated, vision);
	
	COLOR = vec4(desaturated, color.a);
}
