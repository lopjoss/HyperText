--!strict

local types = require("../../Types")
local util = require("../../Util")

local function validateFont(value : string) : string
	local fetschingSchema = util.getTextboundsCacheFetschinSchema(
		"a",
		value,
		1,
		Enum.FontWeight.Regular,
		Enum.FontStyle.Normal
	)

	local textBounds = util.textBoundsCache:Get(fetschingSchema)
	
	if textBounds.Magnitude > 0 then
		return value
	else
		error("\"" .. value .. "\" is not a valid font", 0)
	end
end

local name : "font" = "font"
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
		printerData.character.FontFace = typeof(printerData.markups.font.value) == "string"
			and Font.new(
				printerData.markups.font.value,
				printerData.markups.weight.value,
				printerData.markups.italic.value and Enum.FontStyle.Italic or Enum.FontStyle.Normal
			)
			or Font.fromId(
				printerData.markups.font.value :: number,
				printerData.markups.weight.value,
				printerData.markups.italic.value and Enum.FontStyle.Italic or Enum.FontStyle.Normal
			)
	end,
	validateDefaultValue = function(value : number | string)
		local fontId : string

		if type(value) == "number" then
			fontId = "rbxassetid://" .. tostring(value)
		else
			fontId = value
		end

		validateFont(fontId)
	end,
	convert = function(value : string)
		local success = pcall(function()
			return util.stringToNumber(value)
		end)
		if success then
			value = "rbxassetid://" .. tostring(value)
		end
		
		return validateFont(value)
	end,
	attributes = {},
	valueAttributes = {},
}

return module
