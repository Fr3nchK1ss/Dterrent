/**
	Authors: ludo456 on github
	Copyright: proprietary / contact dev

 */

module dterrent.system.sound.openal;
import dterrent.system.logger;

import std.exception : enforce;
import std.traits : fullyQualifiedName, ReturnType, Parameters;

public import bindbc.openal;


/*
import tango.core.Traits;
import yage.core.misc;
import yage.system.sound.soundsystem;
*/


/**
 * Create a wrapper around all OpenAL functions providing the following additional features:
 *
 * Error results from each openal call are checked.
 * On error, an exception is thrown with the OpenAL error code translated to a meaningful string. */
class OpenAL
{
	static string[int] ALErrorLookup;

	// Initialize static variables
	static this ()
	{	ALErrorLookup = [
			0xA001: "AL_INVALID_NAME"[],
			0xA002: "AL_ILLEGAL_ENUM",
			0xA002: "AL_INVALID_ENUM",
			0xA003: "AL_INVALID_VALUE",
			0xA004: "AL_ILLEGAL_COMMAND",
			0xA004: "AL_INVALID_OPERATION",
			0xA005: "AL_OUT_OF_MEMORY"
		];
        import std.stdio;
		writeln("openal static this");
	}


    /**
     * wrapper around OpenAL functions
     */
    synchronized static R execute(alias FUNC, R=ReturnType!FUNC)(Parameters!FUNC func_args)
    {
        int error = alGetError(); // clear any previous errors.

        void checkError()
        {
                        info("Checking for al error");// TODO: remove
            error = alGetError();
            enforce (error == AL_NO_ERROR,
                     "OpenAL: " ~ fullyQualifiedName!(FUNC) ~ ": " ~ OpenAL.ALErrorLookup[error]);
        }

        // Call FUNC
        static if (is (R == void))
        {
            FUNC(func_args);
            static if (FUNC.stringof[0..3] != "alc")
                checkError();
        }
        else
        {
            R result = FUNC(func_args);
            info(FUNC.stringof[0..3]);// TODO: remove
            static if (FUNC.stringof[0..3] == "alc") // can't use alGetError for alc functions.
            {
                enforce(!result,
                        "OpenAL: " ~ fullyQualifiedName!(FUNC) ~ " returned null instead
                        of a valid " ~ R.stringof);
            }
            else
                checkError();

            return result;
        }
    }

	/**
	 * Wrappers for each OpenAL function (unfinished).
     */
	alias bufferData = execute!(alBufferData) ; /// ditto
	alias deleteBuffers = execute!(alDeleteBuffers) ; /// ditto
	alias deleteSources = execute!(alDeleteSources) ; /// ditto
	alias genBuffers = execute!(alGenBuffers) ; /// ditto
	alias genSources = execute!(alGenSources); /// ditto
	alias getSourcef = execute!(alGetSourcef); /// ditto
	alias getSourcei = execute!(alGetSourcei); /// ditto
	alias isBuffer = execute!(alIsBuffer) ; /// ditto
	alias listenerfv = execute!(alListenerfv) ; /// ditto
	alias sourcef = execute!(alSourcef) ; /// ditto
	alias sourcefv = execute!(alSourcefv) ; /// ditto
	alias sourcePlay = execute!(alSourcePlay) ; /// ditto
	alias sourcePause = execute!(alSourcePause) ; /// ditto
	alias sourceQueueBuffers = execute!(alSourceQueueBuffers) ; /// ditto
	alias sourceStop = execute!(alSourceStop) ; /// ditto
	alias sourceUnqueueBuffers = execute!(alSourceUnqueueBuffers) ; /// ditto

	alias closeDevice = execute!(alcCloseDevice) ; /// ditto
	alias createContext = execute!(alcCreateContext) ; /// ditto
	alias destroyContext = execute!(alcDestroyContext) ; /// ditto
	alias getIntegerv = execute!(alcGetIntegerv) ; /// ditto
	alias getString = execute!(alcGetString) ; /// ditto
	alias makeContextCurrent = execute!(alcMakeContextCurrent) ; /// ditto
	alias openDevice = execute!(alcOpenDevice) ; /// ditto

}
