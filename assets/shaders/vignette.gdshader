shader_type canvas_item;

// Edge vignette for danger feedback. `intensity` is tweened by JuiceOverlay; at 0 the
// rect is fully transparent. Simple radial falloff -> works under gl_compatibility.

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.2, 0.2, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.41421356;        // 0 at center -> ~1 at corners
	float v = smoothstep(0.4, 0.95, d);        // ring concentrated near edges
	COLOR = vec4(edge_color.rgb, v * intensity);
}
