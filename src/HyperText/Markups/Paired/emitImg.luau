--!strict

local types = require("../../Types")
local util = require("../../Util")
local emitImage = require("../Helpers/EmitImage")
local emitImgAttrsConverters = require("../Helpers/EmitImgAttrsConverters")

local name : "emitImg" = "emitImg"
local type_ : "paired" = "paired"
local applyToImages : true = true
local module : types.dataModule<typeof(name), typeof(type_), typeof(applyToImages)> = {
	type = type_,
	name = name,
	applyToImages = applyToImages,

	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry,
		spanData : types.onPrintMarkupSpanData,
		updater : {[string] : (dt : number) -> ()}
	)
		for _, markups in ipairs(printerData.markups.emitImg) do
			if markups.value then
				emitImage(
					obj,
					markups.value,
					printerData,
					printerData.markups,
					markups.attributes,
					updater
				)
			end
		end
	end,
	convert = util.stringToNumber,
	attributes = emitImgAttrsConverters,
	valueAttributes = {},
	unrequired = true,
	stackable = true,
}

return module
