// Script to compare the deltav efficiency of suicide burns versus
// constant altitude burns when landing on vacuum planets.
//
// Differential equations obtained from the paper:
// "Optimal Trajectory Planning for the Apollo MoonLanding: Descent, Ascent, and Aborts"
// Author: Duncan Millers
// Available from: https://www.aerospades.com/uploads/3/7/3/2/37325123/apollo_moon.pdf
//
// Simplifying assumptions:
// (1) Craft is in circular prograde orbit with zero degrees inclination.
// (2) Craft has a single stage with enough deltav to complete landing.
// (3) Planet is perfectly smooth with sea level radius (no mountains or
//     terrain to get in the way).

@lazyglobal off.
// Overclock CPU
set config:ipu to 2000.

// KSP has 50 physics "ticks" per second, so each tick lasts 20 milliseconds.
local delta_time is 0.02.

// Planet details
local planet is tylo.
local mu is planet:mu.
local surface_gravity is mu / planet:radius ^ 2.
local surface_ground_speed is (2 * constant:pi * planet:radius) / planet:rotationperiod.

// Hohmann descent orbit 
local initial_altitude is 30000. // Meters above sea level 
local initial_periapsis is planet:radius. // Land at sea level
local initial_apoapsis is planet:radius + initial_altitude.

// Ship details
local thrust is 60. // Kilonewtons
local isp is 320. // Seconds
local initial_mass is 2.5. // Tons
local initial_twr is thrust / (initial_mass * surface_gravity).

// Simulate constant altitude burn.
output("=========================================").
output("Initial TWR: " + initial_twr).

local result is simulate("constant_altitude_burn").
output("Constant Altitude Burn").
output("  Total time: " + round(result:time, 2)).
output("  Total Delta-V: " + round(result:deltav)).
output("  Final TWR: " + round(result:final_twr, 2)).

// Iterate suicide burns adjusting initial periapsis altitude each time.
// Ten iterations is usually enough to converge on Tylo.
// Lighter bodies or higher TWR needs fewer iterations.
local count is 0.

until count = 10 {
    set result to simulate("suicide_burn").

    output("Suicide Burn Round " + (count + 1)).
    output("  Total time: " + round(result:time, 2)).
    output("  Total Delta-V: " + round(result:deltav)).
    output("  Radial Offset: " + round(result:offset)).

    set initial_periapsis to initial_periapsis + result:offset.
    set count to count + 1.
}

local function simulate {
    parameter strategy.

    // Start landing burn exactly at periapsis. Radial velcocity is zero and
    // tranverse velocity is given by vis-viva equation.
    local current_mass is initial_mass.
    local current_distance is initial_periapsis.
    local current_radial is 0.
    local current_transerve is sqrt(mu * (2 / initial_apoapsis - 2 / (initial_periapsis + initial_apoapsis))).
    local delta_mass is -thrust / (isp * constant:g0).

    // Measure total time and deltav
    local total_time is 0.
    local total_deltav is 0.
    local finished is false.

    until finished {
        // Decelerate at full throttle for entire burn.
        local acceleration is thrust / current_mass.
        // Take planet's rotation into account.
        local relative_ground_speed is current_transerve - surface_ground_speed.
        // If acceleration exceeds remaining velocity then we're done
        set finished to acceleration > v(current_radial, relative_ground_speed, 0):mag.

        // Apply acceleration due to gravity
        local delta_radial_gravity is -mu / (current_distance ^ 2) + (current_transerve ^ 2) / current_distance.
        local delta_transverse_gravity is -current_transerve * current_radial / current_distance.

        local alpha is "undefined".
        if strategy = "suicide_burn" {
            // Craft angle follows surface retrograde
            set alpha to arctan2(current_radial, relative_ground_speed).
        }
        if strategy = "constant_altitude_burn" {
            // Craft angle attempts to keep radial velocity at zero.
            set alpha to arcsin(delta_radial_gravity / acceleration).
        }

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
    }

    local offset is planet:radius - current_distance.
    local final_twr is thrust / (current_mass * surface_gravity).

    return lex("time", total_time, "deltav", total_deltav, "offset", offset, "final_twr", final_twr).
}

local function output {
    parameter message.

    print message.
    log message to "output.txt".
}