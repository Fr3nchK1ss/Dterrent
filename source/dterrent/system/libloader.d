/**
	Authors: Fr3nchK1ss on github
	Copyright: proprietary / contact dev

 */

module dterrent.system.libloader;
import dterrent.system.logger;

/* All the libs used by Dterrent */
import bindbc.sdl;
import bindbc.sdl.image;
import bindbc.openal;
import bindbc.freetype;
import bindbc.opengl;


/* Mixins declarations */
/**
 * Log errors when external libraries fail to load.
 * Params:
 * E = The Enum returned by the bindbc loader
 * loaded = the Enum value which indicates the loading succeeded
 * libName = The cosmetic name of the library to be loaded
 */
mixin template mxtpl_logResult(E, E validVersion, string libName)
{
	void logResult(immutable E libVersion, immutable LogLevel level)
    {
        if(libVersion != validVersion)
        {
    		if( libVersion == E.badLibrary ) {
    			/* Usually this means that either the library or one of its dependencies could not be found.*/
    			log(level, libName ~ " not found.");
    		}
    		else if ( libVersion == E.noLibrary ) {
    			/* e.g., an SDL 2.0.2 library loaded by an SDL 2.0.10 configuration.*/
    		          log(level, "The system was able to find and successfully load " ~ libName
    						~" but one or more symbols were missing."
    						~" This usually indicates that the loaded library is of a lower API"
    						~" version than expected.");
    		}
            else
                log(level, libName ~" failed to load.\n");
        }
        else
            tracef (libName ~" version %s loaded", libVersion);
	}

}

/**
 * Try to loads all necessary Dterrent libs
 */
void loadAll() {

    /**
     * To understand the template params, the SDLSupport enum looks like:
     * (in bindbc-sdl/source/bindbc/sdl/config.d)
     * enum SDLSupport {
     * noLibrary,
     * badLibrary,
     * sdl200      = 200,
     * sdl201      = 201,
     * ...}
     * and later on sdlSupport is defined as:
     * version(SDL_2012) enum sdlSupport = SDLSupport.sdl2012;
     * else version(SDL_2010) enum sdlSupport = SDLSupport.sdl2010;
     * ...
     */
    mixin mxtpl_logResult!(SDLSupport, sdlSupport, "SDL");
    logResult( loadSDL(), LogLevel.fatal );// throw a fatal Error if loading fails

    mixin mxtpl_logResult!(SDLImageSupport, sdlImageSupport, "SDLImage");
    logResult( loadSDLImage(), LogLevel.fatal );// throw

    mixin mxtpl_logResult!(ALSupport, ALSupport.al11, "OpenAL");
    logResult( loadOpenAL(), LogLevel.warning );// do not throw

    mixin mxtpl_logResult!(FTSupport, ftSupport, "FreeType");
    logResult( loadFreeType(), LogLevel.warning );

    import std.stdio: writeln;
    writeln("");
}

void loadOpenGL()
{
    mixin mxtpl_logResult!(GLSupport, GLSupport.gl46, "OpenGL");
    logResult( bindbc.opengl.loadOpenGL(), LogLevel.fatal );

    import std.stdio: writeln;
    writeln("");
}


bool isOpenALLoaded()
{
    return bindbc.openal.isOpenALLoaded();
}


void unloadAll(){
    unloadOpenGL();
    unloadSDL();
    unloadOpenAL();
    unloadFreeType();

}
