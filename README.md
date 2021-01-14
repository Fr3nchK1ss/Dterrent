# Dterrent ![D](https://github.com/ludo456/Dterrent/workflows/D/badge.svg)

Minimalist game engine in D (Digital Mars). Intended for Linux.

Dterrent tries to salvage the defunct yage3D project, at least its architecture, ideally replacing most of the former components with D2 features or Dub packages. In this aspect, it is a proof of concept for a 3D engine built upon community-made "building bricks", without reinventing the wheel.

*Note: ludo456 was a contributor to the original yage3D project.*

## Current libs changes

* derelict		-> bindbc (bindings to SDL2)
* tango.core.Thread	-> core.thread.osthread
* yage.system.log	-> std.experimental.logger, console-logger
* yage.core.math       -> gl3n
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
