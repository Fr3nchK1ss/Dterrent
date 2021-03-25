/**
	Authors: Fr3nchK1ss on github
	Copyright: proprietary / contact dev

	This class is a rewrite of yage3D System class.
 */

module dterrent.system.system;
import dterrent.system.logger;

import std.concurrency;
import libloader = dterrent.system.libloader;
import dterrent.system.sound;
import dterrent.system.window;

/+
import tango.core.Memory;

import derelict.opengl3.gl;
import derelict.opengl3.ext;
import derelict.util.exception;

import yage.gui.surface;
import yage.system.graphics.all;
import yage.scene.scene;
import yage.resource.manager;
+/

Tid system_thread; // reference to thread that called init, typically the main thread
bool isSoundON = true;

/* Load external libs */
void init()
{
	import std.datetime.stopwatch : StopWatch, AutoStart;

	auto stopWatch = StopWatch(AutoStart.yes);

	// Init variables
	sharedLog = new DtrtLogger(); // is a global
	system_thread = thisTid();

	// Load external libraries
	libloader.loadAll();

	if (libloader.isOpenALLoaded())
	{
		try
		{
			// Create OpenAL device, context, and start sound processing thread.
			SoundContext.init();
		}
		catch (OpenALException e)
		{
			isSoundON = false;
		}
	}

	stopWatch.stop();
	infof("Dterrent initialized in %s msecs", stopWatch.peek.total!"msecs");

}

/**
 * Perform a clean stop of the engine
 */
void stop()
{
	/**
     * The assert is useful to ensure that rendering functions aren't called from
     * other threads. Always returns false if called before System.init()
     */
	assert(thisTid() == system_thread);

	SoundContext.deInit(); // stop the sound thread
	/+
	// TODO FIX THIS
	//SDL_WM_GrabInput(SDL_GRAB_OFF);
	SDL_ShowCursor(true);

	foreach ( s; retro (Scene.getAllScenes().values) )
		s.dispose();

	Render.cleanup(0); // textures, vbo's, and other OpenGL resources

	ResourceManager.dispose();
    +/

	if (Window.getInstance())
		Window.getInstance().destroy();

	libloader.unloadAll();

}

struct Credit
{
	string name;
	string handle;
	string code;
	string license;
	static Credit opCall(string name, string handle, string code, string license)
	{
		Credit result;
		result.name = name;
		result.handle = handle;
		result.code = code;
		result.license = license;
		return result;
	}
}

Credit[] getCredits()
{
	return [
		Credit("Eric Poggel", "JoeCoder", "Original Yage engine", "LGPL v3"),
		Credit("Fr3nchK1ss", "Fr3nchK1ss", "Dterrent engine", "LGLP v3"),
	];
}
