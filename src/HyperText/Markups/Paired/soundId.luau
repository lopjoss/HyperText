--!strict

local ContentProvider = game:GetService("ContentProvider")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")

local types = require("../../Types")
local util = require("../../Util")
local config = require("../../Config")
local memoizer = require("../../Memoizer")

type schema = {[string] : Sound}

local SFXCache = memoizer.new<<schema>>(
	5,
	config.MAX_TYPEWRITER_SFX_CACHE_RECORDS
)

local function getSFXCacheFetchingSchema(soundURI : string) : memoizer.fetchingSchema<schema>
	return {
		[soundURI] = function()
			local fetchStatus : Enum.AssetFetchStatus?
			local sound : Sound?
			local success, result = pcall(function()
				local snippet = tonumber(soundURI:sub(string.len("rbxassetid://") + 1))

				if snippet then
					return MarketplaceService:GetProductInfoAsync(snippet)
				else
					error("Not a valid asset ID", 0)
				end
			end)

			if success and result and result.AssetTypeId == 3 then
				sound = Instance.new("Sound")
				sound.SoundId = soundURI
	
				ContentProvider:PreloadAsync({sound}, function(_, status)
					fetchStatus = status
				end)
			end

			if not sound or fetchStatus ~= Enum.AssetFetchStatus.Success then
				if sound then
					sound:Destroy()
				end

				local errmsg = not sound and result or fetchStatus and fetchStatus.Name

				error(`Failed to load sound with asset URI "{soundURI}": {errmsg}`, 0)
			end

			return sound
		end
	}
end

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
			and not obj._fetchingTypewriterSFX
			and not obj._ignoreIntervals
			and not isWhitespace
			and (
				not obj._nextTypewriterSFXTime
					or t >= obj._nextTypewriterSFXTime
			)
		then
			local soundURI = typeof(printerData.markups.soundId.value) == "string"
				and printerData.markups.soundId.value
				or "rbxassetid://" .. printerData.markups.soundId.value
			local renderId = obj._renderId

			obj._fetchingTypewriterSFX = true

			task.spawn(function()
				local success, sound = pcall(function()
					if obj._currentTypewriterSFX and obj._currentTypewriterSFX.SoundId == soundURI then
						return obj._currentTypewriterSFX
					else
						if obj._currentTypewriterSFX then
							obj._currentTypewriterSFX:Destroy()
							obj._currentTypewriterSFX = nil
						end

						local sound = SFXCache:Get(getSFXCacheFetchingSchema(soundURI)):Clone()
						sound.Parent = SoundService

						return sound
					end
				end)

				if obj._renderId == renderId then
					if success then
						obj._currentTypewriterSFX = sound

						if sound.IsPlaying then
							sound:Stop()
						end

						sound.Volume = printerData.markups.soundId.attributes.volume
						sound:Play()

						obj._nextTypewriterSFXTime = t + math.max(
							config.MIN_TYPEWRITER_SFX_INTERVAL,
							printerData.markups.interval.value
						)
					else
						warn(`Failed to fetch sound with asset URI "{soundURI}": {sound}`)
					end

					obj._fetchingTypewriterSFX = false
				elseif success then
					sound:Destroy()
				end
			end)
		end
	end,
	validateDefaultValue = function(value : number | string)
		local URI : string

		if type(value) == "number" then
			URI = "rbxassetid://" .. tostring(value)
		else
			URI = value
		end

		SFXCache:Get(getSFXCacheFetchingSchema(URI))
	end,
	convert = function(value : string)
		local URI = util.stringToURI(value)

		SFXCache:Get(getSFXCacheFetchingSchema(URI))

		return URI
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
