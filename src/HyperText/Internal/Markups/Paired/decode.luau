--!strict

local HttpService = game:GetService("HttpService")

local types = require("../../Types")
local util = require("../../Util")

local name : "decode" = "decode"
local type_ : "paired" = "paired"
local module : types.dataModule<typeof(name), typeof(type_)> = {
	type = type_,
	name = name,
	
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry<false>,
		spanData : types.onPrintMarkupSpanData,
		updater : {[string] : (dt : number) -> ()}
	)
		if obj._contentFolder and printerData.markups.decode.value then
			local startTime = os.clock()
			local updaterId = HttpService:GenerateGUID()
			local text = printerData.character.Text
			local last

			local function stop()
				updater[updaterId] = nil

				printerData.character.Text = text
			end
			
			updater[updaterId] = function(dt : number)
				debug.profilebegin("Decode Markup")

				local time_ = os.clock()
				local elapsed = time_ - startTime

				if 
					not printerData.markups.decode.attributes.freq
					or not last
					or time_ - last >= 1 / printerData.markups.decode.attributes.freq
				then
					last = time_
					
					local byte = math.random(33, 125)
					byte += byte >= 60 and 1 or 0
					
					local char = string.char(byte)
						
					printerData.character.Text = 
						(printerData.markups.underline.value and "<u>" or "")
						.. (printerData.markups.strike.value and "<s>" or "")
						.. char
						.. (printerData.markups.strike.value and "</s>" or "")
						.. (printerData.markups.underline.value and "</u>" or "")
				end

				if elapsed >= printerData.markups.decode.attributes.dur and not printerData.markups.decode.attributes.loop then
					stop()
				end

				debug.profileend()
			end

			local connection = obj.onRenderEnded:Once(function(stopped : boolean?)
				if stopped and not printerData.markups.decode.attributes.loop then
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
		freq = {
			convert = util.stringToNumber,
			unrequired = true,
		},
		dur = {
			convert = function(value : string)
				return util.stringToNumber(value, 0)
			end,
		},
		loop = {
			convert = util.stringToBoolean,
		},
	},
	valueAttributes = {},
}

return module
