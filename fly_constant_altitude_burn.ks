// Created for the "Tylo Lowest twr Lander Challenge"
// https://forum.kerbalspaceprogram.com/index.php?/topic/203028-tylo-lowest-twr-lander-challenge/
//
// Video of script in action:
// https://vimeo.com/590568684
//
// Flies a constant altitude landing burn in 3 phases. Assumes a single stage
// and that the craft is in an initial stable circular orbit. Can be tweaked to
// support multiple stages.
// 
// Phase 1:
// * Locks the craft heading to a retrograde direction
// * Uses the target longitude from the "find_highest_point_on_equator" script
//   and the offset angle from the "simulate_constant_alitude_burn" script to
//   wait for the precise moment to start the burn
//
// Phase 2:
// * Creates a PID controller to maintain zero vertical velocity
// * Holds the craft at exactly the picth angle needed until horizontal ground
//   velocity drops below a 10 m/s threshold
//
// Phase 3:
// * Switches to a constant velocity descent for the final few metres
// * Slows the craft to 5 m/s as most parts can survive this impact
//
// Written for kOS version 1.3.2 or later

@lazyglobal off.

// ****************************************
// Phase 1
// ****************************************

local desiredCompassAngle is 270.
local desiredPitchAngle is 0.
local desiredRollAngle is 0.
lock steering to heading(desiredCompassAngle, desiredPitchAngle, desiredRollAngle).

print "Waiting until longitude threshold".
local target_longitude is -73.7927.
local offset_longitude is 41.4.
wait until ship:geoposition:lng > target_longitude - offset_longitude.

// ****************************************
// Phase 2
// ****************************************

print "Starting constant altitude burn".
set throttle to 1.

// Tweak PID constants to your specific craft
local kp is 10.
local ki is 6.
local kd is 6.
local minPitchAngle is -90.
local maxPitchAngle is 90.

local pid is pidloop(kp, ki, kd, minPitchAngle, maxPitchAngle).
set pid:setpoint to 0.

until ship:groundspeed < 10 {
    set desiredPitchAngle to pid:update(time:seconds, ship:verticalspeed).
    wait 0.
}

// ****************************************
// Phase 3
// ****************************************

print "Switching to constant velocity descent".
set throttle to 0.

// Pause until the retrograde vector is close the craft's orientation to prevent
// a large sudden swing in direction.
wait until vang(ship:facing:vector, -ship:velocity:surface) < 10.

// Tweak PID constants to your specific craft
set kp to 0.25.
set ki to 0.15.
set kd to 0.15.
local minThrottle is -1.
local maxThrottle is 1.

set pid to pidloop(kp, ki, kd, minThrottle, maxThrottle).
set pid:setpoint to -5.

until ship:status = "landed" {
    // There's a built-in "srfretrograde" direction but this loses roll control
    // at low speeds. Handle this manually to keep the craft oriented predictably.
    local y is vdot(-ship:velocity:surface, ship:up:vector:normalized).
    local x is vdot(-ship:velocity:surface, vcrs(ship:north:vector, ship:up:vector):normalized).
    set desiredPitchAngle to arctan2(y, x).

    // Only thrust if the craft is close to the desired orientation to prevent
    // a runwaway sequence of over-corrections.
    if vang(ship:facing:vector, -ship:velocity:surface) < 10 {
        set throttle to throttle + pid:update(time:seconds, -ship:velocity:surface:mag).
    }
    else {
        set throttle to 0.
    }

    wait 0.
}

// ****************************************
// Cleanup
// ****************************************

unlock steering.
set throttle to 0.

sas on.
gear on.
brakes on.