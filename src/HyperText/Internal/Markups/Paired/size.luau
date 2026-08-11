--!strict

local types = require("../../Types")
local util = require("../../Util")

local name : "size" = "size"
local type_ : "paired" = "paired"
local module : types.dataModule<typeof(name), typeof(type_)> = {
	type = type_,
	name = name,
	
	convert = function(value : string)
		return util.stringToNumber(value, 0, 100)
	end,
	attributes = {},
	valueAttributes = {},
}

return module
