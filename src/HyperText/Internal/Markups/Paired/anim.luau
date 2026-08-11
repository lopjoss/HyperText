--!strict

local types = require("../../Types")
local util = require("../../Util")
local applyAnimation = require("../Helpers/ApplyAnimation")
local animAttrsConverters = require("../Helpers/AnimAttrsConverters")

local name : "anim" = "anim"
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
		if printerData.markups.anim.value then
			applyAnimation(
				obj,
				printerData,
				printerData.markups.anim.value,
				printerData.markups.anim.attributes,
				printerData.markups.anim.valueAttributes,
				updater,
				false,
				name
			)
		end
	end,
	convert = function(value)
		return util.stringToSingletonKey(types.literal.animations, value)
	end,
	attributes = animAttrsConverters.attrsConverters,
	valueAttributes = animAttrsConverters.valueAttrsConverters,
	unrequired = true,
}

return module
