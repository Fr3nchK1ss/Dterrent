/**
    Authors: @Fr3nchK1ss
    Copyright: proprietary / contact dev

    Minimal Dterrent test application
 */

module demo1;

import std.conv;
import dterrent;
import bindbc.sdl;

void main()
{
    bool running = true;
    enum FPS = 90; // Target FPS

    /******* INIT SDL, libs, engine *******/
    dterrent.system.init();
    auto window = Window.getInstance();

    immutable perfFrequency = SDL_GetPerformanceFrequency();
    immutable counterTicksAvailablePerFrame = perfFrequency / FPS; // (ticks/sec)/(F/sec)=tick/F
    //trace ("perfFrequency " ~ to!string(perfFrequency));
    //trace ("counterTicksAvailablePerFrame " ~ to!string(counterTicksAvailablePerFrame));

    /********** Nested funcs **********/

    /**
     * Update Gui every second
     */
    void updateGUI(float drawDelay)
    {
        import std.math : floor;

        static int updateCountDown = 0;

        if (updateCountDown == FPS)
        {
            //trace ("drawDelay " ~ to!string(drawDelay));

            window.setCaption("Dterrent" 
                ~ "   -   target FPS = " 
                ~ to!string(FPS) 
                ~ "   -   possible FPS = " ~ to!string(
                    floor(cast(float)(counterTicksAvailablePerFrame) / drawDelay * FPS)));
            updateCountDown = 0;

        }
        else
            ++updateCountDown;
    }

    /**
     * Introduce a draw delay in the game loop if necessary
     */
    void delayLoop(float drawDelay)
    {
        if (drawDelay > counterTicksAvailablePerFrame)
            SDL_Delay(0); // Draw AFAP
        else
            SDL_Delay(cast(uint)((counterTicksAvailablePerFrame - drawDelay) * 1000 / perfFrequency));
    }

    /******* GAME *******/

    //auto scene = new TerrainDemo();

    mainLoop: while (running)
    {
        immutable frameStart = SDL_GetPerformanceCounter();

        // SDL_Event
        for (SDL_Event e; SDL_PollEvent(&e);)
        {
            switch (e.type)
            {
            case SDL_QUIT:
                critical("QUIT signal");
                running = false;
                break mainLoop;
            default:
                break;
            }
        }

        //draw();

        immutable drawDelay = SDL_GetPerformanceCounter() - frameStart;
        delayLoop(drawDelay);
        updateGUI(drawDelay);
    }

    // destroy window and stop system
    dterrent.system.stop();

}
