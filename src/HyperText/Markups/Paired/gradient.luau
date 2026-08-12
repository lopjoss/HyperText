--!strict

local types = require("../../Types")
local util = require("../../Util")
local gradientAttrsConverters = require("../Helpers/GradientAttrsConverters")
local applyGradient = require("../Helpers/ApplyGradient")

local name : "gradient" = "gradient"
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
		if printerData.markups.gradient.value then
			if printerData.character:IsA("TextLabel") then
				printerData.character.TextColor3 = Color3.new(1, 1, 1)
			elseif printerData.character:IsA("ImageLabel") then
				printerData.character.ImageColor3 = Color3.new(1, 1, 1)
			end
			
			applyGradient(
				obj,
				printerData.character,
				spanData,
				printerData.markups.gradient.attributes,
				updater,
				"gradient"
			)
		end
	end,
	convert = util.stringToBoolean,
	attributes = gradientAttrsConverters,
	valueAttributes = {},
}

return module
