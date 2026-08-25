--!strict

local types = require("../../Types")
local util = require("../../Util")
local emitImage = require("../Helpers/EmitImage")
local emitImgAttrsConverters = require("../Helpers/EmitImgAttrsConverters")
local flipbookEffect = require("../Helpers/FlipbookEffect")

local function cacheImageSize(markups : types.markups)
	for _, markups in pairs(markups.emitImg.stack) do
		if markups and flipbookEffect.shouldApplyFlipbookEffect(markups.attributes) then
			flipbookEffect.cacheImageSize("rbxassetid://" .. markups.value)
		end
	end
end

local name : "emitImg" = "emitImg"
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
		cacheImageSize(markups)
	end,
	onDefaultMarkupsChanged = cacheImageSize,
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry,
		spanData : types.onPrintMarkupSpanData,
		updater : {[string] : (dt : number) -> ()}
	)
		for _, markup in pairs(printerData.markups.emitImg.stack) do
			if markup then
				emitImage(
					obj,
					markup.value,
					printerData,
					printerData.markups,
					markup.attributes,
					updater
				)
			end
		end
	end,
	convert = util.stringToNumber,
	attributes = emitImgAttrsConverters,
	valueAttributes = {},
	stackable = true,
}

return module
