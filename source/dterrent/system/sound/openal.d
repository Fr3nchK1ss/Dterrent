/**
	Authors: ludo456 on github
	Copyright: proprietary / contact dev

 */

module dterrent.system.sound.openal;
import dterrent.system.logger;

import std.traits : fullyQualifiedName, ReturnType, Parameters;
import std.conv : to;
public import bindbc.openal;

package(dterrent.system.sound) ALCdevice* device = null;

/**
 * Class to bundle OpenAL
 */
class OpenAL
{

    /**
     * wrapper around OpenAL functions in order to add error checking
     */
    synchronized static R execute(alias FUNC, R=ReturnType!FUNC)(Parameters!FUNC func_args)
    {
        /**
         * (Nested) Check for error with a regular al call
         */
        void checkAlError()
        {
            int error = alGetError();
            if(error != AL_NO_ERROR)
            {
                final switch(error)
                {
                    case AL_INVALID_NAME:
                        critical("AL_INVALID_NAME: a bad name (ID) was passed\n");
                        break;
                    case AL_INVALID_ENUM:
                        critical("AL_INVALID_ENUM: an invalid enum value was passed\n");
                        break;
                    case AL_INVALID_VALUE:
                        critical("AL_INVALID_VALUE: an invalid value was passed\n");
                        break;
                    case AL_INVALID_OPERATION:
                        critical("AL_INVALID_OPERATION: the requested operation is not valid\"\n");
                        break;
                    case AL_OUT_OF_MEMORY:
                        critical("AL_OUT_OF_MEMORY: the requested operation resulted in OpenAL running out of memory\n");
                        break;
                }
            }
        }

        /**
         * (Nested) for error with an al context call
         */
        void checkAlcError(ALCdevice* device)
        {
            int error = alcGetError(device);
            if(error != ALC_NO_ERROR)
            {
                final switch(error)
                {
                    case ALC_INVALID_VALUE:
                        critical ("ALC_INVALID_VALUE: an invalid value was passed\n");
                        break;
                    case ALC_INVALID_DEVICE:
                        critical ("ALC_INVALID_DEVICE: a bad device was passed\n");
                        break;
                    case ALC_INVALID_CONTEXT:
                        critical ("ALC_INVALID_CONTEXT: a bad context was passed\n");
                        break;
                    case ALC_INVALID_ENUM:
                        critical ("ALC_INVALID_ENUM: an unknown enum value was passed\n");
                        break;
                    case ALC_OUT_OF_MEMORY:
                        critical ("ALC_OUT_OF_MEMORY: an unknown enum value was passed\n");
                        break;
                }
            }
        }

        //info ( "OpenAL: Executing " ~ fullyQualifiedName!(FUNC) ~ " \n");
        alGetError(); // clear any previous errors.

        // Call FUNC
        static if (is (R == void))
        {
            FUNC(func_args);
            static if (FUNC.stringof[0..3] != "alc")
                checkAlError();
            else
                checkAlcError(device);
        }
        else
        {
            R result = FUNC(func_args);

            //trace( FUNC.stringof ~" returned: " ~ R.stringof ~ " " ~ to!string(result));

            static if (FUNC.stringof[0..3] != "alc")
                checkAlError();
            else
                checkAlcError(null);

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
