--!strict

local types = require("../../Types")
local util = require("../../Util")
local appendFlipbookAttrsConverters = require("../Helpers/AppendFlipbookAttrsConverters")
local flipbookEffect = require("../Helpers/FlipbookEffect")

local attrsConverters : types.bgImgAttrsConverters = {
	heightMul = {
		validateDefaultValue = function(value : number)
			if value < 0 then
				error("Value must be more than or equal to 0", 0)
			end
		end,
		convert = function(value : string)
			return util.stringToNumber(value, 0)
		end,
		unrequired = true,
	},
	widthMul = {
		validateDefaultValue = function(value : number)
			if value < 0 then
				error("Value must be more than or equal to 0", 0)
			end
		end,
		convert = function(value : string)
			return util.stringToNumber(value, 0)
		end,
		unrequired = true,
	},
	trans = {
		convert = util.stringToNumber,
	},
	color = {
		convert = util.stringToColor3,
	},
}

local name : "bgImg" = "bgImg"
local type_ : "paired" = "paired"
local applyToImages : true = true
local module : types.dataModule<typeof(name), typeof(type_), typeof(applyToImages)> = {
	type = type_,
	name = name,
	applyToImages = applyToImages,
	alwaysApplyToImages = true,
	
	onConstruction = function(
		obj : types.hyperTextClassObject,
		markups : types.markups
	)
		util.cacheStackableImageMarkupLastEntry(markups.bgImg.stack :: index<types.stack<types.markupIndexable>, "stack">)
	end,
	onDefaultMarkupsChanged = function(markups : types.markups)
		util.fullyCacheStackableImageMarkup(markups.bgImg :: types.stack<types.markupIndexable>)
	end,
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry<false>,
		spanData : {types.onPrintMarkupSpanData},
		updater : {[string] : (dt : number) -> ()}
	)
		if obj._contentFolder then
			local index = 1
	
			for _, markups in pairs(printerData.markups.bgImg.stack) do
				if markups then
					local spanData = spanData[index]
					local firstVisibleRowEntryIndex : number
	
					for _, index in ipairs(spanData.rowEntryIndices) do
						local constructionData = obj._constructionData.rowEntries[index]
						
						if Vector2.new(constructionData.width, constructionData.height).Magnitude > 0 then
							firstVisibleRowEntryIndex = index
							
							break
						end
					end
	
					if printerData.index == firstVisibleRowEntryIndex then
						local imageURI = typeof(markups.value) == "string"
							and markups.value
							or "rbxassetid://" .. markups.value
	
						local parent: Folder = obj._contentFolder:FindFirstChild("BackgroundImages") :: Folder?
							or Instance.new("Folder", obj._contentFolder)
						parent.Name = "BackgroundImages"
	
						local widthMul = markups.attributes.widthMul or 1
						local heightMul = markups.attributes.heightMul or 1
						local verticalAlignment = printerData.markups.verticalAlignment.value
						local constructionSize = obj:GetConstructionSize() :: Vector2
						local containerSize = Vector2.new(
							obj._automaticSizeX and obj:_GetProportionalSize(constructionSize.X) or obj._container.AbsoluteSize.X,
							obj._automaticSizeY and obj:_GetProportionalSize(constructionSize.Y) or obj._container.AbsoluteSize.Y
						)
						local contentHeight = constructionSize.Y
						local verticalOffset = verticalAlignment == Enum.VerticalAlignment.Top
							and 0
							or verticalAlignment == Enum.VerticalAlignment.Center
							and (containerSize.Y - contentHeight) / 2
							or containerSize.Y - contentHeight
	
						local image = Instance.new("ImageLabel", parent)
						image.AnchorPoint = Vector2.new(.5, .5)
						image.Name = "Image_" .. imageURI
						image.BackgroundTransparency = 1
						image.Image = imageURI
						image.ImageTransparency = markups.attributes.trans
						image.ImageColor3 = markups.attributes.color
						image.ZIndex = printerData.markups.ZIndex.value - 1
						image.SizeConstraint = printerData.markups.sizeConstraint.value
						image.Size = UDim2.fromScale(
							((
								printerData.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXY
								or printerData.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXX
							)
									and spanData.spanSize.X / containerSize.X
								or spanData.spanSize.X / containerSize.Y) * widthMul,
							((
								printerData.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXY
								or printerData.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeYY
							)
									and spanData.spanSize.Y / containerSize.Y
								or spanData.spanSize.Y / containerSize.X) * heightMul
						)
						image.Position = UDim2.fromScale(
							(spanData.spanPosition.X + spanData.spanSize.X / 2) / containerSize.X,
							(
								verticalOffset
								+ spanData.spanPosition.Y
								+ spanData.spanSize.Y / 2
							) / containerSize.Y
						)
	
						flipbookEffect.applyFlipbookEffect(
							image,
							markups.attributes,
							updater
						)
					end
					
					index += 1
				end
			end
		end
	end,
	convert = util.stringToURI,
	attributes = appendFlipbookAttrsConverters(attrsConverters),
	valueAttributes = {},
	stackable = true,
}

return module
