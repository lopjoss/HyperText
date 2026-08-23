--!strict

local types = require("../../Types")
local util = require("../../Util")
local emitImage = require("../Helpers/EmitImage")
local emitImgAttrsConverters = require("../Helpers/EmitImgAttrsConverters")
local FlipbookEffect = require("../Helpers/FlipbookEffect")

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
		local i = 0
		for j, _ in pairs(markups.emitImg.stack) do
			if j > i then
				i = j
			end
		end

		local lastEntry = markups.emitImg.stack[i]
		
		if lastEntry and lastEntry.attributes.flipbookLayout then
			FlipbookEffect.cacheImageSize("rbxassetid://" .. lastEntry.value)
		end
	end,
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
