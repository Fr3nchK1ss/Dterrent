/**
	Authors: Poggel / Fr3nchK1ss
	Copyright: proprietary / contact dev

	This class is a rewrite of yage3D EngineObject class.
 */
module dterrent.core.arraybuilder;
import dterrent.system.logger;

import std.format;

/**
 * Behaves the same as built-in arrays, except about 6x faster with concatenation at the expense of the base pointer
 * being 4 system words instead of two (16 instead of 8 bytes on a 32-bit system).
 * Internally, it's implemented similarly to java's StringBuffer.
 * Use .data to access the underlying array.
 * ArrayBuilder is a value type, so all copies point to the same data, unless either:
 * - A slice is taken and then appended to.
 * - .dup() is called. 
 */
struct ArrayBuilder(T)
{
	alias AT = ArrayBuilder!(T);

	private T[] array; // array.length is capacity
	private size_t size; // current used size
	size_t reserve; // capacity will never be less than this size, takes effect after the next grow.

	///
	static AT opCall()
	{
		AT result;
		return result;
	}

	///
	static AT opCall(T[] elems)
	{
		AT result;
		result.array = elems;
		result.size = elems.length;
		return result;
	}

	///
	size_t capacity()
	{
		return array.length;
	}

	///
	T[] data()
	{
		return array[0 .. size];
	}

	///
	void dispose()
	{
		array.destroy();
	}

	///
	AT dup()
	{
		AT result;
		result.array = array.dup;
		result.size = size;
		return result;
	}

	///
	size_t length()
	{
		return size;
	}

	///
	void length(size_t l)
	{
		size = l;
		grow();
	}

	///
	int opApply(int delegate(ref T) dg)
	{
		int result = 0;
		for (int i = 0; i < size; i++)
		{
			result = dg(array[i]);
			if (result)
				break;
		}
		return result;
	}

	///
	AT opAssign(T[] elem)
	{
		array = elem;
		size = elem.length;
		return this;
	}

	///
	AT opCat(T elem)
	{
		return AT(array ~ elem);
	}

	AT opCat(T[] elem) /// ditto
	{
		return AT(array ~ elem);
	}

	AT opCat(AT elem) /// ditto
	{
		return AT(array ~ elem.array);
	}

	///
	void opOpAssign(string op)(T elem) if (op == "~")
	{
		size++;
		grow();
		array[size - 1] = elem;
	}

	/// temporary until opCatAssign always works
	T* append(T elem)
	{
		size++;
		grow();
		array[size - 1] = elem;
		return &array[size - 1];
	}

	void opCatAssign(T[] elem) /// ditto
	{
		size_t old_size = size; // same as push
		size += elem.length;
		grow();
		array[old_size .. size] = elem[0 .. $];
	}

	void opOpAssign(string op)(AT elem) if (op == "~")
	{
		size_t old_size = size;
		size += elem.array.length;
		grow();
		array[old_size .. size] = elem.array[0 .. $];
	}

	/// TODO: This returns a copy, so a[i].b = 3; doesn't work!!
	T* opIndex(size_t i)
	{
		assert(i < size, format("array index %s out of bounds 0..%s", i, size));
		return &array[i];
	}

	T opIndexAssign(T val, size_t i) /// ditto
	{
		assert(i < size, format("array index %s out of bounds 0..%s", i, size));
		return array[i] = val;
	}

	///
	AT opSlice() // overloads a[], a slice of the entire array
	{
		return AT(array[0 .. size]);
	}

	AT opSlice(size_t start, size_t end) /// ditto
	{
		assert(end <= size, format("array index %s out of bounds 0..%s", end, size));
		return AT(array[start .. end]); // overloads a[i .. j]
	}

	///
	AT opSliceAssign(T v) // overloads a[] = v
	{
		array[0 .. size] = v;
		return this;
	}

	///
	AT opSliceAssign(T v, size_t start, size_t end) // overloads a[i .. j] = v
	{
		assert(end <= size);
		array[start .. end] = v;
		return this;
	}

	void reserveAndClear()
	{
		if (reserve < array.length)
			reserve = array.length;
		size = 0;
	}

	///
	T* ptr()
	{
		return array.ptr;
	}

	/// Remove an element, replacing it with one from the end.
	void remove(size_t index)
	{
		array[index] = array[size - 1];
		size--;
	}

	///
	import std.algorithm.mutation: reverse;

	AT reverse()
	{
		array.reverse;
		return this;
	}

	/**
	 * Add and remove elements from the array, in-place.
	 * Params:
	 *     index =
	 *     remove = Number of elements to remove, including and after index (can be 0)
	 *     insert = Element to insert before index, after elements have been removed. */
	void splice(size_t index, size_t remove, T[] insert...)
	{
		// Split member 'array' in two parts
		T[] firstPart = array[0 .. index];
		T[] secondPart = array[index + remove .. $];
		length(firstPart.length + insert.length + secondPart.length);

		array = firstPart ~ insert ~ secondPart;
	}

	///
	string toString() const
	{
		return ""; // TODO this needs to output the data. swritef(data);
	}

	private void grow()
	{
		if (array.length < size || size * 4 < array.length)
		{
			ulong new_size = size * 2 + 1;
			if (new_size < reserve)
				new_size = reserve;
			array.length = new_size;
		}
	}
}

unittest
{
	{
		struct A
		{
			int x, y;
		}

		A a;
		ArrayBuilder!(A) array;
		array ~= a;
		array[0].x = 3;
		assert(array[0].x == 3);
	}
	{ // Test slice and append; ensure copy on append is performed
		immutable test = ArrayBuilder!(int)([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
		auto original = ArrayBuilder!(int)([0, 1, 2, 3]);
		auto s = original[1 .. 3];
		assert(s[0] == original[1]); // compares pointer
		s ~= 12;
		assert(*s[0] == 1);
		assert(*s[1] == 2);
		assert(*s[2] == 12);
		assert(*original[3] == 3);
	}
	{ // Test splice
		auto test = ArrayBuilder!(int)([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
		test.splice(3, 3);
		assert(test.data == [0, 1, 2, 6, 7, 8, 9]);
		test.splice(3, 0, [3, 4, 5]);
		assert(test.data == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
		test.splice(0, 3, [2, 1, 0]);
		assert(test.data == [2, 1, 0, 3, 4, 5, 6, 7, 8, 9]);
		test.splice(test.length, 0, 10);
		assert(test.data == [2, 1, 0, 3, 4, 5, 6, 7, 8, 9, 10]);

		auto test2 = ArrayBuilder!(int)();
		test2.splice(0, 0, 1);
		assert(test2.data == [1]);
	}
	{
		trace("*** ArrayBuilder Concatenation benchmark ***");
		import std.datetime.stopwatch : benchmark, Duration;
		import std.array : appender;

		void concat_withStd()
		{
			int[] array;
			for (int j = 0; j < 1000; j++)
				array ~= j;
		}

		void concat_withStdReserve()
		{
			int[] array;
			array.reserve(1000);
			for (int j = 0; j < 1000; j++)
				array ~= j;
		}

		void concat_withStdLength()
		{
			int[] array;
			array.length = 1000;
			for (int j = 0; j < 1000; j++)
				array[j] = j;
		}

		void concat_withAppenderReserve()
		{
			auto array = appender!(int[]);
			//trace ("array is ", array);
			array.reserve(1000);
			for (int j = 0; j < 1000; j++)
				array ~= j;
		}

		void concat_withArrayBuilder()
		{
			ArrayBuilder!(int) array;
			for (int j = 0; j < 1000; j++)
				array ~= j;
		}

		auto r = benchmark!(concat_withStd,
			concat_withStdReserve,
			concat_withStdLength,
			concat_withAppenderReserve,
			concat_withArrayBuilder)(10_000);
		Duration bench1 = r[0];
		Duration bench2 = r[1];
		Duration bench3 = r[2];
		Duration bench4 = r[3];
		Duration bench5 = r[4];

		tracef("with std: %s", bench1);
		tracef("with stdReserve: %s", bench2);
		tracef("with stdLength: %s", bench3);
		tracef("with AppenderReserve: %s", bench4);
		tracef("with Arraybuilder: %s \n", bench5);

	}
}
