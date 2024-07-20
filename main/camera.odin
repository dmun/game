package main

import glm "core:math/linalg/glsl"
import SDL "vendor:sdl2"

Camera :: struct {
	position:  vec3,
	direction: vec3,
	right:     vec3,
}

camera_rotate :: proc(using camera: ^Camera, pitch, yaw: f32) {
	direction.x = -cos(radians(yaw)) * cos(radians(pitch))
	direction.y = -sin(radians(pitch))
	direction.z = -sin(radians(yaw)) * cos(radians(pitch))
	right = glm.normalize(glm.cross(vec3{0, 1, 0}, direction))
}

camera_get_matrix :: proc(using camera: ^Camera) -> mat4 {
	return glm.mat4LookAt(position, position + direction, glm.cross(direction, right))
}

camera_move :: proc(using camera: ^Camera, state: [^]u8, dt: f32) {
	speed := f32(5)
	if state[SDL.Scancode.W] == 1 {
		position += glm.normalize_vec3({direction.x, 0, direction.z}) * speed * dt
	}
	if state[SDL.Scancode.S] == 1 {
		position -= glm.normalize_vec3({direction.x, 0, direction.z}) * speed * dt
	}
	if state[SDL.Scancode.A] == 1 {
		position += right * speed * dt
	}
	if state[SDL.Scancode.D] == 1 {
		position -= right * speed * dt
	}
}
