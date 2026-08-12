--!strict

local util = require("../../Util")
local types = require("../../Types")

local converters : types.flipbookAttrsConverts = {
	flipbookLayout = {
		convert = util.stringToVector2,
		unrequired = true,
	},
	flipbookFreq = {
		convert = util.stringToNumber,
	},
	flipbookLoop = {
		convert = util.stringToBoolean,
	},
	flipbookReverse = {
		convert = util.stringToBoolean,
	}
}

return function<T>(base : T) : T & types.flipbookAttrsConverts
	for key, value in pairs(converters :: {[string] : any}) do
		(base :: any)[key] = value
	end
	
	return base :: T & types.flipbookAttrsConverts
end