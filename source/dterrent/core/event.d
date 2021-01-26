/**
 * Copyright:  (c) 2005-2009 Eric Poggel
 * Authors:	   Eric Poggel
 * License:	   <a href="lgpl3.txt">LGPL v3</a>
 *
 */

module dterrent.core.event;

/**
 * Implements the event pattern.
 * Params:
 *     T = Every listener of this event should accept these arguments
 * Example:
 * Event!(int) event;
 * event.addListener(delegate void(int a) { ... });
 * event(); // calls all listeners. */
struct Event(T...)
{
	void delegate() listenersChanged; /// Called after the listeners are added or removed.
    /*
     * A set. Associative arrays are copied by ref, so when one event is assigned to another,
     * they will both point ot the same listeners.
     */
	protected bool[void delegate(T)] listeners;

	void addListener(void delegate(T) listener)
	{	listeners[listener] = true;
		if (listenersChanged)
			listenersChanged();
	}

	/// Call all the functions in the listeners list.
	void opCall(T args)
	{	foreach (func, unused; listeners)
		func(args);
	}

	ulong length()
	{	return listeners.length;
	}

	void removeListener(void delegate(T) listener)
	{	listeners.remove(listener);
		if (listenersChanged)
			listenersChanged();
	}

	void removeAll()
	{	foreach (key; listeners.keys)
		listeners.remove(key);
		if (listenersChanged)
			listenersChanged();
	}
}
