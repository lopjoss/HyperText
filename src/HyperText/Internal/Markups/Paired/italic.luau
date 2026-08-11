--!strict

local types = require("../../Types")
local util = require("../../Util")

local name : "italic" = "italic"
local type_ : "paired" = "paired"
local module : types.dataModule<typeof(name), typeof(type_)> = {
	name = name,
	type = type_,
	
	convert = util.stringToBoolean,
	attributes = {},
	valueAttributes = {},
}

return module
