shader_type canvas_item;

uniform vec2 stars_speed = vec2(0.0);
uniform float stars_density: hint_range(0.0, 1.0, 0.001) = 0.01;

varying vec2 position;

// https://thebookofshaders.com/10/
float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Called for every vertex the material is visible on.
void vertex() {
	position = VERTEX;
}
uniform float stars_density: hint_range(0.0, 1.0, 0.001) = 0.01;

// ✱ NEW: twinkle controls ----------------------------------------------------
uniform float twinkle_speed   : hint_range(0.0, 10.0) = 2.0;   // cycles / sec
uniform float twinkle_strength: hint_range(0.0, 1.0)  = 0.5;   // 0 = no flicker
// ---------------------------------------------------------------------------
// ... existing code ...

void fragment() {
	vec2 uv = (position + TIME * stars_speed) * (TEXTURE_PIXEL_SIZE*1.0);

	vec2 cell = floor(uv);                     // integer id – 1 star per cell
	float present = step(random(cell), stars_density);   // 0 or 1

	// stable random phase so each star blinks differently
	float phase   = random(cell + 13.37);
	float twinkle = sin(TIME * twinkle_speed + phase * 6.28318) * 0.5 + 0.5;
	twinkle       = mix(1.0 - twinkle_strength, 1.0, twinkle);

	float brightness = present * twinkle;

	COLOR = vec4(vec3(brightness), 1.0);
}


// Called for every pixel the material is visible on.
void fragment() {
	vec2 uv = (position + TIME * stars_speed) * (TEXTURE_PIXEL_SIZE*1.0);
	uv = fract(uv) * step(random(floor(uv)), stars_density);
	COLOR = texture(TEXTURE, uv);
}