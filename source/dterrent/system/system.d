/**
	Authors: ludo456 on github
	Copyright: proprietary / contact dev

	Minimal Dterrent test application. This class is a
	rewrite of yage3D System class.
 */

module dterrent.system.system;


import core.thread.osthread;
import bindbc.sdl;
import bindbc.sdl.image;
import bindbc.openal;

import dterrent.system.logger;
import std.experimental.logger; //to use global sharedLog

/+
import std.range;

import tango.stdc.stringz;
import tango.core.Memory;

import derelict.openal.al;
import derelict.opengl3.gl;
import derelict.opengl3.ext;
import derelict.util.exception;

import derelict.freetype.ft;
import yage.core.all;
import yage.gui.surface;

import yage.system.sound.soundsystem;
import yage.system.graphics.all;
import yage.core.object2;
import yage.core.math.vector;
import yage.scene.scene;
import yage.resource.manager;
import yage.system.window;
import yage.system.libraries;
+/

/**
 * The System class exists to initilize/deinitialize the engine.
 */
abstract class System
{
	protected static bool active = false;		// true if between a call to init and deinit, inclusive
	protected static bool initialized=false;	// true if between a call to init and deinit, exclusive
	protected static bool aborted = false; 		// this flag is set when the engine is ready to exit.

	protected static Thread calling_thread; 		// reference to thread that called init, typically the main thread

	/* Mixins declarations */
	mixin template mxtpl_logLoadError(E, string libName) {
		void logLoadError(){
			E magic;
			if( magic == E.badLibrary ) {
				/*Usually this means that either the library or one of its dependencies could not be found.*/
				fatal(libName ~ " not found.");
			}
			else if ( magic == E.noLibrary ) {
				/* e.g., an SDL 2.0.2 library loaded by an SDL 2.0.10 configuration.*/
				fatal ("The system was able to find and successfully load" ~ libName ~
							" but one or more symbols the binding expected to find was missing."
							~" This usually indicates that the loaded library is of a lower API "
							~"version than expected.");
			}
		}

	}


	/* Load external libs */
	static void init()
	{
		// Initialize sharedLog global
		sharedLog = new DtrtLogger();

		// variables
		active = true;
		this.calling_thread = Thread.getThis();

		SDLSupport sdlMagic = loadSDL();
		if(sdlMagic != sdlSupport) {
			mixin mxtpl_logLoadError!(SDLSupport, "SDL"); logLoadError();
		}

		SDLImageSupport sdlImageMagic = loadSDLImage();
		if(sdlImageMagic != sdlImageSupport) {
			mixin mxtpl_logLoadError!(SDLImageSupport, "SDLImage"); logLoadError();
		}

		ALSupport alMagic = loadOpenAL();//using bindbc.openal;
		if( alMagic != ALSupport.al11 ) {
			mixin mxtpl_logLoadError!(ALSupport, "OpenAL"); logLoadError();
		}

		//Libraries.loadVorbis();
		//Libraries.loadFreeType();

		// Create OpenAL device, context, and start sound processing thread.
		//SoundContext.init();

		initialized = true;
		info("Dterrent initialized!");
	}
/+
	/**
	 * Release all Yage Resources.
	 * If System.init() is called, this must be called for cleanup before the program closes.
	 * After calling this function, many Yage functions can no longer be called safely. */
	static void deInit()
	{	assert(isSystemThread());

		initialized = false;

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

		SDL_Quit();
		DerelictSDL2.unload();
		DerelictSDL2Image.unload();
		DerelictAL.unload();
		Libraries.loadVorbis(false);
		Libraries.loadFreeType(false);
		active = false;
		Log.info("Yage has been de-initialized successfully.");
	}

	/**
	 * Returns true if called from the same thread as what System.init() was called.
	 * This is useful to ensure that rendering functions aren't called from other threads.
	 * Always returns false if called before System.init() */
	static bool isSystemThread()
	{	if (self_thread)
			return !!(Thread.getThis() == self_thread);
		return false;
	}
+/

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

	static Credit[] getCredits()
	{//TODO update list to match reality
		return [
		    Credit("Joe Pusderis", "Deformative", "The first versions of yage.gui.surface, initial version of terrain support, .obj model file format loader, linux fixes", "LGPL v3"),
		    Credit("Brandon Lyons", "Etherous", "Ideas and interface for a second version of the Terrain engine", "Boost 1.0"),
		    Credit("Ludovic Angot", "anarky", "Linux fixes", "Boost 1.0"),
		    Credit("William V. Baxter III", "", "yage.resource.dds", "Zlib/LibPng"),
		    Credit("Michael Parker and Others", "Aldacron", "Derelict", "BSD"),
		    Credit("Walter Bright and others", "", "The D Programming Language", ""),
		    Credit("Tango Developers", "", "The Tango Library", "Academic Free License v3.0 or BSD License"),
		    Credit("FreeType Developers", "", "FreeType Project", "FreeType License or GPL"),
		    Credit("Xiph Foundation", "", "Ogg/Vorbis", "BSD"),
		    Credit("Jean-Loup Gailly and Mark Adler", "", "ZLib", "Zlib/LibPng"),
		    Credit("LibPng Developers", "", "LibPng", "Zlib/LibPng"),
		    Credit("Independent JPEG Group", "", "Jpeg", "This software is based in part on the work of the Independent JPEG Group."),
		    Credit("Sam Lantiga and others", "", "SDL", "LGPL"),
		    Credit("Sam Lantinga and Mattias Engdegård", "", "SDL_Image", "LGPL"),
		    Credit("Eric Poggel", "JoeCoder", "everything else", "LGPL v3")
		];
	}

}
