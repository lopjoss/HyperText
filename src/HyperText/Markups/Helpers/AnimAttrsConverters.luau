--!strict

local util = require("../../Util")
local types = require("../../Types")

local converters : types.animAttrsConverters = {
	dur = {
		validateDefaultValue = function(value : number)
			if value < 0 then
				error("Value must be more than or equal to 0", 0)
			end
		end,
		convert = function(value : string)
			return util.stringToNumber(value, 0)
		end,
	},
	loop = {
		convert = util.stringToBoolean,
	},
}

local valueAttrsConverters : types.animValueAttrsConverters = {
	slide = {
		dir = {
			convert = function(value)
				return util.stringToSingletonKey(types.literal.verticalDir, value)
			end,
		},
		offset = {
			convert = util.stringToNumber,
		},
		rot = {
			convert = util.stringToNumber,
		},
	},
	bounce = {
		dir = {
			convert = function(value)
				return util.stringToSingletonKey(types.literal.verticalDir, value)
			end,
		},
		offset = {
			convert = util.stringToNumber,
		},
		exp = {
			convert = util.stringToNumber,
		}
	},
	wiggle = {
		freq = {
			convert = util.stringToNumber,
		},
		offset = {
			convert = util.stringToNumber,
		},
		amp = {
			convert = util.stringToNumber,
		},
		rot = {
			convert = util.stringToBoolean,
		},
	},
	grow = {
		exp = {
			convert = util.stringToNumber,
		},
		startScale = {
			convert = util.stringToNumber,
		},
	}
}

return {
	attrsConverters = converters,
	valueAttrsConverters = valueAttrsConverters,
}