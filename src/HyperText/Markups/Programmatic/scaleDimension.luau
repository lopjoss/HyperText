--!strict

local types = require("../../Types")

local name : "scaleDimension" = "scaleDimension"
local type_ : "programmatic" = "programmatic"
local module : types.dataModule<typeof(name), typeof(type_)> = {
	type = type_,
	name = name,
	
	attributes = {},
	valueAttributes = {},
}

return module
