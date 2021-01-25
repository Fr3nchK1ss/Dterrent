/**
	Authors: JoeCoder - original Yage3D programmer
	Copyright: proprietary

 */
module dterrent.core.multithreading.fastlock;

import core.sync.mutex;
import core.thread;

class FastLock
{
	protected Mutex mutex;
	protected int lockCount;
	protected Thread owner;

	///
	this()
	{	mutex = new Mutex();
	}

	/**
	 * This works the same as Tango's Mutex's lock()/unlock except provides extra performance in the special case where
	 * a thread calls lock()/unlock() multiple times while it already has ownership from a previous call to lock().
	 * This is a common case in Yage.
	 *
	 * For convenience, lock() and unlock() calls may be nested.  Subsequent lock() calls will still maintain the lock,
	 * but unlocking will only occur after unlock() has been called an equal number of times.
	 *
	 * On Windows, Tango's lock() is always faster than D's synchronized statement.  */
	void lock()
	{	auto self = Thread.getThis();
		if (self !is owner)
		{	mutex.lock();
			owner = self;
		}
		lockCount++;
	}
	void unlock() /// ditto
	{	assert(Thread.getThis() is owner);
		lockCount--;
		if (!lockCount)
		{	owner = null;
			mutex.unlock();
		}
	}
}
