--!strict

local types = require("../../Types")
local util = require("../../Util")

local name : "size" = "size"
local type_ : "paired" = "paired"
local module : types.dataModule<typeof(name), typeof(type_)> = {
	type = type_,
	name = name,
	
	validateDefaultValue = function(value : number)
		if value < 0 or value > 100 then
			error("Value must be between 0-100", 0)
		end
	end,
	convert = function(value : string)
		return util.stringToNumber(value, 0, 100)
	end,
	attributes = {},
	valueAttributes = {},
}

return module
