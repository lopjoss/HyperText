--!strict

local types = require("../../Types")
local util = require("../../Util")
local config = require("../../Config")

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
	convert = function(value : string)
		local success = pcall(function()
			return util.stringToNumber(value)
		end)
		if success then
			value = "rbxassetid://" .. tostring(value)
		end
		
		local default = util.deepCopy(config.DEFAULT_MARKUPS)
		local markups = util.getEmptyMarkups()
		markups.font.value = value
		
		util.mergeMarkups(default, markups)
		
		local textBounds = util.fetchTextBounds(value, default)
		
		if textBounds.Magnitude > 0 then
			return value
		else
			error("\"" .. value .. "\" is not a valid font", 0)
		end
	end,
	attributes = {},
	valueAttributes = {},
}

return module
