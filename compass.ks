// Functions that convert from raw ship vectors to compass values that match the in-game navball.
//
// Namespaced for convenience, to use simply call the lexicon members e.g. compass:pitch()
//
// Written for kOS version 1.2.0 or later

global compass is lexicon(
	"pitch", {
		return 90 - vang(ship:up:vector, ship:facing:vector).
	},
	"yaw", {
		local yawFromNorth is vang(ship:north:vector, ship:facing:vector).
		local yawFromEast is vang(vcrs(ship:north:vector, ship:up:vector), ship:facing:vector).
		return choose yawFromNorth if yawFromEast > 90 else 360 - yawFromNorth.
	},
	"roll", {
		local x is vdot(ship:up:vector, ship:facing:topvector).
	    local y is vdot(vcrs(ship:up:vector, ship:facing:vector), ship:facing:topvector).
	    return arctan2(y, x).
	},
	"pitch_rate", {
		return -constant:radtodeg * ship:angularvel:y.
	},
	"yaw_rate", {
		return constant:radtodeg * ship:angularvel:z.
	},
	"roll_rate", {
		return -constant:radtodeg * ship:angularvel:x.
	}
}