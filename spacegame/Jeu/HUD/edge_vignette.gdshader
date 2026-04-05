shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.0, 1.0) = 0.55;
uniform vec4 tint : source_color = vec4(1.0, 0.08, 0.08, 1.0);

void fragment() {
	vec2 centered = SCREEN_UV - vec2(0.5);
	float dist = length(centered) * 1.4142136;
	float edge = smoothstep(softness, 1.0, dist);
	COLOR = vec4(tint.rgb, edge * intensity);
}
