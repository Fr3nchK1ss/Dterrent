/**
	Authors: Fr3nchK1ss on github
	Copyright: proprietary / contact dev

	This class is a rewrite of yage3D Window class.
 */

module dterrent.system.window;
import dterrent.system.logger;

import std.string;
import std.conv;
import bindbc.sdl;
import bindbc.sdl.image;
import bindbc.opengl;
import dterrent.core.interfaces;
import dterrent.core.math;
import libloader = dterrent.system.libloader;

/*
import derelict.util.exception;
import derelict.sdl2.types;
import yage.gui.surface;

import yage.resource.image;
import yage.scene.scene;

import yage.system.graphics.all;
import yage.system.system;
*/

// TODO: remove those var
const int LIGHT_MODEL_COLOR_CONTROL_EXT = 0x81F8;
const int SINGLE_COLOR_EXT = 0x81F9;
const int SEPARATE_SPECULAR_COLOR_EXT	= 0x81FA;

/**
 * Example
 * System.init(); // required
 * auto window = Window.getInstance();
 * window.setResolution(640, 480); // window is created/recreated here
 * --------
 */
class Window : IRenderTarget
{
	void delegate() onExit;

	enum Buffer // ?
	{	COLOR,
		DEPTH,
		STENCIL
	}

	protected static Window instance;

	protected SDL_Window* sdlWindow;
    protected SDL_Surface* sdlSurface;
    protected SDL_GLContext mainGLContext;
    protected ulong winWidth;
    protected ulong winHeight;

	protected vec2i viewportPosition;
	protected vec2i viewportSize;
	protected string title, taskbarName;

	version (linux)
	{
		// Linux needs to remember the fullscreen state when resizing
		protected bool fullscreen = false;
	}


	private this(int width, int height)
	{
		// Initialize SDL video
		if( SDL_Init(SDL_INIT_VIDEO) < 0 )
			throw new Exception ("Unable to initialize SDL: " ~ to!string(SDL_GetError()) );

        setResolution(width, height);

        // Set GL attributes
        // choose: SDL_GL_CONTEXT_PROFILE_CORE  SDL_GL_CONTEXT_PROFILE_COMPATIBILITY
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 6);
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

        // Create SDL window
        uint flags = SDL_WINDOW_RESIZABLE | SDL_WINDOW_OPENGL;
        version (linux)
        {
            if (fullscreen)
                flags |= SDL_WINDOW_FULLSCREEN;
        }

        sdlWindow = SDL_CreateWindow("DT3RR3NT",
                                  cast(int) SDL_WINDOWPOS_UNDEFINED,
                                  cast(int) SDL_WINDOWPOS_UNDEFINED,
                                  cast(int) winWidth,
                                  cast(int) winHeight,
                                  cast(SDL_WindowFlags) flags); // TODO depth, is no longer an option.

        sdlSurface = SDL_GetWindowSurface(sdlWindow);
        mainGLContext = SDL_GL_CreateContext(sdlWindow);

        // OpenGL must be loaded after context creation
        libloader.loadOpenGL();

        if(sdlSurface is null)
            throw new Exception(format("Unable to set %d x %d video mode: %s ", winWidth, winHeight, SDL_GetError()));
        SDL_LockSurface(sdlSurface);

        setViewport();


        int major, minor;
        SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, &major);
        SDL_GL_GetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, &minor);
        infof ("SDL is using OpenGL %d.%d\n", major, minor);

        info ("OpenGL renderer: " ~ to!string(glGetString(GL_RENDERER)));
        info ("OpenGL version: " ~ to!string(glGetString(GL_VERSION)));
        //info ("OpenGL version: " ~ to!string(glGetString(GL_SHADING_LANGUAGE_VERSION​)));
	}


	~this()
	{
        trace("destroy window \n");
        if (instance)
		{	SDL_FreeSurface(sdlSurface); // TODO I probably need a surface anyway for other things...
			SDL_Quit();
			instance = null;
		}
	}

	/// Get the width / height of this Window's display area (not including title/borders) in pixels.
	override ulong getWidth()
	{	return winWidth;
	}
	override ulong getHeight() /// ditto
	{	return winHeight;
	}

	///
	vec2i getViewportPosition()
	{	return viewportPosition;
	}
	///
	vec2i getViewportSize()
	{	return viewportSize;
	}

	static bool hasInstance()
	{	return instance !is null;
	}

	/**
	 * Minimize the Window. */
	void minimize()
	{ SDL_MinimizeWindow(sdlWindow);
	}

	/**
	 * Set the caption for the Window.
	 * Params:
	 *     title = The caption shown on top of the window
     */
	void setCaption(string title)
	{
		SDL_SetWindowTitle(sdlWindow, title.ptr);
	}

	/**
	 * Create (or recreate) the window singleton at this resolution.
	 * Unfortunately this resets the OpenGL context on Windows, which currently causes a crash on subsequent calls.
	 * Params:
	 *     w = width of the window in pixels
	 *     h = height of the window in pixels
	 *     depth = Color depth of each pixel.  Should be 16, 24, 32, or 0 for auto.
	 *     fullscreen = The window is fullscreen if true; windowed otherwise.
	 *     samples = The number of samples to use for anti-aliasing (1 for no aa).
	 */
	void setResolution(ulong w, ulong h, ubyte depth=0, bool fullscreen_=false, ubyte samples=1)
	{
		assert(depth==0 || depth==16 || depth==24 || depth==32); // 0 for current screen depth
		assert(w>0 && h>0);

		version (linux)
		{
			fullscreen = fullscreen_;
		}
		// Anti-aliasing

		if (samples > 1)
			SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
		else
			SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 0);
		SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, samples);

		winWidth = w;
		winHeight = h;

	}

    void setOpenGL()
    {
        /+
        		// OpenGL options
        		// These are the engine defaults.  Any function that modifies these should reset them when done.
        		// TODO: Move these to OpenGL.reset()
        		glShadeModel(GL_SMOOTH);
        +/
        		glClearDepth(1);
        /+
        		glEnable(GL_DEPTH_TEST);
        		glDepthFunc(GL_LEQUAL);

        		glEnable(GL_CULL_FACE);
        		glEnable(GL_NORMALIZE);  // GL_RESCALE_NORMAL is faster but does not work for non-uniform scaling
        		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
        		glHint(GL_FOG_HINT, GL_FASTEST); // per vertex fog
        		glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, true); // [below] Specular highlights w/ textures.
        		glLightModeli(LIGHT_MODEL_COLOR_CONTROL_EXT, SEPARATE_SPECULAR_COLOR_EXT);

        		glEnable(GL_LIGHTING);
        		glFogi(GL_FOG_MODE, GL_EXP); // Most realistic?

        		// Environment Mapping (disabled by default)
        		glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
        		glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
        +/
    }

	/**
	 * Set the viewport position and size
	 * Params:
	 *     topLeft = Top left coordinates of the viewport in pixels.
	 *     winWidthwinHeight = winWidth and winHeight of the viewport in pixels.  If zero, defaults to window winWidth/winHeight. */
	void setViewport(vec2i topLeft=vec2i(0), vec2i wh=vec2i(0))
	{
        if (wh.x <= 0)
			wh.x = to!int(winWidth);
		if (wh.y <= 0)
			wh.y = to!int(winHeight);
		glViewport(topLeft.x, topLeft.y, wh.x, wh.y);
		viewportPosition = topLeft;
		viewportSize = wh;
	}

	/**
	 * Stores the dimensions of the current window size.
	 * This is called by a resize event in Input.checkInput(). */
	void resizeWindow(int w, int h)
	{	winWidth = w;
		winHeight = h;

        //SDL_SetWindowSize(sdlWindow, w, h);
        setViewport();
	}

/+
	/**
	 * Get an image from the Window's back-buffer (where image operations take place).
	 * Params:
	 *     buffer = Can be COLOR, DEPTH, or STENCIL to get the corresponding buffer.
	 * Returns: Image1ub for the stencil buffer, Image1ui for the depth buffer, or Image3ub for the color buffer.
	 * Example:
	 * --------
	 * IImage image = Window.getInstance().toImage(Window.Buffer.DEPTH);
	 ................* ubyte[] data = image.convert!(ubyte, 1).getBytes();  // convert imagem,\ from 32-bit grayscale to 8-bit grayscale
	 * File file = new File("depth.raw", File.WriteCreate); // Photoshop can open raw files
	 * file.write(image.convert!(ubyte, 1).getBytes());
	 * file.close();
	 * --------
	 */
	ImageBase toImage(Buffer buffer=Buffer.COLOR)
	{
		if (buffer==Buffer.STENCIL)		{
			Image1ub result = new Image1ub(to!ubyte(winWidth), to!ubyte(winHeight));
			glReadPixels(0, 0, to!int(winWidth), to!int(winHeight), GL_STENCIL_INDEX, GL_UNSIGNED_BYTE, result.data.ptr);
			return result;
		}
		else if (buffer==Buffer.DEPTH)
		{	Image2!(int, 1) result = new Image2!(int, 1)(to!int(winWidth), to!int(winHeight));
			glReadPixels(0, 0, to!int(winWidth), to!int(winHeight), GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, result.data.ptr);
			return result;
		} else // color
		{	Image3ub result = new Image3ub(to!ubyte(winWidth), to!ubyte(winHeight));
			glReadPixels(0, 0, to!int(winWidth), to!int(winHeight), GL_RGB,GL_UNSIGNED_BYTE, result.data.ptr);
			return result;
		}
	}

+/
	/**
	 * Returns: The singleton Window instance. */
	static Window getInstance(int width = 1366, int height = 768)
	{
        if (instance)
			return instance;
		return instance = new Window(width, height);
	}
}
