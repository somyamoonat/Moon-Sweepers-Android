shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform sampler2D dust_mask : filter_linear, repeat_disable;
uniform vec4 clean_color : source_color = vec4(0.12, 0.13, 0.17, 1.0);
uniform vec4 dust_color : source_color = vec4(0.48, 0.44, 0.38, 1.0);

void fragment() {
	float dust_factor = texture(dust_mask, UV).r;
	ALBEDO = mix(clean_color.rgb, dust_color.rgb, dust_factor);
	ROUGHNESS = mix(0.45, 0.95, dust_factor);
	SPECULAR = mix(0.4, 0.1, dust_factor);
}
