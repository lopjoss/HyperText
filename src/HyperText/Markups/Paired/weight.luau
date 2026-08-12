--!strict

local types = require("../../Types")
local util = require("../../Util")

local name : "weight" = "weight"
local type_ : "paired" = "paired"
local module : types.dataModule<typeof(name), typeof(type_)> = {
	name = name,
	type = type_,
	
	convert = util.stringToFontWeight,
	attributes = {},
	valueAttributes = {},
}

return module
