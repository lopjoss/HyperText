--!strict

local types = require("../../Types")
local util = require("../../Util")

local name : "underline" = "underline"
local type_ : "paired" = "paired"
local module : types.dataModule<typeof(name), typeof(type_)> = {
	type = type_,
	name = name,
	
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry<false>,
		spanData : types.onPrintMarkupSpanData,
		updater : {[string] : (dt : number) -> ()}
	)		
		if printerData.markups.underline.value then
			printerData.character.Text = "<u>" .. printerData.character.Text .. "</u>"
		end
	end,
	convert = util.stringToBoolean,
	attributes = {},
	valueAttributes = {},
}

return module
