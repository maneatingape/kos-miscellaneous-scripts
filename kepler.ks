// This code solves Kepler's problem to determine the position of a body
// orbiting another parent body with classical Newtonian mechanics.
// Given the traditional 6 Keplerian orbital elements and a time offet,
// it returns Cartesian orbital state vectors (x,y,z components for position
// and velocity) where the origin is the center of mass of the parent body.
//
// Based on the steps in the memorandum
// "Keplerian Orbit Elements -> Cartesian State Vectors" by René Schwarz
// https://downloads.rene-schwarz.com/download/M001-Keplerian_Orbit_Elements_to_Cartesian_State_Vectors.pdf
//
// Key simplifying differences:
// * Eccentric anomaly is used to determine position, instead of true anomaly
// * kOS provides built in support for vector rotations, so we can compose
//   rotations without needing to use trignometric functions directly.
//
// The equations in this algorithm expect radians, so variants of the trignometric
// functions that use radians are imported from the "util.ks" file, namespaced with "trig".
//
// There is no practical reason to use this code in your own kOS scripts. The
// built-in "positionat" and "velocityat" functions in kOS do the same thing
// but are much faster, as they use KSP's own code.
// This script is written for fun and to understand orbital mechanics better.

@lazyglobal off.
runoncepath("kos-miscellaneous-scripts/util.ks").

// Parameters:
// body: Celestial body e.g. Kerbin, Duna, Mun
// t: Scalar time in seconds since epoch. e.g. time:seconds
global function orbitalStateVectors {
    parameter body, t.

    // Use the standard symbols for Keplerian elements (with one minor exception
    // as kOS is case-sensitive, omicron is used instead of lower case omega
    // to denote the argument of periapsis)
    local a is body:orbit:semimajoraxis.
    local b is body:orbit:semiminoraxis.
    local e is body:orbit:eccentricity.

    // These are specified in degrees, which is fine since they are only used
    // indirectly via the built-in kOS rotations that also expect degrees.
    local i is body:orbit:inclination.
    local omega is body:orbit:longitudeofascendingnode.
    local omicron is body:orbit:argumentofperiapsis.

    // Mean anomaly at epoch needs to be converted to radians as it is used
    // directly to calculate the mean anomaly.
    local mu is body:orbit:body:mu.
    local t0 is body:orbit:epoch.
    local m0 is body:orbit:meananomalyatepoch * constant:degtorad. // Sneaky gotcha here

    // Calculate mean motion
    local n is sqrt(mu / a ^ 3).
    // Calculate mean anomaly, clamping to the range [0, 2π]    
    local m is mod(m0 + n * (t - t0), 2 * constant:pi).
    if m < 0 set m to m + 2 * constant:pi.

    // We approximate the eccentric anomaly numerically, by using Newton's
    // method on Kepler's equation.
    local f is newtons_method@:bind(e, m).
    local ea is iterative_root_finder(m, f, 1e-5, 15).

    // In order to simplify things, we first solve orbital position and velocity
    // as a 2 dimensional problem in the plane of the orbiting body.
    // KSP uses a coordinate system where the y axis point straight up from the
    // Sun's north pole, so our solution lies on the x-z plane instead of the x-y plane.
    local x is a * (trig:cos(ea) - e).
    local z is b * trig:sin(ea).

    // Calculate orbital velocity
    local gamma is n / (1 - e * trig:cos(ea)).
    local dx is gamma * a * -trig:sin(ea).
    local dz is gamma * b * trig:cos(ea).

    // Now for the fun part. Using rotations we convert our 2D solution to
    // full fledged 3D coordinates by rotating to the correct inertial frame
    // (the plane of Kerbin's orbit essentially).
    local rotateToInertialFrame is r(0, -omega, 0) * r(-i, 0, 0) * r(0, -omicron, 0).
    // There's still one slight difference - our longitude of ascending node
    // reference angle is measured from the positive x axis, whereas in KSP the
    // reference angle seems to vary constantly in a way I can't figure out.
    // This final rotation adjusts to the in-game coordinate system.
    local rotateToPrimeMeridian is rotatefromto(v(1, 0, 0), solarprimevector).

    local position is v(x, 0, z) * rotateToInertialFrame * rotateToPrimeMeridian.
    local velocity is v(dx, 0, dz) * rotateToInertialFrame * rotateToPrimeMeridian.

    return lexicon("position", position, "velocity", velocity).
}

local function newtons_method {
    parameter e, m, ea.

    return (m + e * trig:sin(ea) - ea) / (e * trig:cos(ea) - 1).
}