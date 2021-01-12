/**
	Authors: ludo456 on github
	Copyright: proprietary / contact dev

	This class is a rewrite of yage3D System class.
 */

module dterrent.system.system;
import dterrent.system.logger;

import core.thread.osthread;
import libloader = dterrent.system.libloader;
import dterrent.system.sound.openal;

/+
import std.range;

import tango.stdc.stringz;
import tango.core.Memory;

import derelict.opengl3.gl;
import derelict.opengl3.ext;
import derelict.util.exception;

import yage.core.all;
import yage.gui.surface;

import yage.system.sound.soundsystem;
import yage.system.graphics.all;
import yage.core.object2;
import yage.core.math.vector;
import yage.scene.scene;
import yage.resource.manager;
import yage.system.window;
+/


Thread system_thread; 		// reference to thread that called init, typically the main thread

/* Load external libs */
void init()
{
    import std.datetime.stopwatch : StopWatch, AutoStart;
	auto stopWatch = StopWatch(AutoStart.yes);

	// Init variables
	sharedLog = new DtrtLogger(); // is a global
	system_thread = Thread.getThis();

	// Load external libraries
	libloader.loadAll();

    if (libloader.isOpenALLoaded())
    {
        //uint* buffers; TEST OK
        //OpenAL.genBuffers(10, buffers); TEST OK
        // Create OpenAL device, context, and start sound processing thread.
        //SoundContext.init();
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
	assert(system_thread && Thread.getThis() == system_thread);

    /*
	// TODO FIX THIS
	//SDL_WM_GrabInput(SDL_GRAB_OFF);
	SDL_ShowCursor(true);

	SoundContext.deInit(); // stop the sound thread

	foreach ( s; retro (Scene.getAllScenes().values) )
		s.dispose();

	Render.cleanup(0); // textures, vbo's, and other OpenGL resources

	ResourceManager.dispose();

	if (Window.getInstance())
		Window.getInstance().dispose();

	// TODO: This shouldn't be needed to force any calls to dispose.
	//GC.collect(); // Crashes when called in debug mode

    */

    libloader.unloadAll();

}


struct Credit
{	string name;
	string handle;
	string code;
	string license;
	static Credit opCall(string name, string handle, string code, string license)
	{	Credit result;
		result.name=name;
		result.handle=handle;
		result.code=code;
		result.license=license;
		return result;
	}
}

Credit[] getCredits()
{
	return [
	    Credit("Eric Poggel", "JoeCoder", "Original Yage engine", "LGPL v3")
	];
}
