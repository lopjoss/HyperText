--!strict

local types = require("../../Types")
local util = require("../../Util")
local applyTrans = require("../Helpers/ApplyTrans")

local name : "clearTransDur" = "clearTransDur"
local type_ : "paired" = "paired"
local applyToImages : true = true
local applyOnClear : true = true
local module : types.dataModule<typeof(name), typeof(type_), typeof(applyToImages), typeof(applyOnClear)> = {
	type = type_,
	name = name,
	applyToImages = applyToImages,
	applyOnClear = applyOnClear,
	
	validate = function(markups : types.markups)
		return true
	end,
	getClearingDuration = function(markups : types.markups)
		return markups.clearTransDur.value == "inherit"
			and (markups.trans.attributes.tweenDur or 0)
			or markups.clearTransDur.value :: number
	end,
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry,
		spanData : types.onPrintMarkupSpanData,
		updater : {[string] : (dt : number) -> ()},
		onClear : boolean
	)
		if onClear then
			applyTrans(
				obj,
				printerData,
				printerData.character:IsA("TextLabel") 
					and printerData.character.TextTransparency
					or printerData.character.ImageTransparency,
				1,
				true,
				printerData.markups.clearTransDur.value == "inherit"
					and (printerData.markups.trans.attributes.tweenDur or 0)
					or printerData.markups.clearTransDur.value :: number
			)
		end
	end,
	convert = function(str : string)
		return util.stringToInheritable(str, util.stringToNumber)
	end,
	attributes = {},
	valueAttributes = {},
}

return module
