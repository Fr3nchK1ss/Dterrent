/**
    This module manages OpenAL device and sources

	Authors: Poggel / Fr3nchK1ss
	Copyright: Contact Fr3nchK1ss
 */


module dterrent.system.sound.soundsystem;
import dterrent.system.logger;

import std.exception : enforce;
import std.string;
import std.math : floor;
import std.algorithm : max;
import std.conv : to;

import gl3n.linalg;
import dterrent.core.interfaces;
import dterrent.system.sound.openal;
import dterrent.resource.sound;

/*
import tango.util.Convert;
import tango.core.Thread;
import tango.core.Traits;

import yage.core.array;
import yage.core.object2;
import yage.core.math.all;
import yage.core.misc;
import yage.core.repeater;
import yage.core.timer;
import yage.scene.camera;
import yage.scene.sound;
import yage.resource.sound;
*/

/**
 * This class is used internally by the engine and shouldn't need to be used manually.
 *
 * Instantiates an OpenAL device and context upon init()
 * Stores a short array of SoundSource wrappers that can be wrapped around with an infinite number of virtual sources
 * Controls a sound thread that handles buffering audio to all active SoundSources.
 */
class SoundContext
{
	private static const int MAX_SOURCES = 32; // arbitrary.  TODO: Make this a variable
	private static const int UPDATE_FREQUENCY = 30; // arbitrary
	private static SoundSource[] sources;

	private static ALCcontext* context = null;

	/**
	 * Create a device, a context, and start a thread that automatically updates all sound buffers.
	 */
	public static void init()
	{
		// Get a device
		device = OpenAL.openDevice(null); // device is a package variable defined in openal.d
		tracef("Using OpenAL Device '%s'.",
				fromStringz(OpenAL.getString(device, ALC_DEVICE_SPECIFIER)));

		// Get a context
		context = OpenAL.createContext(device, null);
		OpenAL.makeContextCurrent(context);

		// Query how many sources are available.
		// Note that we only query the number of mono sources.
		int max_sources;
		OpenAL.getIntegerv(device, ALC_MONO_SOURCES, 1, &max_sources);
		enforce(max_sources > 0, "OpenAL reports no sound sources available.
        Please close any other applications which may be using sound resources.");

		if (max_sources > MAX_SOURCES)
			max_sources = MAX_SOURCES;

		// Create as many soures as we can, up to a limit
		for (int i = 0; i < max_sources; i++)
		{
			auto source = new SoundSource();
			sources ~= source;
		}

	}

	/**
	 * Delete the dedvice and context,
	 * delete all sources, and set the current context to null. */
	static void deInit()
	{
		if (context)
		{

			foreach (source; sources)
				if (source) // in case of the unpredictible order of the gc.
					source.dispose();

			sources = null;
			OpenAL.makeContextCurrent(null);
			OpenAL.destroyContext(context);
			OpenAL.closeDevice(device);
			context = device = null;
		}
	}

	/**
	 * Get the OpenAL Context. */
	static ALCcontext* getContext()
	{
		return context;
	}

	/+
	/*
	 * Called by the sound thread to update all active source's sound buffers. */
	static void updateSounds(SoundList list)
	{
		union Orientation {
			struct { Vec3f look, up; }
			float[6] values;
		}
		Orientation orientation;
		orientation.look = Vec3f(0, 0, -1).rotate(list.cameraRotation);
		orientation.up = Vec3f(0, 1, 0).rotate(list.cameraRotation);

		synchronized (OpenAL.getMutex())
		{
			// Set the listener position, velocity, and orientation
			OpenAL.listenerfv(AL_POSITION, list.cameraPosition.ptr);
			OpenAL.listenerfv(AL_ORIENTATION, orientation.values.ptr);
			OpenAL.listenerfv(AL_VELOCITY, list.cameraVelocity.ptr);

			// Unbind sources that no longer have a command.
			foreach (i, source; sources)
			{
				bool unbind = true;
				foreach (command; list.commands)
					if (source.soundNode is command.soundNode) // already bound here, change nothing.
					{	//Log.write("rebinding %s to source %d", command.sound.getSource(), i);
						source.bind(command); // update the source with the new command variables
						unbind = false;
						break;
					}
				if (unbind)
					source.unbind();
			}

			// Bind commands to empty sources.
			foreach (command; list.commands)
			{	bool unbound = true;
				foreach (source; sources)
					if (source.soundNode is command.soundNode)
					{	unbound = false;
						break;
					}

				// if this command is not bould to any source
				if (unbound)
				{	foreach (i, source; sources) // find a source to bind to.
						if (!source.soundNode)
						{	//Log.write("binding %s to source %d, intensity=%f", command.sound.getSource(), i, command. intensity);
							source.bind(command);
							break;
						}
				}
			}
		}

		// update each source's sound buffers.
		foreach (source; sources)
			if (source.soundNode)
				source.updateBuffers();
	}
+/
}

/*
 * Represents an OpenAL source (an instance of a sound playing).

 * Typical hardware can only support a small number of these, so SoundNodes map and unmap to these sources as needed.
 * This is used internally by the engine and should never need to be instantiated manually. */
private class SoundSource : IDisposable
{

	package uint al_source;
	/+
	private SoundNode soundNode;	// It would be good if this became unnecessary.  It's currently required to set the playback timer.
+/
	private Sound sound;

	private float pitch;
	private float radius; // The radius of the Sound that plays.
	private float volume;
	private bool looping = false;
	private vec3 position;
	private vec3 velocity;

	private ulong size; // number of buffers that we use at one time, either sounds' buffers per second,
	// or less if the sound is less than one second long.
	private bool enqueue = true; // Keep enqueue'ing more buffers, false if no loop and at end of track.
	private ulong buffer_start; // the first buffer in the array of currently enqueue'd buffers
	private ulong buffer_end; // the last buffer in the array of currently enqueue'd buffers
	private ulong to_process; // the number of buffers to queue next time.

	/*
	 * Create the OpenAL Source. */
	this()
	{
		OpenAL.genSources(1, &al_source);
	}

	/*
	 * Stop playback, unqueue all buffers and then delete the source itself. */
	~this()
	{
		dispose();
	}

	void dispose() // ditto
	{
		if (al_source)
		{
			//unbind();
			alDeleteSources(1, &al_source);
			al_source = 0;
		}
	}
	/+
	/*
	 * SoundNodes act as a virtual instance of a real SoundSource
	 * This function ensures the SoundSource matches all of the parameters of the SoundNode.
	 * If called multiple times from the same SoundNode, this will just update the parameters. */
	void bind(SoundCommand command)
	{
		soundNode = command.soundNode;
		looping = command.looping;

		synchronized(OpenAL.getMutex())
		{
			if (sound !is command.sound)
			{	sound = command.sound;

				// Ensure that our number of buffers isn't more than what exists in the sound file
				ulong len = sound.getBuffersLength();
				ulong sec = sound.getBuffersPerSecond();
				size = len < sec ? len : sec;

				seek(command.position);
			}

			if (radius != command.radius)
			{	radius = command.radius;
				OpenAL.sourcef(al_source, AL_ROLLOFF_FACTOR, 1.0/radius);
			}

			if (volume != command.volume)
			{	volume = command.volume;
				OpenAL.sourcef(al_source, AL_GAIN, volume);
			}

			if (pitch != command.pitch)
			{	pitch = command.pitch;
				OpenAL.sourcef(al_source, AL_PITCH, pitch);
			}

			double marginOfError = 1.0/ /*sound.getBuffersPerSecond()*/ 0.05; // is this always .05?
			double _tell = tell();
			double seconds = command.position;
			if ((seconds+marginOfError < _tell ||  _tell < seconds-marginOfError))
			{	if (command.reseek)
					seek(seconds);
				else if (enqueue) // update soundNode's playback timer to the real playback location.
				{	//Log.write("reseek!");
					command.soundNode.seek(_tell); // Warning-- this should be behind a lock!
				}
			}
			command.reseek = false;// is this necessary?

			if (position != command.worldPosition)
			{	position = command.worldPosition;
				OpenAL.sourcefv(al_source, AL_POSITION, position.ptr);
			}

			if (velocity != command.worldVelocity)
			{	velocity = command.worldVelocity;
				OpenAL.sourcefv(al_source, AL_VELOCITY, velocity.ptr);
			}
		}
	}

	/*
	 * Unbind this sound source from a sound node, stopping playback and resetting key state variables. */
	void unbind()
	{
		if (soundNode)
		{	enqueue	= false;
			synchronized(OpenAL.getMutex())
			{	//Stdout.format("unbinding source");
				OpenAL.sourceStop(al_source);
				//Stdout.format("2]");
				unqueueBuffers();
			}
			buffer_start = buffer_end = 0;
			sound = null; // so sound can be freed if no more references.
			soundNode = null;
		}
	}
+/
	/*
	 * Seek to the position in the track.  Seek has a precision of .05 seconds.
	 * @throws OpenALException if the value is outside the range of the Sound. */
	void seek(double seconds)
	{
		int buffers_per_second = sound.getBuffersPerSecond();
		int new_start = cast(int) floor(seconds * buffers_per_second);
		float fraction = seconds * buffers_per_second - new_start;
		enforce(new_start <= sound.getBuffersLength(),
				"SoundSource.seek(" ~ to!string(
					seconds) ~ ") is invalid for ''" ~ sound.getSource() ~ "'.");

		// Delete any leftover buffers

		OpenAL.sourceStop(al_source);

		unqueueBuffers();
		buffer_start = buffer_end = new_start;
		enqueue = true;
		updateBuffers();

		OpenAL.sourcePlay(al_source);
		OpenAL.sourcef(al_source, AL_SEC_OFFSET, fraction / buffers_per_second);
		// Stdout.format("seeked to ", (new_start+fraction)/buffers_per_second);
	}
	/+
	/*
	 * Tell the position of the playback of the current sound file, in seconds. */
	double tell()
	{
		int processed; // [below] synchronization shouldn't be needed for read-only functions... ?
		OpenAL.getSourcei(al_source, AL_BUFFERS_PROCESSED, &processed);
		float fraction=0;
		OpenAL.getSourcef(al_source, AL_SEC_OFFSET, &fraction);
		return ((buffer_start + processed) % sound.getBuffersLength()) /
			cast(double)sound.getBuffersPerSecond();
	}
+/
	/*
	 * Enqueue new buffers for this SoundNode to play
	 * Takes into account pausing, looping and all kinds of other things.
	 * This is normally called automatically from the SoundNode's scene's sound thread.
	 * This will fail silently if the SoundNode has no sound or no scene. */
	void updateBuffers()
	in
	{
		//assert(soundNode);
		assert(sound);
	}
	do
	{
		if (enqueue)
		{
			//Stdout.format("updating buffers for %s", sound.getSource());
			// Count buffers processed since last time we queue'd more
			int processed;
			OpenAL.getSourcei(al_source, AL_BUFFERS_PROCESSED, &processed);
			to_process = max(processed, size - (buffer_end - buffer_start));

			// Update the buffers for this source if more than 1/4th have been used.
			if (to_process > size / 4)
			{
				// If looping and our buffer has reached the end of the track
				ulong blength = sound.getBuffersLength();
				if (!looping && buffer_end + to_process >= blength)
					to_process = blength - buffer_end;

				// Unqueue old buffers
				unqueueBuffers();

				// Enqueue as many buffers as what are available
				sound.allocBuffers(buffer_end, to_process);
				OpenAL.sourceQueueBuffers(al_source, to!(int)(to_process),
						sound.getBuffers(buffer_end, buffer_end + to_process).ptr);

				buffer_start += processed;
				buffer_end += to_process;
			}
		}

		// If not playing
		// Is this block still necessary if everything behaves as it should?
		int state;
		OpenAL.getSourcei(al_source, AL_SOURCE_STATE, &state);
		if (state == AL_STOPPED || state == AL_INITIAL)
		{ // but it should be, resume playback
			if (enqueue)
				OpenAL.sourcePlay(al_source);
			else // we've reached the end of the track
			{
				// stop
				OpenAL.sourceStop(al_source);
				unqueueBuffers();
				buffer_start = buffer_end = 0;

				if (looping)
				{ //play
					OpenAL.sourcePlay(al_source);
					enqueue = true;
				}
			}
		}

		// This is required for tracks with their total number of buffers equal to size.
		if (enqueue) // If not looping and our buffer has reached the end of the track
			if (!looping && buffer_end + 1 >= sound.getBuffersLength())
				enqueue = false;

	}

	/*
	 * Unqueue all buffers that have finished playing
	 * If the source is stopped, all buffers will be removed. */
	private void unqueueBuffers()
	{
		if (sound)
		{
			int processed;
			OpenAL.getSourcei(al_source, AL_BUFFERS_PROCESSED, &processed);
			OpenAL.sourceUnqueueBuffers(al_source, processed,
					sound.getBuffers(buffer_start, buffer_start + processed).ptr);
			sound.freeBuffers(buffer_start, processed);
		}
	}

}
