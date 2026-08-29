--!strict

local types = require("../../Types")
local util = require("../../Util")
local config = require("../../Config")
local emitImage = require("../Helpers/EmitImage")
local emitImgAttrsConverters = require("../Helpers/EmitImgAttrsConverters")

local name : "shiny" = "shiny"
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
		util.cacheStackableImageMarkupLastEntry(markups.shiny.stack :: index<types.stack<types.markupIndexable>, "stack">)
	end,
	onDefaultMarkupsChanged = function(markups : types.markups)
		util.fullyCacheStackableImageMarkup(markups.shiny :: types.stack<types.markupIndexable>)
	end,
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry,
		spanData : {types.onPrintMarkupSpanData},
		updater : {[string] : (dt : number) -> ()}
	)
		for _, markups in pairs(printerData.markups.shiny.stack) do
			if markups and markups.value then
				emitImage(
					obj,
					config.SHINY_IMG_ID,
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
