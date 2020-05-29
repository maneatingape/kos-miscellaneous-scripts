// Very simple example of using nested PID controllers to maintain the height
// of a craft at a constant altitude.
//
// Written for kOS version 1.2.0 or later.

@lazyglobal off.

lock steering to Up.
stage.

local heightPid is pidloop(0.25, 0.0001, 0.05, -15, 15).
set heightPid:setpoint to 200.

local speedPid is pidloop(0.01, 0.006, 0.006, -1, 1).
set speedPid:setpoint to 0.

until false {
    set speedPid:setpoint to heightPid:update(time:seconds, ship:altitude).
    set throttle to throttle + speedPid:update(time:seconds, ship:verticalspeed).                   
}