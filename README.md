# Description

Collection of miscellaneous [kOS](https://ksp-kos.github.io/KOS/) scripts for the game [Kerbal Space Program](https://www.kerbalspaceprogram.com/), covering diverse topics such as [PID controllers](https://en.wikipedia.org/wiki/PID_controller), [orbital mechanics](https://en.wikipedia.org/wiki/Orbital_elements) and [vector math](https://en.wikipedia.org/wiki/Euclidean_vector).

Published under the permissive MIT license, so feel free to use the content of the scripts either directly or as inspiration.

# Scripts

## Low TWR Tylo Lander Challenge

Three related scripts to support an entry to a [low TWR Tylo lander forum challenge](https://forum.kerbalspaceprogram.com/index.php?/topic/203028-tylo-lowest-twr-lander-challenge/). [Video of entry](https://vimeo.com/590568684)

### [find_highest_point_on_equator.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/find_highest_point_on_equator.ks)

Searches points on the equator of a celestial body at regular 100 meter intervals in order to find the highest terrrain elevation.

### [simulate_constant_altitude_burn.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/simulate_constant_altitude_burn.ks)

Simulates a constant altitude landing burn using Euler integration. Results match almost exactly with those obtained in game.

Use this to predict initial and final TWR, burn duration and delta-v needed for craft designs without having to actually fly the mission.  Also predicts the number of degrees longitude needed to start burning ahead of time so that the landing can target a precise location. 

This script can be run on *any* craft in *any* location. There is no need to run it on the actual Tylo landing craft. Assumes a single stage, but can be tweaked to support multiple stages.

### [fly_constant_altitude_burn.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/fly_constant_altitude_burn.ks)

Flies a constant altitude landing burn in 3 phases. Assumes a single stage and that the craft is in an initial stable circular orbit. Can be tweaked to support multiple stages.

Phase 1:
* Locks the craft heading to a retrograde direction.
* Uses the target longitude from the `find_highest_point_on_equator` script and the offset angle from the `simulate_constant_alitude_burn` script to wait for the precise moment to start the burn.

Phase 2:
* Creates a PID controller to maintain zero vertical velocity.
* Holds the craft at exactly the picth angle needed until horizontal ground velocity drops below a 10 m/s threshold.

Phase 3:
* Switches to a constant velocity descent for the final few metres.
* Slows the craft to 5 m/s as most parts can survive this impact.

## What is the most efficient way to de-orbit and land?

### [compare.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/compare.ks)

Script to compare the deltav efficiency of suicide burns versus constant altitude burns when landing on vacuum planets. Simulates landing trajectory using differential equations to estimate deltav requirements based on craft with different TWR. Used to answer [a related question](https://forum.kerbalspaceprogram.com/index.php?/topic/201813-what-is-the-most-efficient-way-to-deorbitland/) on the KSP forum.

## Around the World Challenge

### [around_v1.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/around_v1.ks)

Created for the [Around the World in 80 minutes](https://forum.kerbalspaceprogram.com/index.php?/topic/190374-around-the-world-in-80-minutes-original-done/) challenge. [Video of entry](https://vimeo.com/382757485)

This script flies a plane westwards at a constant height and speed, then lands it on the KSC runway. PID loops are used to control the plane's speed, direction and altitude.

As the plane is intended to travel at faster than orbital velocity, it flips upside down once high enough. The craft then uses negative lift from its wings to counteract the excess radial acceleration.

A nifty trick is that altitude is not controlled directly by a single PID loop but rather by using 2 nested PID loops, the inner loop controlling the vertical speed of the craft. This allows quite precise control of altitude (the craft only overshoots by ~1%) and also allows tuning of maximum safe ascent and descent angles.

### [around_v2.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/around_v2.ks)

Created for the [Race Around The World](https://forum.kerbalspaceprogram.com/index.php?/topic/192495-race-around-the-world/) challenge. [Video of entry](https://vimeo.com/406980090)

Derived from the `around_v1` script, the key differences are:
* Tuned vertical speed PID constants to match different craft dynamics
* Eliminated the yaw PID loop, instead using a simple heading
* Some extra logic to drop empty stages

## Other Scripts

### [kepler.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/kepler.ks)

Solves Kepler's problem to determine the position of a body orbiting another parent body with classical Newtonian mechanics. Given the traditional 6 Keplerian orbital elements and a time offet, it returns Cartesian orbital state vectors (x,y,z components for position and velocity) where the origin is the center of mass of the parent body.

Based on the steps in the memorandum ["Keplerian Orbit Elements -> Cartesian State Vectors"](https://downloads.rene-schwarz.com/download/M001-Keplerian_Orbit_Elements_to_Cartesian_State_Vectors.pdf) by René Schwarz

Key simplifying differences:
* Eccentric anomaly is used to determine position, instead of true anomaly
* kOS provides built in support for vector rotations, so we can compose rotations without needing to use trignometric functions directly.
* The equations in this algorithm expect radians, so variants of the trignometric functions that use radians are imported from the `util.ks` file, namespaced with `trig`.

*There is no practical reason to use this code in your own kOS scripts.* The built-in `positionat` and `velocityat` functions in kOS do the same thing but are much faster, as they use KSP's own code. This script is written for fun and to understand orbital mechanics better.

### [util.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/util.ks)

Utility functions called by the `kepler.ks` script:
* Regular trignometric functions that use radians instead of degrees along with hyperbolic variants.
* Helper function to run iterative root finding algorithsm such as Newton's method.

### [compass.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/compass.ks)

Functions that convert from raw ship vectors to compass values that match the in-game navball. Namespaced for convenience, to use simply call the lexicon members e.g. `compass:pitch()`

### [hover.ks](https://github.com/maneatingape/kos-miscellaneous-scripts/blob/master/hover.ks)

Very simple example of using nested PID controllers to maintain the height of a craft at a constant altitude.