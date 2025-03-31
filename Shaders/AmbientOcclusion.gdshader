shader_type canvas_item;

uniform sampler2D screen_texture;
uniform float blur_amount = 2.0;

// Gaussian blur kernel (simplified)
float gaussian(float x, float sigma) {
    return exp(-x * x / (2.0 * sigma * sigma)) / (sqrt(2.0 * PI) * sigma);
}

void fragment() {
    vec4 tex_color = texture(screen_texture, UV);
    float alpha = tex_color.a;

    // Apply Gaussian blur to alpha (simplified)
    float blur = 0.0;
    for (int i = -int(blur_amount); i <= int(blur_amount); i++) {
        float offset = float(i) / blur_amount;
        float weight = gaussian(offset, 1.0);
        blur += texture(screen_texture, UV + vec2(offset, 0.0)).a * weight;
        blur += texture(screen_texture, UV + vec2(0.0, offset)).a * weight;
    }
    blur /= (2.0 * blur_amount + 1.0) * 2.0;

    // Create the outline color
    vec4 outline_color = vec4(0.0, 0.0, 0.0, (1.0 - blur) * 0.5); // Adjust darkness

    // Composite the outline and original texture
    COLOR = mix(tex_color, outline_color, outline_color.a);
}