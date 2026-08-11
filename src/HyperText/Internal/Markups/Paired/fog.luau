--!strict

local types = require("../../Types")
local util = require("../../Util")
local config = require("../../Config")
local emitImage = require("../Helpers/EmitImage")
local emitImgAttrsConverters = require("../Helpers/EmitImgAttrsConverters")

local name : "fog" = "fog"
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
		if printerData.markups.fog.value then
			emitImage(
				obj,
				config.FOG_IMG_ID,
				printerData,
				printerData.markups,
				printerData.markups.fog.attributes,
				updater
			)
		end
	end,
	convert = util.stringToBoolean,
	attributes = emitImgAttrsConverters,
	valueAttributes = {},
}

return module
