--!strict

local types = require("../../Types")
local util = require("../../Util")
local config = require("../../Config")
local emitImage = require("../Helpers/EmitImage")
local emitImgAttrsConverters = require("../Helpers/EmitImgAttrsConverters")
local flipbookEffect = require("../Helpers/FlipbookEffect")

local name : "fog" = "fog"
local type_ : "paired" = "paired"
local applyToImages : true = true
local module : types.dataModule<typeof(name), typeof(type_), typeof(applyToImages)> = {
	type = type_,
	name = name,
	applyToImages = applyToImages,

	onConstruction = function(
		obj : types.hyperTextClassObject,
		markups : types.markups
	)
		local i = 0
		for j, _ in pairs(markups.fog.stack) do
			if j > i then
				i = j
			end
		end

		local lastEntry = markups.fog.stack[i]
		
		if lastEntry and lastEntry.attributes.flipbookLayout then
			flipbookEffect.cacheImageSize("rbxassetid://" .. config.FOG_IMG_ID)
		end
	end,
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry,
		spanData : types.onPrintMarkupSpanData,
		updater : {[string] : (dt : number) -> ()}
	)
		for _, markups in pairs(printerData.markups.fog.stack) do
			if markups and markups.value then
				emitImage(
					obj,
					config.FOG_IMG_ID,
					printerData,
					printerData.markups,
					markups.attributes,
					updater
				)
			end
		end
	end,
	convert = util.stringToBoolean,
	attributes = emitImgAttrsConverters,
	valueAttributes = {},
	stackable = true,
}

return module
