shader_type canvas_item;

uniform float frequency = 32.0;
uniform float speed = 1.0;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 32.0 + TIME) * 0.001;
	uv.x = clamp(uv.x, 0.0, 1.0);
	COLOR = vec4(1, 1, 1, 1);
	vec3 c = textureLod(screen_texture, uv, 0.0).rgb;

	COLOR.rgb = c;
}
