--!strict

local HttpService = game:GetService("HttpService")

local types = require("../../Types")
local util = require("../../Util")

local name : "shake" = "shake"
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
		if 
			printerData.markups.shake.value
			and (
				printerData.markups.shake.attributes.loop
				or printerData.markups.shake.attributes.dur > 0
			)
			and obj._contentFolder
		then
			local updaterId = HttpService:GenerateGUID()
			local startTime = os.clock()
			local last
			local lastPos
			local lastRot
			
			if printerData.character.Parent == printerData.row then
				obj:_CreateRowEntryContainer(printerData, name)
			end
			
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
				debug.profilebegin("Shake Markup")

				local offset = printerData.markups.shake.attributes.maxOffset * (printerData.character.Parent :: GuiObject).AbsoluteSize.Y
				local yOffset = offset * math.random(-100, 100)/100
				local xOffset = offset * math.random(-100, 100)/100

				local time_ = os.clock()
				local elapsed = time_ - startTime
				local fade = (printerData.markups.shake.attributes.loop or not printerData.markups.shake.attributes.fade)
					and 1
					or (1 - (elapsed / printerData.markups.shake.attributes.dur))

				if 
					not printerData.markups.shake.attributes.freq
					or not last
					or time_ - last >= 1 / printerData.markups.shake.attributes.freq
				then
					last = time_
					
					local pos = Vector2.new(
						xOffset/(printerData.character.Parent :: GuiObject).AbsoluteSize.X * fade,
						yOffset/(printerData.character.Parent :: GuiObject).AbsoluteSize.Y * fade
					)
					printerData.position += pos
					lastPos = pos
					
					local rot = printerData.markups.shake.attributes.maxRot * math.random(-100, 100)/100 * fade
					printerData.rotation += rot
					lastRot = rot
				elseif lastPos and lastRot then
					printerData.position += lastPos
					printerData.rotation += lastRot
				end

				if elapsed >= printerData.markups.shake.attributes.dur and not printerData.markups.shake.attributes.loop then
					stop()
				end

				debug.profileend()
			end

			local connection = obj.onRenderEnded:Once(function(stopped : boolean?)
				if stopped and not printerData.markups.shake.attributes.loop then
					stop()
				end
			end)
			obj._contentFolder.Destroying:Once(function()
				connection:Disconnect()

				stop()
			end)
		end
	end,
	convert = util.stringToBoolean,
	attributes = {
		maxOffset = {
			convert = util.stringToNumber,
		},
		dur = {
			convert = util.stringToNumber,
		},
		loop = {
			convert = util.stringToBoolean,
		},
		maxRot = {
			convert = util.stringToNumber,
		},
		freq = {
			convert = util.stringToNumber,
			unrequired = true,
		},
		fade = {
			convert = util.stringToBoolean,
		}
	},
	valueAttributes = {},
}

return module
