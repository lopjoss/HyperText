--!strict

local HttpService = game:GetService("HttpService")

local types = require("../../Types")
local util = require("../../Util")

local name : "rainbow" = "rainbow"
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
		if printerData.markups.rainbow.value and obj._markupIndices and obj._contentFolder then
			local updaterId = HttpService:GenerateGUID()

			if not obj._markupIndices["rainbow"] then
				obj._markupIndices["rainbow"] = 0
			end

			local index = obj._markupIndices["rainbow"]

			updater[updaterId] = function(dt : number)
				debug.profilebegin("Rainbow Markup")

				local color = Color3.fromHSV(
					(
						os.clock() * printerData.markups.rainbow.attributes.freq -
							printerData.markups.rainbow.attributes.offset * index
					) % 1,
					1,
					1
				)

				if printerData.character:IsA("TextLabel") then
					printerData.character.TextColor3 = color
				else
					printerData.character.ImageColor3 = color
				end

				debug.profileend()
			end

			obj._contentFolder.Destroying:Once(function()
				updater[updaterId] = nil
			end)

			obj._markupIndices["rainbow"] += 1
		end
	end,
	convert = util.stringToBoolean,
	attributes = {
		freq = {
			convert = util.stringToNumber,
		},
		offset = {
			convert = util.stringToNumber,
		},
	},
	valueAttributes = {},
}

return module
