// Created for the "Around the World in 80 minutes" challenge.
// https://forum.kerbalspaceprogram.com/index.php?/topic/190374-around-the-world-in-80-minutes-original-done/
// Video of entry: https://vimeo.com/382757485
//
// This script flies a plane westwards at a constant height and speed,
// then lands it on the KSC runway. PID loops are used to control the plane's
// speed, direction and altitude.
//
// As the plane is intended to travel at faster than orbital velocity, it flips
// upside down once high enough. The craft then uses negative lift from its wings
// to counteract the excess radial acceleration.
//
// A nifty trick is that altitude is not controlled directly by a single PID loop
// but rather by using 2 nested PID loops, the inner loop controlling the vertical 
// speed of the craft. This allows quite precise control of altitude (the craft only
// overshoots by ~1%) and also allows tuning of maximum safe ascent and descent angles.
//
// Written for kOS version 1.2.0 or later

@lazyglobal off.

// Desired cruising altitude and speed
local altitudeSetpoint is 34700.
local airspeedSetpoint is 2670.

// Save runway location so vessel can navigate towards it during final approach
local kscRunway is ship:geoposition.

// Mutable vessel state 
local upsideDown is false.
local approachingKsc is false.
local stoppedAtKsc is false.

// Increase roll control threshold and response
set steeringmanager:rollcontrolanglerange to 45.
set steeringmanager:rollpid:kp to 1.6.

// Initialise PID controllers with constants tuned to a specific craft
local maxYawAngle is 4.
local minYawAngle is -4.
local latitudePid is pidloop(0.004, 0.000007, 0.0001, minYawAngle, maxYawAngle).
set latitudePid:setpoint to 0.

local maxVerticalSpeed is 450.
local minVerticalSpeed is -700.
local altitudePid is pidloop(0.25, 0.006, 1.6, minVerticalSpeed, maxVerticalSpeed).
set altitudePid:setpoint to altitudeSetpoint.

local maxPitchAngle is 17.
local minPitchAngle is -47.
local verticalSpeedPid is pidloop(0.5, 0.0002, 0.1, minPitchAngle, maxPitchAngle).
set verticalSpeedPid:setpoint to 0.

local maxThrottle is 1.
local minThrottle is -1.
local airspeedPid is pidloop(0.05, 0.006, 0.006, minThrottle, maxThrottle).
set airspeedPid:setpoint to airspeedSetpoint.

// Start
sas off.
brakes off.
stage.

//Create ascent triggers
when ship:altitude > 100 then gear off.
when ship:altitude > 20000 then upsideDown on.

// Create descent triggers once craft is far enough away from KSC
when kscRunway:distance > 200000 then {
    when kscRunway:distance < 180000 then upsideDown off.
    when kscRunway:distance < 134000 then {
        // Vesssel responds differently when lighter and in thicker atmosphere so tweak altitude PID loop constants
        set altitudePid to pidloop(0.5, 0.0002, 0.4, minVerticalSpeed, maxVerticalSpeed).
        set altitudePid:setpoint to kscRunway:terrainheight + 10.
        set airspeedPid:setpoint to 0.
    }
    when kscRunway:distance < 30000 then approachingKsc on.
    when kscRunway:distance < 6800 then {
        gear on.
        chutes on.
        brakes on.
    }
    when ship:groundspeed < 0.1 then stoppedAtKsc on.
}

// Main control loop that keeps vessel at desired heading, altitude and speed
until stoppedAtKsc {
    // Yaw
    local lateralDistance is kerbin:radius * constant:degtorad * (ship:geoposition:lat - kscRunway:lat).
    local compassDelta is latitudePid:update(time:seconds, lateralDistance).
    local desiredCompassAngle is choose 270 + compassDelta if approachingKsc else 270.
    // Pitch
    set verticalSpeedPid:setpoint to altitudePid:update(time:seconds, ship:altitude).
    local desiredPitchAngle is verticalSpeedPid:update(time:seconds, ship:verticalspeed).
    // Roll
    local desiredRollAngle is choose 180 if upsideDown else 0.
    set steering to heading(desiredCompassAngle, desiredPitchAngle, desiredRollAngle).
    // Throttle
    set throttle to throttle + airspeedPid:update(time:seconds, ship:airspeed).
}