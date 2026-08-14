--!strict

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local types = require("../../Types")
local util = require("../../Util")
local applyFlipbookEffect = require("./ApplyFlipbookEffect")

return function(
	obj : types.hyperTextClassObject,
	id : number,
	printerData : types.printerDataRowEntry,
	markups : types.markups,
	attributes : types.emitImgAttrs & types.flipbookAttrs,
	updater : {[string] : (dt : number) -> ()}
)
	if obj._contentFolder and attributes.rate > 0 then
		local container = 
			attributes.applyTransform
			and printerData.character
			or #printerData.containers > 0 
			and printerData.containers[#printerData.containers] 
			or obj:_CreateRowEntryContainer(printerData, "ImageEmitter")
		
		local interval = 1 / attributes.rate
		local last = os.clock() - math.random() * interval

		local images : {
			[ImageLabel] : {
				vel : Vector2,
				accel : Vector2,
				rotvel : number,
			}	
		} = {}

		local updaterId = HttpService:GenerateGUID()

		updater[updaterId] = function(dt : number)
			debug.profilebegin("Image Emitting Markup")

			for img, data in pairs(images) do
				img.Position += UDim2.fromScale(
					data.vel.X * dt,
					data.vel.Y * dt
				)

				data.vel += Vector2.new(
					data.accel.X * dt,
					data.accel.Y * dt
				)

				img.Rotation += data.rotvel * dt
			end

			local c = os.clock()
			if c - last >= interval then
				last = c

				if math.random() * 100 <= attributes.chance then
					local img = Instance.new("ImageLabel", container)
					img.ImageColor3 = attributes.color
					img.AnchorPoint = Vector2.new(.5, .5)
					img.Image = "rbxassetid://" .. id
					img.BackgroundTransparency = 1
					img.ImageTransparency = util.getRandomFromRange(attributes.startTrans)
					img.Position = UDim2.fromScale(.5, .5) + UDim2.fromScale(
						util.getRandomFromRange(attributes.startPosX),
						util.getRandomFromRange(attributes.startPosY)
					)
					img.Rotation = util.getRandomFromRange(attributes.startRot)
					img.SizeConstraint = Enum.SizeConstraint.RelativeYY
					img.ZIndex = markups.ZIndex.value

					local endSize = util.getRandomFromRange(attributes.endSize)
					local size = util.getRandomFromRange(attributes.startSize) 
					img.Size = UDim2.fromScale(size * attributes.aspectRatio, size)
					
					applyFlipbookEffect(
						img,
						attributes,
						updater
					)
					
					local vel = Vector2.new(
						util.getRandomFromRange(attributes.velX),
						util.getRandomFromRange(attributes.velY)
					)
					local accel = Vector2.new(
						util.getRandomFromRange(attributes.accelX),
						util.getRandomFromRange(attributes.accelY)
					)
					local rotvel = util.getRandomFromRange(attributes.rotVel)

					local lifetime = util.getRandomFromRange(attributes.lifetime)
					local tween = TweenService:Create(
						img,
						TweenInfo.new(lifetime),
						{
							Size = UDim2.fromScale(endSize * attributes.aspectRatio, endSize),
							ImageTransparency = util.getRandomFromRange(attributes.endTrans)
						}
					)

					images[img] = {
						vel = vel,
						accel = accel,
						rotvel = rotvel,
					}

					tween.Completed:Once(function()
						img:Destroy()

						images[img] = nil
					end)
					tween:Play()
				end
			end

			debug.profileend()
		end

		obj._contentFolder.Destroying:Once(function()
			updater[updaterId] = nil
		end)
	end
end