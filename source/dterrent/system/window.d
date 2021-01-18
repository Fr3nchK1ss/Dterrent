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
import tango.io.Stdout;

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
	}

/+
	void dispose()
	{	if (instance)
		{	SDL_FreeSurface(sdlSurface); // TODO I probably need a surface anyway for other things...
			DerelictGL.unload();
			instance = null;
		}
	}
+/
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

		// If SDL ever decouples window creation from initialization, we can move these to System.init().
		// Create the screen surface (window)
		uint flags = SDL_WINDOW_RESIZABLE | SDL_GL_DOUBLEBUFFER | SDL_WINDOW_OPENGL; // TODO these no longer matter? | SDL_HWPALETTE | SDL_HWACCEL;
		if (fullscreen_) flags |= SDL_WINDOW_FULLSCREEN;
			sdlWindow = SDL_CreateWindow("DT3RR3NT",
                                      cast(int) SDL_WINDOWPOS_UNDEFINED,
                                      cast(int) SDL_WINDOWPOS_UNDEFINED,
                                      cast(int) winWidth,
                                      cast(int) winHeight,
                                      cast(SDL_WindowFlags) flags); // TODO depth, is no longer an option.

		sdlSurface = SDL_GetWindowSurface(sdlWindow);
        mainGLContext = SDL_GL_CreateContext(sdlWindow);

		libloader.loadOpenGL();

		if(sdlSurface is null)
			throw new Exception(format("Unable to set %d x %d video mode: %s ", winWidth, winHeight, SDL_GetError()));
		SDL_LockSurface(sdlSurface);

		// TODO these likely need to be completely redone for SDL2 anyway
		// These have to be set after window creation.
		// SDL_EnableUNICODE(1);
		//SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);
		// SDL_EnableKeyRepeat(0, 0); // disable, we handle it ourselves

		// TODO these are assumed once we move to full GL3
		// Attempt to load multitexturing
/*		if (Probe.feature(Probe.Feature.MULTITEXTURE))
		{	if (!ARBMultitexture.load("GL_ARB_multitexture"))
				throw new YageException("GL_ARB_multitexture extension detected but it could not be loaded.");
			Log.info("GL_ARB_multitexture support enabled.");
		}else
			Log.info("GL_ARB_multitexture not supported.  This is ok, but graphical quality may be limited.");

		// Texture Compression
		if (Probe.feature(Probe.Feature.TEXTURE_COMPRESSION))
		{	if (!ARBTextureCompression.load("GL_ARB_texture_compression"))
				throw new YageException("GL_ARB_texture_compression extension detected but it could not be loaded.");
			Log.info("GL_ARB_texture_compression support enabled.");
		}else
			Log.info("GL_ARB_multitexture not supported.  This is ok, but graphical quality may be limited.");

		// Attempt to load shaders
		if (Probe.feature(Probe.Feature.SHADER))
		{	if (!ARBShaderObjects.load("GL_ARB_shader_objects"))
				throw new YageException("GL_ARB_shader_objects extension detected but it could not be loaded.");
			if (!ARBVertexShader.load("GL_ARB_vertex_shader"))
				throw new YageException("GL_ARB_vertex_shader extension detected but it could not be loaded.");
			Log.info("GL_ARB_shader_objects support enabled.");
		}else
			Log.info("GL_ARB_shader_objects not supported.  This is ok, but rendering will be limited to the fixed-function pipeline.");

		// Attempt to load vertex buffer object
		if (Probe.feature(Probe.Feature.VBO))
		{	if (!ARBVertexBufferObject.load("GL_ARB_vertex_buffer_object"))
				throw new YageException("GL_ARB_vertex_buffer_object extension detected but it could not be loaded.");
			Log.info("GL_ARB_vertex_buffer_object support enabled.");
		}else
			Log.info("GL_ARB_vertex_buffer_object not supported.  This is still ok.");

		// Frame Buffer Object
		if (Probe.feature(Probe.Feature.FBO))
		{	if (!EXTFramebufferObject.load("GL_EXT_framebuffer_object"))
				throw new YageException("GL_EXT_framebuffer_object extension detected but it could not be loaded.");
			Log.info("GL_EXT_framebuffer_object support enabled.");
		}else
			Log.info("GL_EXT_framebuffer_object not supported.  This is still ok.");
*/

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
		setViewport();
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

                // TODO this is likely never needed anymore?
		// For some reason, SDL Linux requires a call to SDL_SetVideoMode for a screen resize that's
		// larger than the current screen. (need to try this with latest version of SDL, also try SDL lock surface)
		// This same code would crash the engine on windows.
		// This code may now be un-needed and needs to be retested.
		// See http://www.libsdl.org/cgi/docwiki.cgi/SDL_5fResizeEvent
/*		version (linux)
		{	uint flags = SDL_HWSURFACE | SDL_GL_DOUBLEBUFFER | SDL_OPENGL | SDL_RESIZABLE | SDL_HWPALETTE | SDL_HWACCEL;
			if (fullscreen)
				flags |= SDL_FULLSCREEN;
			sdlSurface = SDL_SetVideoMode(winWidth, winHeight, 0, flags);
			if (sdlSurface is null)
				throw new YageException("Failed to resize the window!");
		} */
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
