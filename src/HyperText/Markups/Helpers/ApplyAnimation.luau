local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local util = require("../../Util")
local types = require("../../Types")

return function(
	obj : types.hyperTextClassObject,
	printerData : types.printerDataRowEntry,
	value : keyof<typeof(types.literal.animations)>,
	attrs : types.animAttrs,
	valueAttrs : types.animValueAttrs,
	updater : {[string] : (dt : number) -> ()},
	onClear : boolean,
	name : string
)
	if
		obj._markupIndices
		and obj._contentFolder
	then
		local startTime = os.clock()
		local size = obj:_GetProportionalSize(printerData.markups.size.value)
		
		if #printerData.containers == 0 then
			obj:_CreateRowEntryContainer(printerData, name)
		end
		
		if value == "slide" then
			local updaterId = HttpService:GenerateGUID()
			local startPos = valueAttrs.slide.dir == "up"
				and Vector2.new(
					(size * valueAttrs.slide.offset) / (printerData.character.Parent :: GuiObject).AbsoluteSize.X,
					(size * valueAttrs.slide.offset) / (printerData.character.Parent :: GuiObject).AbsoluteSize.Y
				)
				or Vector2.new(
					(size * valueAttrs.slide.offset) / (printerData.character.Parent :: GuiObject).AbsoluteSize.X,
					(-size * valueAttrs.slide.offset) / (printerData.character.Parent :: GuiObject).AbsoluteSize.Y
				)
			local startRot = valueAttrs.slide.dir == "up"
				and valueAttrs.slide.rot
				or -valueAttrs.slide.rot
			local reversing = onClear and true or false

			local function stop()
				util.removeEntryFromTransformUpdater(
					obj,
					printerData,
					name
				)

				updater[updaterId] = nil
			end

			util.addEntryToTransformUpdater(
				obj,
				printerData,
				name
			)

			updater[updaterId] = function()
				debug.profilebegin("Slide Animation Markup")

				local time_ = os.clock()
				local n = math.clamp((time_ - startTime) / attrs.dur, 0, 1)
				local alpha = TweenService:GetValue(
					reversing and 1 - n or n,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				)

				printerData.position += startPos:Lerp(Vector2.zero, alpha)
				printerData.rotation += startRot * (1 - alpha)

				if not onClear and n == 1 then
					if not attrs.loop then
						stop()
					else
						reversing = not reversing
						startTime = time_
					end
				end

				debug.profileend()
			end

			local connection = not onClear and obj.onRenderEnded:Once(function(stopped : boolean?)
				if stopped and not attrs.loop then
					stop()
				end
			end)
			obj._contentFolder.Destroying:Once(function()
				stop()

				if connection then
					connection:Disconnect()
				end						
			end)
		elseif value == "bounce" then
			local updaterId = HttpService:GenerateGUID()
			local startPos = valueAttrs.bounce.dir == "down"
				and Vector2.new(0, (-size * valueAttrs.bounce.offset) / (printerData.character.Parent :: GuiObject).AbsoluteSize.Y)
				or Vector2.new(0, (size * valueAttrs.bounce.offset) / (printerData.character.Parent :: GuiObject).AbsoluteSize.Y)
			local reversing = onClear and true or false

			local function stop()
				util.removeEntryFromTransformUpdater(
					obj,
					printerData,
					name
				)

				updater[updaterId] = nil
			end

			util.addEntryToTransformUpdater(
				obj,
				printerData,
				name
			)

			updater[updaterId] = function()
				debug.profilebegin("Bounce Animation Markup")

				local time_ = os.clock()
				local n = math.clamp((time_ - startTime) / attrs.dur, 0, 1)
				local alpha = TweenService:GetValue(
					reversing and 1 - n or n,
					Enum.EasingStyle.Bounce,
					Enum.EasingDirection.Out
				) ^ valueAttrs.bounce.exp

				printerData.position += startPos:Lerp(Vector2.zero, alpha)

				if not onClear and n == 1 then
					if not attrs.loop then
						stop()
					else
						reversing = not reversing
						startTime = time_
					end
				end

				debug.profileend()
			end

			local connection = not onClear and obj.onRenderEnded:Once(function(stopped : boolean?)
				if stopped and not attrs.loop then
					stop()
				end
			end)
			obj._contentFolder.Destroying:Once(function()
				stop()

				if connection then
					connection:Disconnect()
				end						
			end)
		elseif value == "wiggle" then
			local updaterId = HttpService:GenerateGUID()

			if not obj._markupIndices[value] then
				obj._markupIndices[value] = 0
			end

			local index = obj._markupIndices[value]

			local function stop()
				util.removeEntryFromTransformUpdater(
					obj,
					printerData,
					name
				)

				updater[updaterId] = nil
			end

			util.addEntryToTransformUpdater(
				obj,
				printerData,
				name
			)

			updater[updaterId] = function()
				debug.profilebegin("Wiggle Animation Markup")

				local time_ = os.clock()
				local elapsed = time_ - startTime

				if onClear or not attrs.loop or attrs.dur ~= 0 then
					local x = (time_ / (
						--attrs.loop
						--	and attrs.dur
						--	or 1 / valueAttrs.wiggle.freq
						1 / valueAttrs.wiggle.freq
						) * math.pi * 2)
						+ (math.pi * 2 * valueAttrs.wiggle.offset * index) -- offset between characters

					local wiggle = valueAttrs.wiggle
					local fade = not onClear and attrs.loop
						and 1
						or math.clamp(1 - elapsed / attrs.dur, 0, 1)
					if onClear then
						fade = 1 - fade
					end
					
					local yOffset = math.sin(x)
						* fade
						* wiggle.amp
						* printerData.character.AbsoluteSize.Y
					local n = math.clamp(elapsed / attrs.dur, 0, 1)
					if onClear then
						n = 1 - n
					end

					local pos = Vector2.new(
						0,
						yOffset / (printerData.character.Parent :: GuiObject).AbsoluteSize.Y
					)
					printerData.position += pos:Lerp(
						(onClear or not attrs.loop) and Vector2.zero or pos,
						n
					)

					if wiggle.rot then
						local phaseStep = math.pi * 2 * wiggle.offset

						local slopeY = math.cos(x)
							* phaseStep
							* fade
							* wiggle.amp
							* printerData.constructionDataRowEntry.height
						
						printerData.rotation += math.deg(math.atan2(slopeY, printerData.constructionDataRowEntry.width))
					end
				end

				if 
					elapsed >= attrs.dur
					and not onClear
					and not attrs.loop
				then
					stop()
				end

				debug.profileend()
			end

			local connection = not onClear and obj.onRenderEnded:Once(function(stopped : boolean?)
				if stopped and not attrs.loop then
					stop()
				end
			end)
			obj._contentFolder.Destroying:Once(function()
				stop()

				if connection then
					connection:Disconnect()
				end
			end)

			obj._markupIndices[value] += 1
		elseif value == "grow" then
			local updaterId = HttpService:GenerateGUID()
			local defaultTextSize : Vector2? = printerData.character:IsA("TextLabel")
				and printerData.character:GetAttribute("DefaultTextSize")
			local UIScale : UIScale? = printerData.character:IsA("ImageLabel")
				and Instance.new("UIScale", printerData.character) or nil
			local reversing = onClear and true or false

			local function stop()
				if UIScale then
					UIScale:Destroy()
				end
				if defaultTextSize then
					printerData.character:SetAttribute("DefaultTextSize", defaultTextSize)
				end

				updater[updaterId] = nil
			end

			updater[updaterId] = function()
				debug.profilebegin("Grow Animation Markup")

				local time_ = os.clock()
				local n = math.clamp(
					(time_ - startTime) / attrs.dur,
					0,
					1							
				)
				n = reversing and 1 - n or n

				local landingPoint = .4
				local t = n / landingPoint - 1
				local overshoot = 1.70158

				local alpha = 1
					+ (overshoot + 1) * t ^ 3
					+ overshoot * t ^ 2

				t = (n - landingPoint) / (1 - landingPoint)
				local amplitude = .09
				local oscillations = 1.5
				local damping = (1 - t) ^ 2

				if n > landingPoint then
					alpha = 1 - math.sin(t * math.pi * 2 * oscillations)
						* amplitude
						* damping
				end

				local scale = valueAttrs.grow.startScale + 
					(1 - valueAttrs.grow.startScale) * alpha ^ valueAttrs.grow.exp

				if UIScale then
					UIScale.Scale = scale
				end
				if defaultTextSize then
					printerData.character:SetAttribute("DefaultTextSize", defaultTextSize * scale)
				end

				if not onClear and (not reversing and n == 1 or reversing and n == 0) then
					if not attrs.loop then
						stop()
					else
						startTime = time_
						reversing = not reversing
					end
				end

				debug.profileend()
			end

			local connection = not onClear and obj.onRenderEnded:Once(function(stopped : boolean?)
				if stopped and not attrs.loop then
					stop()
				end
			end)
			obj._contentFolder.Destroying:Once(function()
				stop()

				if connection then
					connection:Disconnect()
				end
			end)
		end
	end
end