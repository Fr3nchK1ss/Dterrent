/**
	Authors: ludo456 on github
	Copyright: proprietary / contact dev

 */

module dterrent.system.libloader;

import std.experimental.logger;

/* All the libs used by Dterrent */
import bindbc.sdl;
import bindbc.sdl.image;
import bindbc.openal;
import bindbc.freetype;

abstract class LibLoader {
	/* Mixins declarations */
	/**
	 * Log errors when external libraries fail to load.
	 * Params:
	 * E = The Enum returns by the bindbc loader
	 * libName = The cosmetic name of the library to be loaded
	 */
	mixin template mxtpl_logLoadError(E, string libName) {
		void logLoadError(){
			E magic;
			if( magic == E.badLibrary ) {
				/* Usually this means that either the library or one of its dependencies could not be found.*/
				fatal(libName ~ " not found.");
			}
			else if ( magic == E.noLibrary ) {
				/* e.g., an SDL 2.0.2 library loaded by an SDL 2.0.10 configuration.*/
				fatal ("The system was able to find and successfully load " ~ libName
							~" but one or more symbols were missing."
							~" This usually indicates that the loaded library is of a lower API"
							~" version than expected.");
			}
		}

	}

	/**
	 * Try to loads all necessary Dterrent libs
	 */
	static void loadAll() {

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

		FTSupport ftMagic = loadFreeType();
		if( ftMagic != ftSupport ) {
			mixin mxtpl_logLoadError!(FTSupport, "FreeType"); logLoadError();
		}
	}

}
