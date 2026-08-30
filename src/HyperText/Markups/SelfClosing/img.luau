--!strict

local types = require("../../Types")
local util = require("../../Util")
local appendFlipbookAttrsConverters = require("../Helpers/AppendFlipbookAttrsConverters")
local flipbookEffect = require("../Helpers/FlipbookEffect")

local attrsConverters : types.imgAttrsConverters = {
	plain = {
		convert = util.stringToBoolean,
	},
	height = {
		validateDefaultValue = function(value : number)
			if value < 0 then
				error("Value must be more than or equal to 0", 0)
			end
		end,
		convert = function(value : string)
			return util.stringToNumber(value, 0)
		end,
	},
	aspectRatio = {
		validateDefaultValue = function(value : number)
			if value < 0 then
				error("Value must be more than or equal to 0", 0)
			end
		end,
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
	yieldFromIntervalOnPrint = true,

	getSize = function(obj : types.hyperTextClassObject, markups : types.markups)
		local height = markups.size.value * markups.img.attributes.height
		local width = height * markups.img.attributes.aspectRatio

		return Vector2.new(width, height)
	end,
	onConstruction = function(
		obj : types.hyperTextClassObject,
		markups : types.markups
	)
		util.cacheImageMarkup(markups.img :: types.markupIndexable)
	end,
	onDefaultMarkupsChanged = function(markups : types.markups)
		util.cacheImageMarkup(markups.img :: types.markupIndexable)
	end,
	onPrint_ = function(
		obj : types.hyperTextClassObject,
		markups : types.markups,
		index : number,
		row : Frame,
		updater : {[string] : (dt : number) -> ()}
	)
		local imageURI = typeof(markups.img.value) == "string"
			and markups.img.value
			or "rbxassetid://" .. markups.img.value
		local entry = obj._constructionData.rowEntries[index]

		local image = Instance.new("ImageLabel", row)
		image.Name = "Image_" .. imageURI
		image.BackgroundTransparency = 1
		image.Image = imageURI
		image.LayoutOrder = index
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
		
		flipbookEffect.applyFlipbookEffect(
			image,
			markups.img.attributes,
			updater
		)
		
		util.fireAllDataModuleOnPrints(
			obj,
			printerRowEntry,
			updater,
			{"img"},
			function(dataModule)
				return dataModule.type == "paired" and
					(if not markups.img.attributes.plain then
						dataModule.applyToImages
					else
						dataModule.alwaysApplyToImages)
					and true or false
			end
		)
	end,
	convert = util.stringToURI,
	attributes = appendFlipbookAttrsConverters(
		attrsConverters
	),
	valueAttributes = {},
}

return module
