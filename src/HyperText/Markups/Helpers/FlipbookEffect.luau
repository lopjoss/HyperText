--!strict

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")

local types = require("../../Types")
local config = require("../../Config")
local memoizer = require("../../Memoizer")

local module = {}

type schema = {[string] : Vector2}

local imageSizeCache = memoizer.new<<schema>>(
	5,
	config.MAX_FLIPBOOK_IMG_SIZE_CACHE_RECORDS
)

local function getImageSizeCacheFetschingSchema(imageId : string) : memoizer.fetchingSchema<schema>
	return {
		[imageId] = function()
			local editableImage = AssetService:CreateEditableImageAsync(Content.fromUri(imageId))
			local size = editableImage.Size

			editableImage:Destroy()

			return size
		end
	}
end

module.shouldApplyFlipbookEffect = function(attrs : types.flipbookAttrs) : boolean
	if attrs.flipbookLayout then
		local columns = math.floor(attrs.flipbookLayout.X)
		local rows = math.floor(attrs.flipbookLayout.Y)
		
		return columns >= 1 and rows >= 1
	end

	return false
end

module.cacheImageSize = function(imageURI : string)
	local success, errmsg = pcall(function()
		imageSizeCache:Get(getImageSizeCacheFetschingSchema(imageURI))
	end)

	if not success then
		warn(`Failed to cache image size for asset URI "{imageURI}": {errmsg}`)
	end
end

module.applyFlipbookEffect = function(
	image : ImageLabel,
	attrs : types.flipbookAttrs,
	updater : {[string] : (dt : number) -> ()}
)	
	if attrs.flipbookLayout and image.Image ~= "" then
		local columns = math.floor(attrs.flipbookLayout.X)
		local rows = math.floor(attrs.flipbookLayout.Y)
		
		if columns >= 1 and rows >= 1 then
			local frameCount = columns * rows

			image.Visible = false

			local success, imageSize = pcall(function()
				return imageSizeCache:Get(getImageSizeCacheFetschingSchema(image.Image))
			end)

			if success and image.Parent then
				image.Visible = true
				
				local frameSize = Vector2.new(
					imageSize.X / columns,
					imageSize.Y / rows
				)
				local frameIndex = 0
				local pingPongPhase = 0
				local elapsed = 0

				local function displayFrame()
					local column = frameIndex % columns
					local row = math.floor(frameIndex / columns)

					image.ImageRectSize = frameSize
					image.ImageRectOffset = Vector2.new(
						column * frameSize.X,
						row * frameSize.Y
					)
				end

				displayFrame()

				if frameCount > 1 and attrs.flipbookFreq > 0 then
					local updaterId = HttpService:GenerateGUID()
					local frameDuration = 1 / (attrs.flipbookFreq * (frameCount - 1))

					local function stop()
						updater[updaterId] = nil
					end
					
					updater[updaterId] = function(dt : number)
						elapsed += dt

						local framesElapsed = math.floor(elapsed / frameDuration)

						if framesElapsed ~= 0 then
							elapsed -= framesElapsed * frameDuration

							if attrs.flipbookReverse then
								local lastFrameIndex = frameCount - 1
								local cycleLength = lastFrameIndex * 2

								pingPongPhase = attrs.flipbookLoop
									and (pingPongPhase + framesElapsed) % cycleLength
									or math.min(cycleLength, pingPongPhase + framesElapsed)
								frameIndex = pingPongPhase <= lastFrameIndex
									and pingPongPhase
									or cycleLength - pingPongPhase

								if not attrs.flipbookLoop and pingPongPhase == cycleLength then
									stop()
								end
							elseif attrs.flipbookLoop then
								frameIndex = (frameIndex + framesElapsed) % frameCount
							else
								local lastFrameIndex = frameCount - 1

								frameIndex = math.min(lastFrameIndex, frameIndex + framesElapsed)

								if frameIndex == lastFrameIndex then
									stop()
								end
							end

							displayFrame()
						end
					end

					image.Destroying:Once(stop)
				end
			else
				warn(`Failed to fetch image size for asset URI "{image.Image}": {imageSize}`)
			end
		end
	end
end

return module