--!strict

local HttpService = game:GetService("HttpService")

local types = require("../../Types")

type gradientAttrs = types.gradientAttrs

type gradientItem = {
	gradient : UIGradient,
	startAlpha : number,
	endAlpha : number,
}

type gradientGroup = {
	colors : {Color3},
	spacing : number,
	items : {gradientItem},
	updaterId : string?,
}

local renderGradientGroups : {[string] : {[string] : gradientGroup}} = {}
local cleanupConnections : {[string] : RBXScriptConnection} = {}

local function getColorAtAlpha(colors : {Color3}, alpha : number) : Color3
	local colorCount = #colors

	if colorCount == 1 then
		return colors[1]
	end

	local scaledAlpha = math.clamp(alpha, 0, 1) * (colorCount - 1)
	local lowerIndex = math.floor(scaledAlpha) + 1
	local upperIndex = math.min(lowerIndex + 1, colorCount)
	local lowerColor = colors[lowerIndex]

	if lowerIndex == upperIndex then
		return lowerColor
	end

	return lowerColor:Lerp(colors[upperIndex], scaledAlpha - math.floor(scaledAlpha))
end

local function createColorSequence(colors : {Color3}) : ColorSequence
	local colorCount = #colors

	if colorCount == 1 then
		return ColorSequence.new(colors[1])
	end

	local keypoints : {ColorSequenceKeypoint} = {}
	local maxIndex = colorCount - 1

	for i, color in ipairs(colors) do
		keypoints[#keypoints + 1] = ColorSequenceKeypoint.new((i - 1) / maxIndex, color)
	end

	return ColorSequence.new(keypoints)
end

local function createColorSequenceSegment(
	colors : {Color3},
	startAlpha : number,
	endAlpha : number
) : ColorSequence
	startAlpha = math.clamp(startAlpha, 0, 1)
	endAlpha = math.clamp(endAlpha, 0, 1)

	if endAlpha <= startAlpha then
		return ColorSequence.new(getColorAtAlpha(colors, startAlpha))
	end

	if #colors <= 1 then
		return createColorSequence(colors)
	end

	local keypoints : {ColorSequenceKeypoint} = {
		ColorSequenceKeypoint.new(0, getColorAtAlpha(colors, startAlpha))
	}
	local maxIndex = #colors - 1

	for i = 2, #colors - 1 do
		local alpha = (i - 1) / maxIndex
		if alpha > startAlpha and alpha < endAlpha then
			keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(
				(alpha - startAlpha) / (endAlpha - startAlpha),
				colors[i]
			)
		end
	end

	keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(1, getColorAtAlpha(colors, endAlpha))

	return ColorSequence.new(keypoints)
end

local function getSpacedColorAtAlpha(colors : {Color3}, alpha : number, spacing : number) : Color3
	local colorCount = #colors

	if spacing <= 0 or colorCount <= 1 then
		return getColorAtAlpha(colors, alpha)
	end

	local firstColorAlpha = .5 - ((colorCount - 1) * spacing) / 2
	local scaledAlpha = (alpha - firstColorAlpha) / spacing

	if scaledAlpha <= 0 then
		return colors[1]
	end
	if scaledAlpha >= colorCount - 1 then
		return colors[colorCount]
	end

	local lowerIndex = math.floor(scaledAlpha) + 1
	local upperIndex = lowerIndex + 1

	return colors[lowerIndex]:Lerp(colors[upperIndex], scaledAlpha - math.floor(scaledAlpha))
end

local function createSpacedColorSequenceSegment(
	colors : {Color3},
	startAlpha : number,
	endAlpha : number,
	spacing : number
) : ColorSequence
	if spacing <= 0 or #colors <= 1 then
		return createColorSequenceSegment(colors, startAlpha, endAlpha)
	end

	startAlpha = math.clamp(startAlpha, 0, 1)
	endAlpha = math.clamp(endAlpha, 0, 1)

	if endAlpha <= startAlpha then
		return ColorSequence.new(getSpacedColorAtAlpha(colors, startAlpha, spacing))
	end

	local keypoints : {ColorSequenceKeypoint} = {
		ColorSequenceKeypoint.new(0, getSpacedColorAtAlpha(colors, startAlpha, spacing))
	}
	local firstColorAlpha = .5 - ((#colors - 1) * spacing) / 2

	for i, color in ipairs(colors) do
		local alpha = firstColorAlpha + (i - 1) * spacing
		if alpha > startAlpha and alpha < endAlpha then
			keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(
				(alpha - startAlpha) / (endAlpha - startAlpha),
				color
			)
		end
	end

	keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(1, getSpacedColorAtAlpha(colors, endAlpha, spacing))

	return ColorSequence.new(keypoints)
end

local function setGradientColor(gradient : UIGradient, color : ColorSequence)
	gradient.Color = color
end

local function createGradient(parent : Instance, rotation : number) : UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Parent = parent

	return gradient
end

local function colorsToKey(colors : {Color3}) : string
	local parts : {string} = {}

	for _, color in ipairs(colors) do
		parts[#parts + 1] = tostring(color)
	end

	return table.concat(parts, "|")
end

local function getLoopedColorAtAlpha(colors : {Color3}, alpha : number) : Color3
	local colorCount = #colors

	if colorCount == 1 then
		return colors[1]
	end

	local normalizedAlpha = alpha % 1
	local scaledAlpha = normalizedAlpha * colorCount
	local lowerIndex = math.floor(scaledAlpha) + 1
	local upperIndex = lowerIndex % colorCount + 1

	return colors[lowerIndex]:Lerp(colors[upperIndex], scaledAlpha - math.floor(scaledAlpha))
end

local function createLoopingColorSequenceSegment(
	colors : {Color3},
	startAlpha : number,
	endAlpha : number,
	alphaOffset : number
) : ColorSequence
	startAlpha = math.clamp(startAlpha, 0, 1)
	endAlpha = math.clamp(endAlpha, 0, 1)

	if endAlpha <= startAlpha or #colors <= 1 then
		return ColorSequence.new(getLoopedColorAtAlpha(colors, startAlpha + alphaOffset))
	end

	local span = endAlpha - startAlpha
	local startWithOffset = startAlpha + alphaOffset
	local endWithOffset = endAlpha + alphaOffset
	local colorCount = #colors
	local keypoints : {ColorSequenceKeypoint} = {
		ColorSequenceKeypoint.new(0, getLoopedColorAtAlpha(colors, startWithOffset))
	}

	for boundary = math.floor(startWithOffset * colorCount) + 1, math.floor(endWithOffset * colorCount) do
		local boundaryAlpha = boundary / colorCount
		if boundaryAlpha > startWithOffset and boundaryAlpha < endWithOffset then
			keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(
				math.clamp((boundaryAlpha - startWithOffset) / span, 0, 1),
				getLoopedColorAtAlpha(colors, boundaryAlpha)
			)
		end
	end

	keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(1, getLoopedColorAtAlpha(colors, endWithOffset))

	return ColorSequence.new(keypoints)
end

local function getLoopedSpacedColorAtAlpha(colors : {Color3}, alpha : number, spacing : number) : Color3
	local colorCount = #colors

	if spacing <= 0 or colorCount <= 1 then
		return getLoopedColorAtAlpha(colors, alpha)
	end

	local period = colorCount * spacing
	local firstColorAlpha = .5 - ((colorCount - 1) * spacing) / 2
	local scaledAlpha = ((alpha - firstColorAlpha) % period) / spacing
	local lowerIndex = math.floor(scaledAlpha) + 1
	local upperIndex = lowerIndex % colorCount + 1

	return colors[lowerIndex]:Lerp(colors[upperIndex], scaledAlpha - math.floor(scaledAlpha))
end

local function createDenseLoopingSpacedColorSequenceSegment(
	colors : {Color3},
	startAlpha : number,
	endAlpha : number,
	alphaOffset : number,
	spacing : number
) : ColorSequence
	local keypoints : {ColorSequenceKeypoint} = {}
	local maxKeypoints = 18

	for i = 1, maxKeypoints do
		local alpha = (i - 1) / (maxKeypoints - 1)
		keypoints[i] = ColorSequenceKeypoint.new(
			alpha,
			getLoopedSpacedColorAtAlpha(colors, startAlpha + (endAlpha - startAlpha) * alpha + alphaOffset, spacing)
		)
	end

	return ColorSequence.new(keypoints)
end

local function createLoopingSpacedColorSequenceSegment(
	colors : {Color3},
	startAlpha : number,
	endAlpha : number,
	alphaOffset : number,
	spacing : number
) : ColorSequence
	if spacing <= 0 or #colors <= 1 then
		return createLoopingColorSequenceSegment(colors, startAlpha, endAlpha, alphaOffset)
	end

	startAlpha = math.clamp(startAlpha, 0, 1)
	endAlpha = math.clamp(endAlpha, 0, 1)
	local period = #colors * spacing
	local offset = alphaOffset * period

	if endAlpha <= startAlpha then
		return ColorSequence.new(getLoopedSpacedColorAtAlpha(colors, startAlpha + offset, spacing))
	end

	local span = endAlpha - startAlpha
	local firstColorAlpha = .5 - ((#colors - 1) * spacing) / 2
	local startWithOffset = startAlpha + offset
	local endWithOffset = endAlpha + offset
	local firstBoundary = math.floor((startWithOffset - firstColorAlpha) / spacing) + 1
	local lastBoundary = math.floor((endWithOffset - firstColorAlpha) / spacing)

	if lastBoundary - firstBoundary > 16 then
		return createDenseLoopingSpacedColorSequenceSegment(colors, startAlpha, endAlpha, offset, spacing)
	end

	local keypoints : {ColorSequenceKeypoint} = {
		ColorSequenceKeypoint.new(0, getLoopedSpacedColorAtAlpha(colors, startWithOffset, spacing))
	}

	for boundary = firstBoundary, lastBoundary do
		local boundaryAlpha = firstColorAlpha + boundary * spacing
		if boundaryAlpha > startWithOffset and boundaryAlpha < endWithOffset then
			keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(
				math.clamp((boundaryAlpha - startWithOffset) / span, 0, 1),
				getLoopedSpacedColorAtAlpha(colors, boundaryAlpha, spacing)
			)
		end
	end

	keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(1, getLoopedSpacedColorAtAlpha(colors, endWithOffset, spacing))

	return ColorSequence.new(keypoints)
end

local function getMoveAlpha(
	moveDir : keyof<typeof(types.literal.horizontalDir)>,
	moveSpeed : number
) : number
	local alpha = (os.clock() * moveSpeed) % 1

	if moveDir == "right" then
		alpha = -alpha
	end

	return alpha
end

local function startGradientColorMovement(
	obj : types.hyperTextClassObject,
	updater : {[string] : (dt : number) -> ()},
	gradient : UIGradient,
	colors : {Color3},
	moveDir : keyof<typeof(types.literal.horizontalDir)>,
	moveSpeed : number,
	startAlpha : number,
	endAlpha : number,
	spacing : number
)
	if obj._contentFolder then
		local updaterId = HttpService:GenerateGUID()

		local function updateColor()
			setGradientColor(
				gradient,
				createLoopingSpacedColorSequenceSegment(
					colors,
					startAlpha,
					endAlpha,
					getMoveAlpha(moveDir, moveSpeed),
					spacing
				)
			)
		end

		updateColor()

		updater[updaterId] = function()
			debug.profilebegin("Gradient Markup")

			updateColor()

			debug.profileend()
		end

		obj._contentFolder.Destroying:Once(function()
			updater[updaterId] = nil
		end)
	end
end

local function getProjectionAxis(rot : number) : Vector2
	local radians = math.rad(rot)
	
	return Vector2.new(math.cos(radians), math.sin(radians))
end

local function projectPoint(point : Vector2, axis : Vector2) : number
	return point.X * axis.X + point.Y * axis.Y
end

local function getRectProjection(
	position : Vector2,
	size : Vector2,
	axis : Vector2
) : (number, number)
	local x0 = position.X
	local y0 = position.Y
	local x1 = x0 + size.X
	local y1 = y0 + size.Y

	local p1 = projectPoint(Vector2.new(x0, y0), axis)
	local p2 = projectPoint(Vector2.new(x1, y0), axis)
	local p3 = projectPoint(Vector2.new(x0, y1), axis)
	local p4 = projectPoint(Vector2.new(x1, y1), axis)

	return math.min(p1, p2, p3, p4), math.max(p1, p2, p3, p4)
end

local function getGradientSegment(
	spanData : types.onPrintMarkupSpanData,
	rot : number
) : (number, number)
	local axis = getProjectionAxis(rot)
	local spanMin, spanMax = getRectProjection(spanData.spanPosition, spanData.spanSize, axis)
	local characterMin, characterMax = getRectProjection(
		spanData.characterPosition,
		spanData.characterSize,
		axis
	)
	local projectionSpan = spanMax - spanMin

	if projectionSpan <= 0 then
		return 0, 1
	end

	return
		math.clamp((characterMin - spanMin) / projectionSpan, 0, 1),
		math.clamp((characterMax - spanMin) / projectionSpan, 0, 1)
end

local function updateCombinedGradient(group : gradientGroup, alphaOffset : number?)
	for _, item in ipairs(group.items) do
		local color = if alphaOffset ~= nil
			then createLoopingSpacedColorSequenceSegment(
				group.colors,
				item.startAlpha,
				item.endAlpha,
				alphaOffset,
				group.spacing
			)
			else createSpacedColorSequenceSegment(
				group.colors,
				item.startAlpha,
				item.endAlpha,
				group.spacing
			)

		setGradientColor(item.gradient, color)
	end
end

local function startCombinedGradientMovement(
	obj : types.hyperTextClassObject,
	updater : {[string] : (dt : number) -> ()},
	group : gradientGroup,
	moveDir : keyof<typeof(types.literal.horizontalDir)>,
	moveSpeed : number
)
	if obj._contentFolder and not group.updaterId then
		local updaterId = HttpService:GenerateGUID()
		group.updaterId = updaterId

		updater[updaterId] = function()
			debug.profilebegin("Gradient Markup Combined")

			updateCombinedGradient(group, getMoveAlpha(moveDir, moveSpeed))

			debug.profileend()
		end

		obj._contentFolder.Destroying:Once(function()
			updater[updaterId] = nil
		end)
	end
end

local function ensureCleanup(renderId : string, contentFolder : Folder?)
	if contentFolder and not cleanupConnections[renderId] then
		cleanupConnections[renderId] = contentFolder.Destroying:Once(function()
			renderGradientGroups[renderId] = nil
			cleanupConnections[renderId] = nil
		end)
	end
end

local function getRenderGroups(renderId : string) : {[string] : gradientGroup}
	local groups = renderGradientGroups[renderId]
	if not groups then
		groups = {}
		renderGradientGroups[renderId] = groups
	end

	return groups
end

local function vector2ToKey(value : Vector2) : string
	return string.format("%.17g,%.17g", value.X, value.Y)
end

return function(
	obj : types.hyperTextClassObject,
	gradientParent : Instance,
	spanData : types.onPrintMarkupSpanData,
	attrs : gradientAttrs,
	updater : {[string] : (dt : number) -> ()},
	groupScope : string
)
	local colors = attrs.colors
	local gradient = createGradient(gradientParent, attrs.rot)

	if attrs.individual then
		if attrs.moveSpeed > 0 then
			startGradientColorMovement(
				obj,
				updater,
				gradient,
				colors,
				attrs.moveDir,
				attrs.moveSpeed,
				0,
				1,
				0
			)
		else
			setGradientColor(gradient, createColorSequence(colors))
		end

		return
	end

	local startAlpha, endAlpha = getGradientSegment(spanData, attrs.rot)

	if attrs.moveSpeed <= 0 then
		setGradientColor(
			gradient,
			createSpacedColorSequenceSegment(colors, startAlpha, endAlpha, attrs.spacing)
		)

		return
	end

	local renderId = obj._renderId
	if not renderId then
		startGradientColorMovement(
			obj,
			updater,
			gradient,
			colors,
			attrs.moveDir,
			attrs.moveSpeed,
			startAlpha,
			endAlpha,
			attrs.spacing
		)

		return
	end

	ensureCleanup(renderId, obj._contentFolder)

	local key = groupScope
		.. "|" .. colorsToKey(colors)
		.. "|" .. tostring(attrs.rot)
		.. "|" .. tostring(attrs.moveDir)
		.. "|" .. tostring(attrs.moveSpeed)
		.. "|" .. tostring(attrs.spacing)
		.. "|" .. vector2ToKey(spanData.spanPosition)
		.. "|" .. vector2ToKey(spanData.spanSize)
	local groups = getRenderGroups(renderId)
	local group = groups[key]

	if not group then
		group = {
			colors = colors,
			spacing = attrs.spacing,
			items = {},
		} :: gradientGroup

		groups[key] = group
	end

	table.insert(group.items, {
		gradient = gradient,
		startAlpha = startAlpha,
		endAlpha = endAlpha,
	})

	startCombinedGradientMovement(obj, updater, group, attrs.moveDir, attrs.moveSpeed)
	updateCombinedGradient(group, getMoveAlpha(attrs.moveDir, attrs.moveSpeed))
end
