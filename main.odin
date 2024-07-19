package main

import "core:fmt"
import "core:io"
import "core:math"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import SDL "vendor:sdl2"
import IMG "vendor:sdl2/image"

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

// odinfmt: disable
_vertices := [?]f32{
	0.75,   0.75, 0.0,  1, 0, 0,  1, 1,
	0.75,  -0.75, 0.0,  0, 1, 0,  1, 0,
	-0.75, -0.75, 0.0,  0, 0, 1,  0, 0,
	-0.75,  0.75, 0.0,  1, 1, 0,  0, 1,
}

vertices := [?]f32{
    -0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,

    -0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0, 1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0
};
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

	vert := string(#load("shader.vert.glsl"))
	frag := string(#load("shader.frag.glsl"))

	program, program_ok := gl.load_shaders_source(vert, frag)
	if !program_ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}

	vao: u32
	gl.GenVertexArrays(1, &vao)
	defer gl.DeleteVertexArrays(1, &vao)

	vbo: u32
	gl.GenBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &vbo)

	ebo: u32
	gl.GenBuffers(1, &ebo)
	defer gl.DeleteBuffers(1, &ebo)

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	indices := [?]u32{0, 1, 3, 1, 2, 3}

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	defer gl.DisableVertexAttribArray(0)

	// gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
	// gl.EnableVertexAttribArray(1)
	// defer gl.DisableVertexAttribArray(1)

	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(2)
	defer gl.DisableVertexAttribArray(2)

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

	surface := SDL.ConvertSurfaceFormat(IMG.Load("swgcat.jpg"), u32(SDL.PixelFormatEnum.RGB24), 0)

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

	gl.UseProgram(program)
	gl.Uniform1i(gl.GetUniformLocation(program, "ourTexture"), 0)

	gl.ClearColor(0.1, 0.1, 0.1, 1)
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	cube_positions := []glm.vec3 {
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

	yaw: f32
	pitch: f32

	SDL.ShowCursor(0)

	loop: for {
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
			}
		}
		SDL.WarpMouseInWindow(window, WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2)

		gl.UseProgram(program)
		defer gl.DeleteProgram(program)
		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		view := glm.mat4(1)
		view *= glm.mat4Rotate({1, 0, 0}, glm.radians(pitch))
		view *= glm.mat4Rotate({0, 1, 0}, glm.radians(yaw))
		view *= glm.mat4Translate({0, 0, 2})
		gl.UniformMatrix4fv(gl.GetUniformLocation(program, "view"), 1, gl.FALSE, &view[0, 0])

		proj := glm.mat4Perspective(glm.radians(f32(90)), f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT), 0.1, 100)
		gl.UniformMatrix4fv(gl.GetUniformLocation(program, "projection"), 1, gl.FALSE, &proj[0, 0])

		for &pos, i in &cube_positions {
			model := glm.mat4Translate(pos)
			angle := f32(SDL.GetTicks()) / 20.0 * f32(i)
			model *= glm.mat4Rotate({1, 0.3, 0.5}, glm.radians(angle) / 5)
			gl.UniformMatrix4fv(gl.GetUniformLocation(program, "model"), 1, gl.FALSE, &model[0, 0])
			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

		// gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

		SDL.GL_SwapWindow(window)
	}

	if gl.GetError() != gl.NO_ERROR {
		fmt.eprintln("error: ", gl.get_last_error_message())
	}
}
