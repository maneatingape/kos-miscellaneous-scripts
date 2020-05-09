// Created for the "Race Around The World" challenge
// https://forum.kerbalspaceprogram.com/index.php?/topic/192495-race-around-the-world/
// Video of entry: https://vimeo.com/406980090
//
// Derived from the 'v1" script of the same name, the key differences are:
// * Tuned vertical speed PID constants to match different craft dynamics
// * Eliminated the yaw PID loop, instead using a simple heading
// * Some extra logic to drop empty stages
//
// Written for kOS version 1.2.0 or later

@lazyglobal off.

// Desired cruising altitude and speed
local altitudeSetpoint is 35000.
local airspeedSetpoint is 3600.

// Save KSC runway location so vessel can navigate towards it during final approach
local kscRunway is latlng(-0.0485, -74.7255).

// Mutable vessel state
local upsideDown is true. 
local approachingKsc is false.
local stoppedAtKsc is false.

// Increase roll control threshold and response
set steeringmanager:rollcontrolanglerange to 45.

// Initialise PID controllers with constants tuned to a specific craft
local maxVerticalSpeed is 450.
local minVerticalSpeed is -1200.
local altitudePid is pidloop(0.15, 0.00002, 0.5, minVerticalSpeed, maxVerticalSpeed).
set altitudePid:setpoint to altitudeSetpoint.

local maxPitchAngle is 45.
local minPitchAngle is -30.
local verticalSpeedPid is pidloop(0.5, 0.0002, 0.1, minPitchAngle, maxPitchAngle).
set verticalSpeedPid:setpoint to 0.

local maxThrottle is 1.
local minThrottle is -1.
local airspeedPid is pidloop(0.05, 0.006, 0.006, minThrottle, maxThrottle).
set airspeedPid:setpoint to airspeedSetpoint.

// Trigger staging when empty
when stage:resourceslex:liquidfuel:amount = 0 then {
    stage.
    when stage:resourceslex:liquidfuel:amount = 0 then {
        stage.
        when ship:airspeed > airspeedSetpoint then stage.
    }
}

// Create descent triggers once craft is far enough away from KSC
when kscRunway:distance > 200000 then {
    when kscRunway:distance < 130000 then {
        set altitudePid:setpoint to kscRunway:terrainheight - 10.
        set verticalSpeedPid:minoutput to -45.
    }
    when kscRunway:distance < 30000 then {
        upsideDown off.
        approachingKsc on.
    }
    when kscRunway:distance < 4000 then {
        gear on.
        brakes on.
    }
    when ship:groundspeed < 0.1 then stoppedAtKsc on.
}

// Main control loop that keeps vessel at desired heading, altitude and speed
until stoppedAtKsc {
    // Yaw
    local desiredCompassAngle is choose kscRunway:heading if approachingKsc else 270.
    // Pitch
    set verticalSpeedPid:setpoint to altitudePid:update(time:seconds, ship:altitude).
    local desiredPitchAngle is verticalSpeedPid:update(time:seconds, ship:verticalspeed).
    // Roll
    local desiredRollAngle is choose 180 if upsideDown else 0.    
    // Update controls
    set steering to heading(desiredCompassAngle, desiredPitchAngle, desiredRollAngle).
    set throttle to throttle + airspeedPid:update(time:seconds, ship:airspeed).
}