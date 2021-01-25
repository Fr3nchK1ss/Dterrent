/**
	Authors: Fr3nchK1ss on github
	Copyright: proprietary / contact dev

	Minimal Dterrent test application
 */

module demo1;

import std.conv;
import dterrent;
import bindbc.sdl;


void main()
{
    bool dragging;
    bool running = true;

	// Init and create window
	dterrent.system.init();
    auto window = Window.getInstance();

    //auto scene = new TerrainDemo();

    /********** FPS count **********/
    enum FPS = 90; // Target FPS
    immutable perfFrequency = SDL_GetPerformanceFrequency();
    // (counter ticks / seconds) / (frames / second) = counter ticks / frame
    immutable counterTicksAvailablePerFrame = perfFrequency / FPS;
    //trace ("perfFrequency " ~ to!string(perfFrequency));
    //trace ("counterTicksAvailablePerFrame " ~ to!string(counterTicksAvailablePerFrame));

    /**
     * Update Gui every second
     */
    void updateGUI(float drawDelay)
    {
        import std.math: floor;
        static int updateCountDown = 0;

        if (updateCountDown == 0)
        {
            Window.getInstance().setCaption("Dt3rr3nt"
                ~ "   -   current FPS = "
                ~ to!string(FPS)
                ~ "   -   max FPS = "
                ~ to!string(floor(cast(float)(counterTicksAvailablePerFrame) / drawDelay * FPS)));
            updateCountDown = FPS;

        } else {
            updateCountDown--;
        }
    }

    mainLoop: while (running) {
        immutable frameStart = SDL_GetPerformanceCounter();

        for (SDL_Event e;  SDL_PollEvent(&e); ) {
            switch (e.type)
            {
                case SDL_QUIT:
                    critical ("QUIT signal");
                    running = false;
                    break mainLoop;
                default:
                    break;
            }
        }

        //draw();

        immutable drawDelay = SDL_GetPerformanceCounter() - frameStart;
        //trace ("drawDelay " ~ to!string(drawDelay));
        if( drawDelay > counterTicksAvailablePerFrame ) {
            // Not enough time to draw!
            SDL_Delay(0);
        } else {
            // Do not draw too fast
            SDL_Delay (cast(uint)
                ( (counterTicksAvailablePerFrame - drawDelay) * 1000/perfFrequency));
        }

        updateGUI ( drawDelay );

    }

    // destroy window and stop system
	dterrent.system.stop();
}
