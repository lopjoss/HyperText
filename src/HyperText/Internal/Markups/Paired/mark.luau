--!strict

local types = require("../../Types")
local util = require("../../Util")

local name : "mark" = "mark"
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
		if printerData.markups.mark.value then
			local container = #printerData.containers > 0 
				and printerData.containers[#printerData.containers] 
				or obj:_CreateRowEntryContainer(printerData, name)
			
			container.BackgroundColor3 = printerData.markups.mark.attributes.color
			container.BackgroundTransparency = printerData.markups.mark.attributes.trans
		end
	end,
	convert = util.stringToBoolean,
	attributes = {
		color = {
			convert = util.stringToColor3,
		},
		trans = {
			convert = util.stringToNumber,
		},
	},
	valueAttributes = {},
}

return module
