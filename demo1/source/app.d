/**
	Authors: Fr3nchK1ss on github
	Copyright: proprietary / contact dev

	Minimal Dterrent test application
 */

module demo1;

import dterrent;

bool dragging;
bool running = true;

void main()
{
	// Init and create window
	dterrent.system.init();
    auto window = Window.getInstance();

    window.onExit = delegate void() {
		info("Window close, exiting...");
		running = false;
	};

    // destroy window and stop system
	dterrent.system.stop();
}
