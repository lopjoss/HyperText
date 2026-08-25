--!strict

local util = require("../../Util")
local types = require("../../Types")

local converters : types.gradientAttrsConverters = {
	colors = {
		validateDefaultValue = function(value : {Color3})
			if #value < 1 or #value > 18 then
				error("The number of colors in a gradient must be between 1 and 18", 0)
			end
		end,
		convert = function(value)
			local colors = util.stringToColor3Pack(value)
			
			if #colors >= 1 and #colors <= 18 then
				return colors
			else
				error("The number of colors in a gradient must be between 1 and 18", 0)
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
		validateDefaultValue = function(value : number)
			if value < 0 then
				error("Value must be more than or equal to 0", 0)
			end
		end,
		convert = function(value : string)
			return util.stringToNumber(value, 0)
		end,
	}
}

return converters