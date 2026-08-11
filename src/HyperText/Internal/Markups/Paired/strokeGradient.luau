--!strict

local types = require("../../Types")
local util = require("../../Util")
local gradientAttrsConverters = require("../Helpers/GradientAttrsConverters")
local applyGradient = require("../Helpers/ApplyGradient")

local name : "strokeGradient" = "strokeGradient"
local type_ : "paired" = "paired"
local module : types.dataModule<typeof(name), typeof(type_)> = {
	type = type_,
	name = name,

	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry<false>,
		spanData : types.onPrintMarkupSpanData,
		updater : {[string] : (dt : number) -> ()}
	)
		if printerData.markups.strokeGradient.value and obj._renderTraceback then
			local stroke = printerData.character:FindFirstChildWhichIsA("UIStroke") :: UIStroke?
			
			if stroke then
				stroke.Color = Color3.new(1, 1, 1)
				
				applyGradient(
					obj,
					stroke,
					spanData,
					printerData.markups.strokeGradient.attributes,
					updater,
					"strokeGradient"
				)
			else
				warn(
					"Tried applying the strokeGradient markup but no stroke was found. Did you forget to use the stroke markup?\n" 
						.. obj._renderTraceback
				)
			end
		end
	end,
	convert = util.stringToBoolean,
	attributes = gradientAttrsConverters,
	valueAttributes = {},
}

return module