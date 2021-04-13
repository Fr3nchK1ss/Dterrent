/**
	This module is a rewrite of yage3D EngineObject class.

	Authors: Poggel / Fr3nchK1ss
	Copyright: Contact Fr3nchK1ss
 */

module dterrent.core.engineobject;

/**
 The EngineObject class is a base class for dterrent objects using Ids.
 */
class EngineObject
{
	// These maps prevent the id system from adding any additional weight per object.
	static EngineObject[string] objects;
	static string[EngineObject] objectsReverse;

	~this()
	{
		if (this in objectsReverse)
		{
			objects.remove(getId());
			objectsReverse.remove(this);
		}
	}

	/**
	 * Get or set a unique identifier string associated with this object.
	 * Later, if another object is assigned the same id, this object will no longer be associated with it.
     */
	string getId()
	{
		auto ptr = this in objectsReverse;
		if (ptr)
			return *ptr;
		return "";
	}

	void setId(string id) /// ditto
	{
		if (id.length)
		{
			// If id already exists on another object
			auto ptr = id in objects;
			if (ptr)
				objectsReverse.remove(*ptr);

			// If this object previously had another id
			string oldId = getId();
			if (oldId.length)
				objects.remove(oldId);

			objects[id] = this;
			objectsReverse[this] = id;
		}
		else if (this in objectsReverse)
		{
			objects.remove(getId());
			objectsReverse.remove(this);
		}
	}

	/**
	 * Get the object previously assigned to the unique id string.
	 * If no object exists, null will be returned. */
	static EngineObject getById(string id)
	{
		auto ptr = id in objects;
		if (ptr)
			return *ptr;
		return null;
	}

	unittest
	{
		class Foo : EngineObject
		{
		}

		Foo a = new Foo();
		Foo b = new Foo();
		a.setId("a");
		b.setId("b");
		assert(a.getId() == "a");
		assert(b.getId() == "b");
		b.setId("a");
		assert(b.getId() == "a");
		assert(a.getId() == "");
		b.setId("");
		assert(b.getId() == "");
		assert(objects.length == 0);
		assert(objectsReverse.length == 0);

		a.setId("a");
		b.setId("b");
		a.destroy();
		b.destroy();
		assert(objects.length == 0);
		assert(objectsReverse.length == 0);
	}
}
