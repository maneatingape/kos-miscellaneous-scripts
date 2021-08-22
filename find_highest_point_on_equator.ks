// Created for the "Tylo Lowest twr Lander Challenge"
// https://forum.kerbalspaceprogram.com/index.php?/topic/203028-tylo-lowest-twr-lander-challenge/
//
// Searches points on the equator of a celestial body at regular 100 meter
// intervals in order to find the highest terrrain elevation.
//
// Written for kOS version 1.3.2 or later

@lazyglobal off.

// Overclock CPU
set config:ipu to 2000.

local planet is tylo.
// Longitude range is -180 to 180 degrees
local lng is -180.
// Print progress in 1 degree increments
local progress is lng.
// Search in 100 meter steps
local step is (360 * 100) / (2 * constant:pi * planet:radius).

local max_height is 0.
local max_lng is 0.

until lng > 180 {
	local height is planet:geopositionlatlng(0, lng):terrainheight.

	if (height > max_height) {
		set max_height to height.
		set max_lng to lng.
	}

	if (round(lng) > progress) {
		set progress to round(lng).
		print progress.
	}

	set lng to lng + step.
}

print max_height. // 9074
print max_lng. // -73.7927