--!strict

local util = require("../../Util")
local types = require("../../Types")
local appendFlipbookAttrsConverters = require("./AppendFlipbookAttrsConverters")

local base : types.emitImageAttrsConverters = {
	color = {
		convert = util.stringToColor3,
	},
	aspectRatio = {
		convert = util.stringToNumber,
	},
	rate = {
		convert = util.stringToNumber,
	},
	chance = {
		convert = util.stringToNumber,
	},
	lifetime = {
		convert = util.stringToNumberRange,
	},
	velX = {
		convert = util.stringToNumberRange,
	},
	velY = {
		convert = util.stringToNumberRange,
	},
	rotVel = {
		convert = util.stringToNumberRange,
	},
	accelX = {
		convert = util.stringToNumberRange,
	},
	accelY = {
		convert = util.stringToNumberRange,
	},
	startTrans = {
		convert = util.stringToNumberRange,
	},
	endTrans = {
		convert = util.stringToNumberRange,
	},
	startSize = {
		convert = util.stringToNumberRange,
	},
	endSize = {
		convert = util.stringToNumberRange,
	},
	startPosX = {
		convert = util.stringToNumberRange,
	},
	startPosY = {
		convert = util.stringToNumberRange,
	},
	startRot = {
		convert = util.stringToNumberRange,
	},
	applyTransform = {
		convert = util.stringToBoolean,
	}
}

return appendFlipbookAttrsConverters(
	base
)