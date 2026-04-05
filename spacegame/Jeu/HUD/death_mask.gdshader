shader_type canvas_item;

uniform vec2 hole_center_uv = vec2(0.5, 0.5);
uniform float hole_radius_uv = 0.6;
uniform float edge_softness_uv = 0.05;
uniform float overlay_alpha : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float dist = distance(UV, hole_center_uv);
	float hole_fade = smoothstep(hole_radius_uv, hole_radius_uv + edge_softness_uv, dist);
	COLOR = vec4(0.0, 0.0, 0.0, hole_fade * overlay_alpha);
}
