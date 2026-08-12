--!strict

local types = require("../../Types")
local util = require("../../Util")
local appendFlipbookAttrsConverters = require("../Helpers/AppendFlipbookAttrsConverters")
local applyFlipbookEffect = require("../Helpers/ApplyFlipbookEffect")

local dataModules = util.getAllMarkupDataModules({"img"})
local attrsConverters : types.imgAttrsConverters = {
	plain = {
		convert = util.stringToBoolean,
	},
	height = {
		convert = function(value : string)
			return util.stringToNumber(value, 0)
		end,
	},
	aspectRatio = {
		convert = function(value : string)
			return util.stringToNumber(value, 0)
		end,
	},
	trans = {
		convert = util.stringToNumber,
		unrequired = true,
	},
	color = {
		convert = util.stringToColor3,
	},
}

local name : "img" = "img"
local type_ : "selfClosing" = "selfClosing"
local appendToCurrentWord : true = true
local module : types.dataModule<typeof(name), typeof(type_), nil, nil, typeof(appendToCurrentWord)> = {
	type = type_,
	name = name,
	appendToCurrentWord = appendToCurrentWord,

	getSize = function(obj : types.hyperTextClassObject, markups : types.markups)
		local height = markups.size.value * markups.img.attributes.height
		local width = height * markups.img.attributes.aspectRatio

		return Vector2.new(width, height)
	end,
	yieldFromIntervalOnPrint = true,
	onPrint_ = function(
		obj : types.hyperTextClassObject,
		markups : types.markups,
		index : number,
		row : Frame,
		updater : {[string] : (dt : number) -> ()}
	)
		local entry = obj._constructionData.rowEntries[index]

		local image = Instance.new("ImageLabel", row)
		image.Name = "Image_" .. markups.img.value
		image.BackgroundTransparency = 1
		image.Image = "rbxassetid://" .. markups.img.value
		image.ImageTransparency = markups.img.attributes.trans or markups.trans.value
		image.ImageColor3 = markups.img.attributes.color
		image.ZIndex = markups.ZIndex.value
		image.SizeConstraint = markups.sizeConstraint.value
		image:SetAttribute("Transparency", markups.img.attributes.trans or markups.trans.value)
		image.Size = UDim2.fromScale(
			(
				markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXY
					or markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXX
			) and entry.width / row.AbsoluteSize.X or entry.width / row.AbsoluteSize.Y,
			(
				markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXY
					or markups.sizeConstraint.value == Enum.SizeConstraint.RelativeYY
			) and entry.height / row.AbsoluteSize.Y or entry.height / row.AbsoluteSize.X
		)
		
		local printerRowEntry : types.printerDataRowEntry = {
			character = image,
			row = row,
			constructionDataRowEntry = entry,
			markups = markups,
			index = index,
			whitespace = false,

			containers = {},
			position = Vector2.zero,
			rotation = 0,
		}

		table.insert(obj._printerData.rowEntries, printerRowEntry)
		
		applyFlipbookEffect(
			image,
			markups.img.attributes,
			updater
		)
		
		if not markups.img.attributes.plain then
			for dataModule in util.iterateMarkupDataModulesByPrintPriority(dataModules) do
				if 
					dataModule.type == "paired"
					and dataModule.applyToImages
					and dataModule.onPrint
				then
					local spans = util.indexCaseInsensitive(
						obj._constructionData.spans,
						dataModule.name
					)
					local span : types.spanData

					for _, candidate in ipairs(spans) do
						if table.find(candidate.rowEntryIndices, index) then
							span = candidate

							break
						end
					end									

					local spanData : types.onPrintMarkupSpanData = {
						characterSize = Vector2.new(entry.width, entry.height),
						characterPosition = obj:_GetRowEntryPosition(index),
						spanSize = span.size,
						spanPosition = span.position,
					}
					
					dataModule.onPrint(
						obj,
						printerRowEntry,
						spanData,
						updater
					)
				end
			end
		end
	end,
	convert = util.stringToNumber,
	attributes = appendFlipbookAttrsConverters(
		attrsConverters
	),
	valueAttributes = {},
}

return module
