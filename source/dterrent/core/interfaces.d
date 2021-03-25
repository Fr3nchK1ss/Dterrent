/**
	Authors: Fr3nchK1ss on github
	Copyright: proprietary / contact dev

 */

module dterrent.core.interfaces;

/**
 * An interface for anything that can be cloned via a clone() method.
 */
interface ICloneable
{
	Object clone(); ///
}

/**
 * Any class that has to do custom cleanup operations before destruction should implement this.
 */
interface IDisposable
{
	/**
	 * Clean up resources before garbage collection that can't safely be cleaned up in a destructor.
	 * Finalize must be able to accept multiple calls, in case it is called manually and by a destroctor.
	 * After dispose is called, it's object should be considered to be in a non-usable state and ready for destruction.*/
	void dispose();
}

/**
 * Anything that implements this can act as a target for anything that
 * renders using OpenGL operations.
 */
interface IRenderTarget
{
	ulong getWidth();
	ulong getHeight();
}

/**
 * An interface for anything that implements timekeeping functions.
    Itemporal may be implemented by:
    Timer
    Repeater (loop makes no sense)
    Scene (loop makes little sense)
    SoundNode
    ModelNode
    AnimatedTexture
 */
interface ITemporal
{
	///
	void play();

	///
	void pause();

	///
	bool paused();

	///
	void stop();

	///
	void seek(double seconds);

	///
	double tell();
}
