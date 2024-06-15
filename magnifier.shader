/*
    This is a magnifier shader written in Godot Shading Language which is similar to GLSL ES 3.0.

    In order to get this shader working, you must attach this to a node with a texture.
    It might work with nodes without textures too, but isn't tested yet.

    Author is Yavuz Burak Yalçın @orbbloff

    MIT License
*/
shader_type canvas_item;

uniform bool is_object_centered; // Note that this needs to match with the sprite's centered property
uniform float magnification:hint_range(0.0, 400.0) = 2.0;
uniform bool filtering;
uniform bool is_round;
uniform float roundness:hint_range(0.0, 2.0) = 1.0;
uniform float circle_radius:hint_range(0.0, 0.71) = 0.5;
uniform float outline_thickness:hint_range(0.0, 0.1) = 0.01;
uniform vec4 outline_color:source_color = vec4(0.4, 0.0, 0.0, 1.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

varying flat vec2 center_pos;

void vertex() {
    center_pos = is_object_centered ? vec2(0.0) : 0.5 / TEXTURE_PIXEL_SIZE; 
    // From local space texel coordinates to screen space pixel coordinates
    center_pos = (MODEL_MATRIX * vec4(center_pos, 0.0, 1.0)).xy;
}

void fragment() {
    vec2 screen_resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv_distance = vec2(0.5) - UV; // UV distance between fragment and object center in local space
    vec2 pixel_distance = center_pos - FRAGCOORD.xy; // Pixel distance between fragment and object center

    vec2 obj_size = pixel_distance / uv_distance; // Ratio of pixel distance to uv distance gives the objects dimensions
    vec2 ratio = obj_size / screen_resolution;    // This gives the ratio of object to screen

    // Maps the magnification value to range[0.0, 1.0)
    // while magnification is higher than 1.0
    float magnify_value = (magnification - 1.0) / magnification;
    if (is_round) {
		// It slightly reduces the magnification of points that are far to the center
    	magnify_value /= smoothstep(0.0, 1.0, length(UV - vec2(0.5))) * roundness + 1.0;
    }

    // Calculates a local UV position towards the center, proportional to magnification
    vec2 local_mapped_uv = mix(UV, vec2(0.5 /*center*/), magnify_value);
    vec2 difference = local_mapped_uv - UV;
    vec2 global_mapped_uv = SCREEN_UV + difference * ratio; // Calculates a global UV position to from screen texture

    if (filtering) {
        // Applies filter while reading from screen texture
        COLOR = texture(SCREEN_TEXTURE, global_mapped_uv);
    } else {
        // Doesn't apply filter.
        // Since texelFetch function uses screen space pixel coordinates, global_mapped_uv is transformed to pixel coordinates.
        COLOR = texelFetch(SCREEN_TEXTURE, ivec2(int(global_mapped_uv.x * screen_resolution.x), int((global_mapped_uv.y) * screen_resolution.y)), 0);
    }
    // Creates outline
    if (length(UV - vec2(0.5)) > circle_radius - outline_thickness) {
        COLOR = vec4(0.0); // Makes fragments transparent
        if (length(UV - vec2(0.5)) < circle_radius) {
            COLOR = outline_color;
        }
    }
}
