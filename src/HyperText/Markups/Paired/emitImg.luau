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

	onConstruction = function(
		obj : types.hyperTextClassObject,
		markups : types.markups
	)
		util.cacheStackableImageMarkupLastEntry(markups.emitImg.stack :: index<types.stack<types.markupIndexable>, "stack">)
	end,
	onDefaultMarkupsChanged = function(markups : types.markups)
		util.fullyCacheStackableImageMarkup(markups.emitImg :: types.stack<types.markupIndexable>)
	end,
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry,
		spanData : {types.onPrintMarkupSpanData},
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
	convert = util.stringToURI,
	attributes = emitImgAttrsConverters,
	valueAttributes = {},
	stackable = true,
}

return module
