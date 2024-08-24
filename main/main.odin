package main

import "core:fmt"
import "core:io"
import "core:math"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import SDL "vendor:sdl2"
import IMG "vendor:sdl2/image"

vec3 :: glm.vec3
mat4 :: glm.mat4
cos :: math.cos
sin :: math.sin
radians :: glm.radians_f32

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

// odinfmt: disable
vertices := [?]f32{
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
     0.5, -0.5, -0.5,  0.0,  0.0, -1.0, 
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 
    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0, 

    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0,  0.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
    -0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,

    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,
    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,
    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,

     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
     0.5,  0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5,  0.5,  1.0,  0.0,  0.0,
     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,

    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,

    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0
}

cube_positions := []vec3 {
	{0.0, 0.0, 0.0},
	{2.0, 5.0, -15.0},
	{-1.5, -2.2, -2.5},
	{-3.8, -2.0, -12.3},
	{2.4, -0.4, -3.5},
	{-1.7, 3.0, -7.5},
	{1.3, -2.0, -2.5},
	{1.5, 2.0, -2.5},
	{1.5, 0.2, -1.5},
	{-1.3, 1.0, -1.5},
}
// odinfmt: enable

main :: proc() {
	WINDOW_WIDTH :: 1280
	WINDOW_HEIGHT :: 720

	SDL.Init({.VIDEO})
	defer SDL.Quit()

	window := SDL.CreateWindow(
		"SDL2",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		SDL.WINDOW_OPENGL | SDL.WINDOW_RESIZABLE,
	)
	assert(window != nil, SDL.GetErrorString())
	defer SDL.DestroyWindow(window)

	SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

	gl_context := SDL.GL_CreateContext(window)
	defer SDL.GL_DeleteContext(gl_context)

	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)

	vert := string(#load("../shader/shader.vert.glsl"))
	frag := string(#load("../shader/shader.frag.glsl"))
	lighting_vert := string(#load("../shader/light.vert.glsl"))
	lighting_frag := string(#load("../shader/light.frag.glsl"))

	mat_shader, program_ok := gl.load_shaders_source(vert, frag)
	if !program_ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}
	lighting_shader, ok := gl.load_shaders_source(lighting_vert, lighting_frag)
	if !ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}

	vao: u32
	gl.GenVertexArrays(1, &vao)
	defer gl.DeleteVertexArrays(1, &vao)

	light_vao: u32
	gl.GenVertexArrays(1, &light_vao)
	defer gl.DeleteVertexArrays(1, &light_vao)

	vbo: u32
	gl.GenBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &vbo)

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	indices := [?]u32{0, 1, 3, 1, 2, 3}

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	defer gl.DisableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)
	defer gl.DisableVertexAttribArray(1)

	light_pos := vec3{1.2, 1, 2}

	gl.BindVertexArray(light_vao)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	defer gl.DisableVertexAttribArray(0)

	gl.Enable(gl.DEPTH_TEST)

	IMG.Init({.JPG, .PNG})
	defer IMG.Quit()

	texture: u32
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	surface := SDL.ConvertSurfaceFormat(
		IMG.Load("image/swgcat.jpg"),
		u32(SDL.PixelFormatEnum.RGB24),
		0,
	)

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.RGB,
		surface.w,
		surface.h,
		0,
		gl.RGB,
		gl.UNSIGNED_BYTE,
		surface.pixels,
	)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture)

	gl.UseProgram(mat_shader)
	gl.Uniform1i(gl.GetUniformLocation(mat_shader, "ourTexture"), 0)

	gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
	gl.ClearColor(0.1, 0.1, 0.1, 1)
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	camera: Camera
	yaw: f32 = 90
	pitch: f32

	SDL.ShowCursor(0)
	SDL.SetRelativeMouseMode(true)

	last_tick := u32(0)
	MAX_FPS :: 250

	loop: for {
		ticks := SDL.GetTicks()
		t := f32(ticks) / 1000
		dt := f32(ticks - last_tick) / 1000

		fps := 1000 / f32(ticks - last_tick)
		if fps > MAX_FPS {continue}
		last_tick = ticks

		state := SDL.GetKeyboardState(nil)
		camera_move(&camera, state, dt)

		event: SDL.Event
		for SDL.PollEvent(&event) {
			#partial switch event.type {
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					break loop
				}
			case .QUIT:
				break loop
			case .MOUSEMOTION:
				yaw += f32(event.motion.xrel) * 0.1
				pitch += f32(event.motion.yrel) * 0.1
				pitch = math.clamp(pitch, -89, 89)
				camera_rotate(&camera, pitch, yaw)
			}
		}

		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		light_pos.x = 2 * sin(f32(ticks) / 400)
		light_pos.y = 2 * sin(f32(ticks) / 500)
		light_pos.z = 2 * cos(f32(ticks) / 400)

		// Lighting
		gl.UseProgram(lighting_shader)

		model := glm.mat4Translate(light_pos)
		model *= glm.mat4Scale(0.2)

		view := camera_get_matrix(&camera)
		aspect_ratio := f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)
		proj := glm.mat4Perspective(radians(90), aspect_ratio, 0.1, 100)

		program_set_vec3(lighting_shader, "objectColor", 1, 0.5, 0.31)
		program_set_vec3(lighting_shader, "lightColor", 1, 1, 1)
		program_set_vec3(lighting_shader, "lightPos", light_pos)

		program_set_mat4(lighting_shader, "view", &view[0, 0])
		program_set_mat4(lighting_shader, "projection", &proj[0, 0])
		program_set_mat4(lighting_shader, "model", &model[0, 0])

		gl.BindVertexArray(light_vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 36)

		// Cubes
		gl.UseProgram(mat_shader)

		program_set_vec3(mat_shader, "objectColor", 1, 0.5, 0.31)
		program_set_vec3(mat_shader, "lightColor", 1, 1, 1)
		program_set_vec3(mat_shader, "lightPos", light_pos)
		program_set_vec3(mat_shader, "viewPos", camera.position)

		program_set_vec3(mat_shader, "material.ambient", 1.0, 0.5, 0.31)
		program_set_vec3(mat_shader, "material.diffuse", 1.0, 0.5, 0.31)
		program_set_vec3(mat_shader, "material.specular", 0.5, 0.5, 0.5)
		program_set_float(mat_shader, "material.shininess", 32.0)

		program_set_vec3(mat_shader, "light.ambient",  0.2, 0.2, 0.2)
		program_set_vec3(mat_shader, "light.diffuse",  0.5, 0.5, 0.5)
		program_set_vec3(mat_shader, "light.specular", 1.0, 1.0, 1.0)

		program_set_mat4(mat_shader, "view", &view[0, 0])
		program_set_mat4(mat_shader, "projection", &proj[0, 0])

		gl.BindVertexArray(vao)
		for &pos, i in &cube_positions {
			angle := f32(ticks) / 20.0 * f32(i)
			model := glm.mat4Translate(pos)
			model *= glm.mat4Rotate({1, 0.3, 0.5}, radians(angle) / 5)

			program_set_mat4(mat_shader, "model", &model[0, 0])

			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

		SDL.GL_SwapWindow(window)
	}

	if gl.GetError() == gl.DEBUG_TYPE_ERROR {
		fmt.eprintln("error: ", gl.get_last_error_message())
	}
}

program_set_vec3_i3 :: proc(program: u32, location: cstring, v1, v2, v3: f32) {
	gl.Uniform3f(gl.GetUniformLocation(program, location), v1, v2, v3)
}

program_set_vec3_vec3 :: proc(program: u32, location: cstring, v: vec3) {
	gl.Uniform3f(gl.GetUniformLocation(program, location), v.x, v.y, v.z)
}

program_set_vec3 :: proc{program_set_vec3_i3, program_set_vec3_vec3}

program_set_mat4 :: proc(program: u32, location: cstring, value: [^]f32) {
	gl.UniformMatrix4fv(gl.GetUniformLocation(program, location), 1, gl.FALSE, value)
}

program_set_float :: proc(program: u32, location: cstring, value: f32) {
	gl.Uniform1f(gl.GetUniformLocation(program, location), value)
}
