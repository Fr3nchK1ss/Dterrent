/**
	This module is a rewrite of yage3D Tree class.

	Authors: Poggel / Fr3nchK1ss
	Copyright: Contact Fr3nchK1ss
 */

module dterrent.core.tree;

import dterrent.core.engineobject;
import algo = dterrent.core.algorithms;

/**
 * Implements an element that can be used in a tree, with parents and children.
 * Example:
 * --------------------------------
 * class Node : Tree!(Node) {}
 * auto n = new Node();
 * auto n2 = n.addChild(new Node());
 * --------------------------------
 */
class Tree(T) : EngineObject
{

	protected T parent; // reference to parent
	protected T[] children; // array of this element's children.
	protected int index = -1; // index of this element in its parent's array, -1 if no parent.

	/**
	 * Add a child element.
	 * Automatically detaches it from any other element's children.
	 * Params:
	 *     child = Node to add as a child of this element.
	 * Returns: A reference to the child
     */
	S addChild(S : T)(S child)
	{
		assert(child);
		assert(child != this);

		if (child.parent is this)
			return child;

		// If child has an existing parent.
		if (child.parent)
		{
			assert(child.parent.isChild(cast(S) child));
			algo.remove(child.parent.children, child.index);
		}

		// Add as a child.
		child.parent = cast(T) this;
		children ~= cast(T) child;
		child.index = cast(int)(children.length - 1); // @suppress(dscanner.suspicious.length_subtraction)

		return child;
	}

	/**
	 * Remove a child element
	 * Params:
	 *     child = An element of type T or that inherits from type T.
	 * Returns: The child element.  For convenience, the return type is templated to match the input type.
	 */
	S removeChild(S : T)(S child)
	{
		assert(child);
		assert(isChild(child));
		assert(child.parent == this);

		if (child.index >= 0)
		{
			algo.remove(children, child.index, false);
			if (child.index < children.length) // update index of element that replaced child.
				children[child.index].index = child.index;
			child.index = -1; // so remove can't be called twice.
			child.parent = null;
		}
		assert(!isChild(child));

		return child;
	}

	/// Get an array of this element's children.
	T[] getChildren()
	{
		return children;
	}

	/**
	 * Get / set the parent of this element (what it's attached to).
	 * Setting a new parent removes it from its old parent's children and returns a self-reference. */
	T getParent()
	{
		return parent;
	}

	/**
	 * Is elem a child of this element?
	 * This function will also return false if elem is null. */
	bool isChild(T elem)
	{
		if (!elem || elem.index < 0 || elem.index >= children.length)
			return false;
		return cast(bool)(children[elem.index] == elem);
	}

}
