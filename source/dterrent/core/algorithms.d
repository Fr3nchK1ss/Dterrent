/**
	Authors: Poggel / Fr3nchK1ss
	Copyright: proprietary / contact dev

	This class is a rewrite of yage3D EngineObject class.
 */

module dterrent.core.algorithms;
import dterrent.system.logger;

import std.format;

/**
 * Add an element to an already sorted array, maintaining the same sort order.
 * replace this with a Heap?
 * Params:
 *     array = The array to use.
 *     value = Value to add.
 *     increasing = The elements are stored in increasing order.
 *     getKey = A function to return a key of type K for each element.
 *     			K must be either a primitive type or a type that impelments opCmp.
 *              Only required for arrays of classes and structs. */
void addSorted(T, K)(ref T[] array, T value, bool increasing,
		K delegate(T elem) getKey, int max_length = int.max)
{
	if (!array.length)
	{
		array ~= value;
		return;
	}

	const K key_value = getKey(value);
	if (array.length < max_length) // increase the length
		array.length = array.length + 1; // [below] If fixed length and no place to add, immediately return.
	else if (increasing ? key_value > getKey(array[$ - 1]) : key_value < getKey(array[$ - 1]))
		return;

	// Despite two loops, this still runs in worst-case O(n)
	for (int i = 0; i < array.length - 1; i++) // TODO: Use a binary search instead of linear.
	{
		if (increasing ? key_value <= getKey(array[i]) : key_value >= getKey(array[i]))
		{
			for (int j = array.length - 2; j >= i; j--) // Shift all elements forward
				array[j + 1] = array[j];
			array[i] = value;
			return;
		}
	}

	array[$ - 1] = value;
}

void addSorted(T, K)(ref ArrayBuilder!(T) array, T value, bool increasing,
		K delegate(T elem) getKey, int max_length = int.max) /// ditto
		{
	if (!array.length)
	{
		array ~= value;
		return;
	}

	const K key_value = getKey(value);
	if (array.length < max_length) // increase the length
		array.length = array.length + 1; // [below] If fixed length and no place to add, immediately return.
	else if (increasing ? key_value > getKey(array.data[$ - 1]) : key_value < getKey(
			array.data[$ - 1]))
		return;

	// Despite two loops, this still runs in worst-case O(n)
	for (int i = 0; i < array.length - 1; i++) // TODO: Use a binary search instead of linear.
	{
		if (increasing ? key_value <= getKey(array.data[i]) : key_value >= getKey(array.data[i]))
		{
			for (ulong j = array.length - 2; j >= i; j--) // Shift all elements forward
				array.data[j + 1] = array.data[j];
			array.data[i] = value;
			return;
		}
	}

	array.data[$ - 1] = value;
}

bool replaceSmallestIfBigger(T)(T[] array, T item, bool delegate(T a, T b) isABigger)
{
	for (int i = 0; i < array.length; i++)
		if (isABigger(item, array[i]))
		{
			for (int j = i; j < array.length - 1; j++) // move all of the items after it over one place
				array[j + 1] = array[j];
			array[i] = item; // and insert new item
			return true;
		}
	return false;
}

/+
/// Ditto
bool sorted(T, K)(T[] array, bool increasing, K delegate(T elem) getKey)
{
}
unittest
{	assert(sorted([-1, 0, 1, 2, 2, 5]) == true);
	assert(sorted([-1, 0, 1, 2, 1, 5]) == false);
	assert(sorted([5, 3, 3, 3, 2, -1], false) == true);

	import std.algorithm.sorting;
	struct S { int a; }

	S s1; s1.a = 2;
	S s2; s2.a = 3;
	S s3; s3.a = 3;
	S s4; s4.a = 10;

	assert(isSorted([-1, 0, 1, 2, 2, 5]));
	assert(!isSorted([-1, 0, 1, 2, 1, 5]));
	assert(isSorted!"a>b"([5, 3, 3, 3, 2, -1]));

	assert(isSorted!"a.a < b.a"([s1, s2, s3, s4]));
}
+/

/**
 * Remove an element from an array.
 * This takes constant time, or linear time if ordered is true.
 * Params:
 *     array    = The array to use.
 *     index    = Index of the element to remove.
 *     ordered  = Keep all elements in the same order, at the cost of performance. 
 * TODO: this function is BROKEN, see unittest. Kept for backwards compatibility
 */
void remove(T)(ref T[] array, int index, bool ordered = true)
{
	if (ordered)
		for (size_t i = index; i < array.length - 1; i++)
			array[i] = array[i + 1];
	else if (index != array.length - 1)
				array[index] = array[array.length - 1];
	array.length = array.length - 1;
}

unittest
{
	// Remove
	int[] test1 = [0, 1, 2, 3, 4];
	test1.remove(0);
	test1.remove(4); // BROKEN, should fail! index 4 does not exist any more...
	assert(test1 == [1, 2, 3]);
	test1.remove(0, false);
	assert(test1 == [3, 2]);

	import m = std.algorithm.mutation : remove;

	alias mmove = m.remove;
	int[] test2 = [0, 1, 2, 3, 4];

	test2 = mmove(test2, 0);
	test2 = mmove(test2, 3);
	assert(test2 == [1, 2, 3]);
}

/**
 * Sort the elements of an array using a radix sort.
 * This runs in linear time and can sort several million items per second on modern hardware.
 * Special thanks go to Pierre Terdiman for his essay: Radix Sort Revisited.
 * Params:
 *     getKey = A function to return a key of type K for each element.
 *              Only required for arrays of classes and structs.
 *     signed = interpret the key data as being signed.  Defaults to true.
 * Example:
 * --------------------------------
 * Timer[] array;
 * // ... fill array with new Timer() ...
 * array.radixSort((Timer a) { return a.tell(); }); // sort timers by thier time
 * --------------------------------
 */
void radixSort(T)(T[] array, bool increasing = true)
{
	radixSort(array, increasing, (T a) { return a; });
}

/// ditto
void radixSort(T, K)(T[] array, bool increasing, K delegate(T elem) getKey, bool signed = true)
{ // Are we sorting floats?
	bool isfloat = false;
	static if (is(K == float) || is(K == double) || is(K == real)
			|| is(K == ifloat) || is(K == idouble) || is(K == ireal)
			|| // Not sure if these will work.
			 is(K == cfloat) || is(K == cdouble) || is(K == creal))
		isfloat = true;

	// A struct to hold our key and a pointer to our value
	struct Elem
	{
		union
		{
			K key2; // The sort key is of variable size
			byte[K.sizeof] key;
		}

		T data;
	}

	// Perform the radix sort.
	ulong count = array.length;
	Elem[] elem = new Elem[count];
	Elem[] elem_copy = new Elem[count];

	// Move everything into an array of structs for faster sorting.
	// This way we don't get all of the cache misses from using classes by reference.
	for (size_t i = 0; i < count; i++)
	{
		elem[i].key2 = getKey(array[i]);
		elem[i].data = array[i];
	}

	for (int k = 0; k < K.sizeof; k++)
	{
		// Build histograms
		uint[256] histogram;
		for (size_t i = 0; i < count; i++)
			histogram[cast(ubyte) elem[i].key[k]]++;

		// Count negative values
		uint neg;
		const bool last_pass = k == K.sizeof - 1;

		if (signed && last_pass)
			for (size_t i = 128; i < 256; i++)
				neg += histogram[i];

		// Build offset table
		uint[256] offset;
		offset[0] = neg;
		for (int i = 0; i < 127; i++)
			offset[i + 1] = offset[i] + histogram[i];
		if (neg) // only if last past and negative
			offset[128] = 0;
		else
			offset[128] = offset[127] + histogram[127];
		for (int i = 128; i < 255; i++)
			offset[i + 1] = offset[i] + histogram[i];

		// Fill destination buffer
		if (!isfloat || !last_pass || !neg) // sort as usual
			for (size_t i = 0; i < count; i++)
				elem_copy[offset[cast(ubyte) elem[i].key[k]]++] = elem[i];
		else // special case if floating point negative numbers exist
		{
				int negm1 = neg - 1;
				for (size_t i = 0; i < count; i++)
				{
					int value = elem[i].key[k];
					int index = offset[cast(ubyte) value]++;
					if (value >= 0)
						elem_copy[index] = elem[i];
					else // put all negative numbers in reverse order, since not represented /w 2's comp
						elem_copy[negm1 - index] = elem[i];
				}
			}

		// Only not swap arrays if last pass of an odd size (rare).
		if (!last_pass || K.sizeof % 2 == 0)
		{
			const Elem[] temp = elem_copy;
			elem_copy = elem;
			elem = temp;
		}
	}

	// Move everything back again
	// If odd number of passes, move data back to return buffer
	if (increasing)
	{
		static if (K.sizeof % 2 == 1)
			for (size_t i = 0; i < count; i++)
				array[i] = elem_copy[i].data;
		else
			for (size_t i = 0; i < count; i++)
				array[i] = elem[i].data;
	}
	else
	{
		static if (K.sizeof % 2 == 1)
			for (size_t i = 0; i < count; i++)
				array[count - i - 1] = elem_copy[i].data;
		else
			for (size_t i = 0; i < count; i++)
				array[count - i - 1] = elem[i].data;
	}
}

unittest
{
	// Sort ints
	int[] test2 = [3, 5, 2, 0, -1, 7, -4];
	test2.radixSort();
	assert(test2 == [-4, -1, 0, 2, 3, 5, 7]);
	test2.radixSort(false);
	assert(test2 == [7, 5, 3, 2, 0, -1, -4]);

	// Sort doubles
	double[] test3 = [3.0, 5, 2, 0, -1, 7, -4];
	test3.radixSort();
	assert(test3 == [-4.0, -1, 0, 2, 3, 5, 7]);

	// large array of +- floats
	import std.random: choice;

	float[] test4;
	for (int i = 0; i < 10_000; i++)
		test4 ~= choice([-1000, 1000]);
	test4.radixSort();
	import std.algorithm.sorting: isSorted;
	assert(test4.isSorted);
}
