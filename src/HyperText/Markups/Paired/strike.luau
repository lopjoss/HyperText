--!strict

local types = require("../../Types")
local util = require("../../Util")

local name : "strike" = "strike"
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
		if printerData.markups.strike.value then
			printerData.character.Text = "<s>" .. printerData.character.Text .. "</s>"
		end
	end,
	convert = util.stringToBoolean,
	attributes = {},
	valueAttributes = {},
}

return module
