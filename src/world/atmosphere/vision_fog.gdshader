shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec4 col = texture(screen_texture, SCREEN_UV);
    float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    
    // Smooth transition from dark (unlit) to bright (lit by flashlight)
    // CanvasModulate is ~0.4, so unlit luma is ~0.2 to 0.4
    // Flashlight adds 0.8, so lit luma is > 0.8
    float factor = smoothstep(0.3, 0.65, luma);
    
    // The unlit fog color: desaturated and tinted slightly blue-gray
    vec3 fog_color = vec3(luma) * vec3(0.8, 0.85, 0.9);
    
    // Mix them
    COLOR.rgb = mix(fog_color, col.rgb, factor);
    COLOR.a = col.a;
}
