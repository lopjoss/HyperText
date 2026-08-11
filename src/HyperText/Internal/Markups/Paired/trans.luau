--!strict

local types = require("../../Types")
local util = require("../../Util")
local applyTrans = require("../Helpers/ApplyTrans")

local name : "trans" = "trans"
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
		applyTrans(
			obj,
			printerData,
			printerData.markups.trans.attributes.tweenFrom,
			printerData.character:IsA("TextLabel") 
				and printerData.markups.trans.value 
				or printerData.character:GetAttribute("Transparency") :: number,
			false,
			printerData.markups.trans.attributes.tweenDur
		)
	end,
	convert = util.stringToNumber,
	attributes = {
		tweenDur = {
			convert = util.stringToNumber,
			unrequired = true
		},
		tweenFrom = {
			convert = util.stringToNumber
		},
		loopTween = {
			convert = util.stringToBoolean,
		},
	},
	valueAttributes = {},
}

return module
