# Dterrent ![D](https://github.com/Fr3nchK1ss/Dterrent/workflows/D/badge.svg)

DISCONTINUED, read POST-MORTEM

Minimalist game engine in D (Dlang). Intended for Linux.

Dterrent tries to salvage the defunct yage3D project by JoeCoder, at least its architecture, ideally replacing most of the former components with D2 features or Dub packages. In this aspect, it is a proof of concept for a 3D engine built upon Dlang community-made "building bricks", without reinventing the wheel.

*Note: Fr3nchK1ss was an original contributor to the yage3D project.*

## Current libs changes

* derelict		-> bindbc (bindings to SDL2)
* tango.core.Thread	-> core.thread.osthread
* yage.system.log	-> std.experimental.logger, console-logger
* yage.core.math (math, vector, quatrn...)  -> gl3n
* yage.core.array   -> std.array, std.algorithm
* ...


# How to run

## Dependencies
You need to install:
* libsdl2	`sudo apt install libsdl2`
* libsdl2-image `sudo apt install libsdl2-image`
* libopenal	`sudo apt install libopenal1`

## Build and Run
* `dub build` to build the engine library
* `cd demo1; dub run` to test the engine.
