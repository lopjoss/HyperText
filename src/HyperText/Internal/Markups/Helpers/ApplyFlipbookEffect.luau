--!strict

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")

local types = require("../../Types")

local imageSizeCache : {[string] : Vector2} = {}
local imageSizeCallbacks : {
	[string] : {(imageSize : Vector2?) -> ()}
} = {}

local function requestImageSize(
	imageUri : string,
	callback : (imageSize : Vector2?) -> ()
)
	local cachedSize = imageSizeCache[imageUri]
	
	if cachedSize then
		callback(cachedSize)

		return
	end

	local callbacks = imageSizeCallbacks[imageUri]
	if callbacks then
		table.insert(callbacks, callback)

		return
	end

	imageSizeCallbacks[imageUri] = {callback}

	task.spawn(function()
		local success, result = pcall(function()
			return AssetService:CreateEditableImageAsync(Content.fromUri(imageUri))
		end)
		local imageSize : Vector2?

		if success and result then
			imageSize = result.Size
			imageSizeCache[imageUri] = imageSize
			
			result:Destroy()
		else
			warn(
				`Failed to get the dimensions of flipbook image "{imageUri}": {result}`
			)
		end

		local pendingCallbacks = imageSizeCallbacks[imageUri]
		imageSizeCallbacks[imageUri] = nil

		if pendingCallbacks then
			for _, pendingCallback in pendingCallbacks do
				pendingCallback(imageSize)
			end
		end
	end)
end

return function(
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

			requestImageSize(image.Image, function(imageSize : Vector2?)
				if imageSize and image.Parent then
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
				end
			end)
		end
	end
end