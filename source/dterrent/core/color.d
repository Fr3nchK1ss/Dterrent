/**
	Authors: Poggel / Fr3nchK1ss
	Copyright: Contact Fr3nchK1ss

	TODO: Replace by a Color dub package
 */

module dterrent.core.color;

import std.algorithm.comparison;
import std.string;
import std.format;
import core.bitop;
import dterrent.core.math;


/**
 * A struct used to represent a color.
 *
 * Colors are represented in RGBA format.
 * Note that uints and dwords store the bytes in reverse (little endian),
 * so Color(0x6633ff00).hex == "00FF3366"
 * All Colors default to transparent black.
 *
 * Example:
 * --------------------------------
 * uint  red  = Color("red").ui;
 * vec4 blue = Color("0000FF").vec4;
 * writefln(Color("blue")); 	 // outputs "0000FF00"
 * writefln(Color(0x00FF0000));  // outputs "0000FF00"
 * --------------------------------
 *
 */
struct Color
{
	private static const real frac = 1.0f / 255;

	static const Color BLACK = {0, 0, 0, 255};
	static const Color BLUE = {0, 0, 255, 255};
	static const Color BROWN = {165, 42, 42, 255};
	static const Color CYAN = {0, 255, 255, 255};
	static const Color GOLD = {255, 215, 0, 255};
	static const Color GRAY = {128, 128, 128, 255};
	static const Color GREY = {128, 128, 128, 255};
	static const Color GREEN = {0, 128, 0, 255};
	static const Color INDIGO = {75, 0, 130, 255};
	static const Color MAGENTA = {255, 0, 255, 255};
	static const Color ORANGE = {255, 165, 0, 255};
	static const Color PINK = {255, 184, 195, 255};
	static const Color PURPLE = {128, 0, 128, 255};
	static const Color RED = {255, 0, 0, 255};
	static const Color TRANSPARENT = {0, 0, 0, 0};
	static const Color VIOLET = {238, 130, 238, 255};
	static const Color WHITE = {255, 255, 255, 255};
	static const Color YELLOW = {255, 255, 0, 255};

	union  // this union breaks CTFE with this struct
	{
		struct
		{
			ubyte r, g, b, a;
		} /// Access each color component: TODO: test to ensure order is correct.
		ubyte[4] ub; /// Get the Color as an array of ubyte
		uint ui; /// Get the Color as a uint
	}

	/**
	 * Initialize from 3 or 4 values (red, green, blue, alpha).
	 * Integer types rante from 0 to 255 and floating point types range from 0 to 1. */
	static Color opCall(int r, int g, int b, int a = 255)
	{
		Color res;
		res.r = cast(ubyte) r;
		res.g = cast(ubyte) g;
		res.b = cast(ubyte) b;
		res.a = cast(ubyte) a;
		return res;
	}

	unittest
	{
		assert(Color(0x99663300) == Color(0, 0x33, 0x66, 0x99));
	}

	static Color opCall(float r, float g, float b, float a = 1) /// ditto
	{
		Color res;
		res.r = cast(ubyte) clamp(r * 255, 0.0f, 255.0f);
		res.g = cast(ubyte) clamp(g * 255, 0.0f, 255.0f);
		res.b = cast(ubyte) clamp(b * 255, 0.0f, 255.0f);
		res.a = cast(ubyte) clamp(a * 255, 0.0f, 255.0f);
		return res;
	}

	static Color opCall(ubyte[] v) /// ditto
	{
		Color res;
		for (int i = 0; i < max(v.length, 4); i++)
			res.ub[i] = cast(ubyte)(v[i]);
		if (v.length < 4)
			res.a = 255;
		return res;
	}

	static Color opCall(int[] v) /// ditto
	{
		Color res;
		for (int i = 0; i < max(v.length, 4); i++)
			res.ub[i] = cast(ubyte)(v[i]);
		if (v.length < 4)
			res.a = 255;
		return res;
	}

	static Color opCall(float[] f) /// ditto
	{
		Color res;
		for (int i = 0; i < min(f.length, 4); i++)
			res.ub[i] = cast(ubyte) clamp(f[i] * 255, 0.0f, 255.0f);
		if (f.length < 4)
			res.a = 255;
		return res;
	}

	static Color opCall(vec3 v) /// ditto
	{	return Color(v.x, v.y, v.z);
	}
	static Color opCall(vec4 v) /// ditto
	{	return Color(v.x, v.y, v.z, v.w);
	}


	/**
	 * Initialize from a uint, string hexadecimal value, or english color name.
	 * Strings. can be a 6 or 8 digit hexadecimal or an English color name.
	 * Black, blue, brown, cyan, gold, gray/grey, green, indigo, magenta, orange,
	 * pink, purple, red, transparent, violet, white, and yellow are supported.
	 * See: <a href="http://www.w3schools.com/css/css_colornames.asp">CSS color names</a>*/
	static Color opCall(uint ui)
	{
		Color res;
		res.ui = ui;
		return res;
	}

	static Color opCall(string s)
	{
		// An english color name
		if (s.length <= 20)
		{
			string lower = toLower(s);
			switch (lower[0 .. s.length])
			{
			case "black":
				return Color.BLACK;
			case "blue":
				return Color.BLUE;
			case "brown":
				return Color.BROWN;
			case "cyan":
				return Color.CYAN;
			case "gold":
				return Color.GOLD;
			case "gray":
			case "grey":
				return Color.GRAY;
			case "green":
				return Color.GREEN;
			case "indigo":
				return Color.INDIGO;
			case "magenta":
				return Color.MAGENTA;
			case "orange":
				return Color.ORANGE;
			case "pink":
				return Color.PINK;
			case "purple":
				return Color.PURPLE;
			case "red":
				return Color.RED;
			case "transparent":
				return Color.TRANSPARENT;
			case "violet":
				return Color.VIOLET;
			case "white":
				return Color.WHITE;
			case "yellow":
				return Color.YELLOW;
			default:
				break;
			}
		}

		//	Allow hex colors to start with hash.
		if (s[0] == '#')
			s = s[1 .. 7];

		// handle 3 and 4-digit color codes
		char[8] color;
		if (s.length <= 4)
		{
			color[0 .. 2] = s[0];
			color[2 .. 4] = s[1];
			color[4 .. 6] = s[2];
			if (s.length == 4)
				color[6 .. 8] = s[3];
			else
				color[6 .. 8] = 'F';
		}
		else if (s.length == 6)
		{
			color[0 .. 6] = s[0 .. 6];
			color[6 .. 8] = 'F';
		}
		else if (s.length >= 8)
			color[0 .. 8] = s[0 .. 8];
		//else
		//	throw new YageException("Could not parse color %s", string);

		// Convert string one char at a time.
		Color result;
		int digit;
		foreach (int i, char h; color)
		{
			if (i >= 8)
				break;

			digit = 0; // will be 0-15
			if (47 < h && h < 58) // 0-9
				digit = (h - 48);
			else if (64 < h && h < 71) // A-F
				digit = (h - 55);
			else if (96 < h && h < 103) // a-f
				digit = (h - 87);
			//	else
			//		throw new YageException("Invalid character '%s' in '%s' for Color()", h, string);
			result.ub[i / 2] += digit * (15 * ((i + 1) % 2) + 1); // gets low or high nibble
		}
		return result;
	}

	/**
	 * Assign from a uint, string hexadecimal value, or english color name.
	 * Strings. can be a 6 or 8 digit hexadecimal or an English color name.
	 * Black, blue, brown, cyan, gold, gray/grey, green, indigo, magenta, orange,
	 * pink, purple, red, transparent, violet, white, and yellow are supported.
	 * See: <a href="http://www.w3schools.com/css/css_colornames.asp">CSS color names</a>*/
	Color opAssign(string string)
	{
		ui = Color(string).ui;
		return this;
	}

	Color opAssign(uint value) /// ditto
	{
		ui = value;
		return this;
	}

	/// Allow casting color to a uint.
	uint opCast()
	{
		return ui;
	}

	/// Get the Color as an array of float.
	float[] f()
	{
		float[4] res;
		res[0] = r * frac;
		res[1] = g * frac;
		res[2] = b * frac;
		res[3] = a * frac;
		return res.dup;
	}

	void f(float[4] result) /// ditto
	{
		result[0] = r * frac;
		result[1] = g * frac;
		result[2] = b * frac;
		result[3] = a * frac;
	}

	/// Get the Color as a Vector
	vec3 toVec3()
	{
		vec3 res;
		res.x = r * frac;
		res.y = g * frac;
		res.z = b * frac;
		return res;
	}

	vec4 toVec4() /// ditto
	{
		vec4 res;
		res.x = r * frac;
		res.y = g * frac;
		res.z = b * frac;
		res.w = a * frac;
		return res;
	}

	/**
	 * Get the color as a string.
	 * Params:
	 * lower = return lower case hexadecimal digits*/
	string hex(bool lower = false, char[] lookaside = null)
	{
		if (lower)
			return format("%.8x", bswap(ui));
		return format("%.8X", bswap(ui));
	}
	/// ditto
	string toString()
	{
		return "#" ~ hex();
	}

	unittest
	{
		assert(Color.sizeof == 4);

		// Test initializers
		assert(Color([0, 102, 51, 255]).hex == "006633FF");
		assert(Color([0.0f, 0.4f, 0.2f, 1.0f]).hex == "006633FF");
		assert(Color(0xFF336600).hex == "006633FF");

		// Test converters
		assert(Color("abcdef97").hex == "ABCDEF97");
		assert(Color("006633FF").toVec4 == vec4(0.0f, 0.4f, 0.2f, 1.0f));
		assert(Color("006633FF").ui == 0xFF336600);
	}
}
