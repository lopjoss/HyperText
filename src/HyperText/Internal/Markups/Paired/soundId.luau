--!strict

local ContentProvider = game:GetService("ContentProvider")

local types = require("../../Types")
local util = require("../../Util")
local config = require("../../Config")

local name : "soundId" = "soundId"
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
		local t = os.clock()
		local isWhitespace = string.match(printerData.constructionDataRowEntry.str, "%s")

		if 
			printerData.markups.soundId.value
			and not obj._loadingTypewriterSfx
			and not obj._ignoreIntervals
			and not isWhitespace
			and (
				not obj._nextTypewriterSfxTime
					or t >= obj._nextTypewriterSfxTime
			)
		then
			local cached = obj._cachedTypewriterSound

			if 
				not cached
				or cached.SoundId ~= (
					typeof(printerData.markups.soundId.value) == "string"
						and printerData.markups.soundId.value
						or "rbxassetid://" .. printerData.markups.soundId.value
				)
			then
				if cached then
					cached:Destroy()
				end

				obj._loadingTypewriterSfx = true

				local sound = Instance.new("Sound", script)
				sound.Volume = printerData.markups.soundId.attributes.volume
				sound.SoundId = typeof(printerData.markups.soundId.value) == "string"
					and printerData.markups.soundId.value
					or "rbxassetid://" .. printerData.markups.soundId.value

				obj._cachedTypewriterSound = sound

				if not sound.IsLoaded then
					task.spawn(function()
						local status: Enum.AssetFetchStatus?
						local renderId = obj._renderId
						
						ContentProvider:PreloadAsync({sound}, function(
							assetId: string,
							fetchStatus: Enum.AssetFetchStatus
						)
							status = fetchStatus
						end)
						
						obj._loadingTypewriterSfx = false
						
						if status == Enum.AssetFetchStatus.Success then
							if obj.rendering and obj._renderId == renderId then
								sound:Play()
							end
						else
							warn("Failed to load sound " .. sound.SoundId .. ": " .. tostring(status))
						end
					end)
				else
					obj._loadingTypewriterSfx = false

					sound:Play()
				end
			else
				if cached.IsPlaying then
					cached:Stop()
				end

				cached.Volume = printerData.markups.soundId.attributes.volume
				cached:Play()

				obj._nextTypewriterSfxTime = t + math.max(
					config.MIN_TYPEWRITER_SFX_INTERVAL,
					printerData.markups.interval.value
				)
			end
		end
	end,
	convert = function(value : string)
		local new : string? = value

		local success = pcall(function()
			return util.stringToNumber(value)
		end)
		if not success then
			new = value
		else
			new = "rbxassetid://" .. tostring(value)
		end

		return new
	end,
	attributes = {
		volume = {
			convert = util.stringToNumber,
		}
	},
	valueAttributes = {},
	unrequired = true,
}

return module
