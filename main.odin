package main

import "core:fmt"
import "core:io"
import gl "vendor:OpenGL"
import SDL "vendor:sdl2"

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

vertex := []f32{0.75, 0.75, 0.0, 1.0, 0.75, -0.75, 0.0, 1.0, -0.75, -0.75, 0.0, 1.0}
vert := string(#load("vert.glsl"))
frag := string(#load("frag.glsl"))

main :: proc() {
	WINDOW_WIDTH :: 854
	WINDOW_HEIGHT :: 480

	SDL.Init({.VIDEO})
	defer SDL.Quit()

	window := SDL.CreateWindow(
		"SDL2",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		{.OPENGL},
	)
	assert(window != nil, SDL.GetErrorString())
	defer SDL.DestroyWindow(window)

	SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

	gl_context := SDL.GL_CreateContext(window)
	defer SDL.GL_DeleteContext(gl_context)

	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)

	program, program_ok := gl.load_shaders_source(vert, frag)
	if !program_ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}

	pbo: u32
	gl.GenBuffers(1, &pbo)
	defer gl.DeleteBuffers(1, &pbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, pbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertex) * size_of(f32), raw_data(vertex), gl.STATIC_DRAW)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	vao: u32
	gl.GenVertexArrays(1, &vao)
	defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	gl.UseProgram(program)
	defer gl.DeleteProgram(program)

	gl.BindBuffer(gl.ARRAY_BUFFER, pbo)
	gl.EnableVertexAttribArray(0)
	defer gl.DisableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 0, 0)

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
			}
		}

		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.ClearColor(0, 0, 0, 0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		SDL.GL_SwapWindow(window)
	}
}
