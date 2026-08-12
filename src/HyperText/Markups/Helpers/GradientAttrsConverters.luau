--!strict

local util = require("../../Util")
local types = require("../../Types")

local converters : types.gradientAttrsConverters = {
	colors = {
		convert = function(value)
			local colors = util.stringToColor3Pack(value)
			
			if #colors <= 18 then
				return colors
			else
				error("The number of colors in a gradient must be 18 or less", 0)
			end
		end,
	},
	rot = {
		convert = util.stringToNumber,
	},
	individual = {
		convert = util.stringToBoolean,
	},
	moveDir = {
		convert = function(value : string)
			return util.stringToSingletonKey(types.literal.horizontalDir, value)
		end,
	},
	moveSpeed = {
		convert = util.stringToNumber,
	},
	spacing = {
		convert = function(value : string)
			return util.stringToNumber(value, 0)
		end,
	}
}

return converters