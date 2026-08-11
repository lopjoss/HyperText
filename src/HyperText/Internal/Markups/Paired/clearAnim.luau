--!strict

local types = require("../../Types")
local util = require("../../Util")
local applyAnimation = require("../Helpers/ApplyAnimation")
local animAttrsConverters = require("../Helpers/AnimAttrsConverters")

local name : "clearAnim" = "clearAnim"
local type_ : "paired" = "paired"
local applyToImages : true = true
local applyOnClear : true = true
local module : types.dataModule<typeof(name), typeof(type_), typeof(applyToImages), typeof(applyOnClear)> = {
	type = type_,
	name = name,
	applyToImages = applyToImages,
	applyOnClear = applyOnClear,
	
	validate = function(markups : types.markups)
		return if markups.clearAnim.value == "inherit"
			then markups.anim.value and true or false
			else markups.clearAnim.value and true or false
	end,
	getClearingDuration = function(markups : types.markups)
		return if markups.clearAnim.value == "inherit"
			then markups.anim.attributes.dur
			else markups.clearAnim.attributes.dur
	end,
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry,
		spanData : types.onPrintMarkupSpanData,
		updater : {[string] : (dt : number) -> ()},
		onClear : boolean
	)
		if onClear and printerData.markups.clearAnim.value then
			local inherit = printerData.markups.clearAnim.value == "inherit"

			applyAnimation(
				obj,
				printerData,
				inherit and printerData.markups.anim.value or printerData.markups.clearAnim.value :: keyof<typeof(types.literal.animations)>,
				inherit and printerData.markups.anim.attributes or printerData.markups.clearAnim.attributes,
				inherit and printerData.markups.anim.valueAttributes or printerData.markups.clearAnim.valueAttributes,
				updater,
				onClear,
				name
			)
		end
	end,
	convert = function(str : string)
		local function convert(str : string) : keyof<typeof(types.literal.animations)>
			return util.stringToSingletonKey(types.literal.animations, str)
		end
		
		return util.stringToInheritable(str, convert)
	end,
	attributes = animAttrsConverters.attrsConverters,
	valueAttributes = animAttrsConverters.valueAttrsConverters,
	unrequired = true,
}

return module
