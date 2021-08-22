// Created for the "Tylo Lowest twr Lander Challenge"
// https://forum.kerbalspaceprogram.com/index.php?/topic/203028-tylo-lowest-twr-lander-challenge/
//
// Simulates a constant altitude landing burn using Euler integration. Results
// match almost exactly with those obtained in game.
//
// Use this to predict initial and final TWR, burn duration and delta-v needed
// for craft designs without having to actually fly the mission.  Also predicts
// the number of degrees longitude needed to start burning ahead of time so that
// the landing can target a precise location. 
//
// This script can be run on *any* craft in *any* location. There is no need to
// run it on the actual Tylo landing craft. Assumes a single stage, but can be
// tweaked to support multiple stages.
//
// Written for kOS version 1.3.2 or later

@lazyglobal off.

// Overclock CPU
set config:ipu to 2000.

// KSP has 50 physics "ticks" per second, so each tick lasts 20 milliseconds.
local delta_time is 0.02.

// Planet details
local planet is tylo.
local mu is planet:mu.
local surface_ground_speed is (2 * constant:pi * planet:radius) / planet:rotationperiod.

// Orbit details (meters above sea level) 
local initial_altitude is 9100.

// Ship details
local thrust is 120. // Kilonewtons
local isp is 800. // Seconds
local initial_mass is 19.488. // Tons
local initial_twr is thrust / (initial_mass * constant:g0).

// Simulate constant altitude burn.
print "Initial TWR: " + round(initial_twr, 2).

// Radial velcocity is zero and tranverse velocity
// is assumed from a circular orbit at "initial_altitude".
local current_mass is initial_mass.
local current_distance is planet:radius + initial_altitude.
local current_radial is 0.
local current_transerve is sqrt(mu / current_distance).
local delta_mass is -thrust / (isp * constant:g0).

// Measure total time and deltav
local total_time is 0.
local total_deltav is 0.
local total_angle is 0.
local finished is false.

until finished {
    // Decelerate at full throttle for entire burn.
    local acceleration is thrust / current_mass.
    // Take planet's rotation into account.
    local relative_ground_speed is current_transerve - surface_ground_speed.
    // If acceleration exceeds remaining velocity then we're done
    set finished to acceleration > v(current_radial, relative_ground_speed, 0):mag.
    // Calculate how many degrees longitude the craft has traversed
    local delta_angle is constant:radtodeg * current_transerve / current_distance.

    // Apply acceleration due to gravity
    local delta_radial_gravity is -mu / (current_distance ^ 2) + (current_transerve ^ 2) / current_distance.
    local delta_transverse_gravity is -current_transerve * current_radial / current_distance.

    // Craft angle attempts to keep radial velocity at zero.
    local alpha is arcsin(delta_radial_gravity / acceleration).

    // Apply acceleration due to engine thrust
    local delta_radial is delta_radial_gravity - acceleration * sin(alpha).
    local delta_transverse is delta_transverse_gravity - acceleration * cos(alpha).

    // Euler integration that seems to match what KSP does under the hood.
    set current_mass to current_mass + delta_time * delta_mass.
    set current_distance to current_distance + delta_time * current_radial.
    set current_radial to current_radial + delta_time * delta_radial.
    set current_transerve to current_transerve + delta_time * delta_transverse.

    // Increment totals
    set total_time to total_time + delta_time.
    set total_deltav to total_deltav + delta_time * acceleration.
    set total_angle to total_angle + delta_time * delta_angle.
}

local final_twr is thrust / (current_mass * constant:g0).

print "Total time: " + round(total_time).
print "Total Delta-V: " + round(total_deltav).
print "Total Angle: " + round(total_angle, 2).
print "Final TWR: " + round(final_twr, 2).