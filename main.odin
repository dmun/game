package main

import SDL "vendor:sdl2"

main :: proc()
{
	sdl_init_error := SDL.Init(SDL.INIT_VIDEO)
	assert(sdl_init_error == 0, SDL.GetErrorString())
	defer SDL.Quit()

	window := SDL.CreateWindow(
		"SDL2 Examples",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		1024,
		960,
		SDL.WINDOW_RESIZABLE
	)
	assert(window != nil, SDL.GetErrorString())
	defer SDL.DestroyWindow(window)

	SDL.Delay(3000)
}
