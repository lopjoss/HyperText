--!strict

local TweenService = game:GetService("TweenService")

local types = require("../../Types")
local util = require("../../Util")

local tweens : {[UIStroke] : Tween} = {}

local name : "stroke" = "stroke"
local type_ : "paired" = "paired"
local applyOnClear : true = true
local module : types.dataModule<typeof(name), typeof(type_), nil, typeof(applyOnClear)> = {
	type = type_,
	name = name,
	applyOnClear = applyOnClear,
	
	validate = function()
		return true
	end,
	getClearingDuration = function()
		return 0
	end,
	onPrint = function(
		obj : types.hyperTextClassObject,
		printerData : types.printerDataRowEntry<false>,
		spanData : types.onPrintMarkupSpanData,
		updater : {[string] : (dt : number) -> ()},
		onClear : boolean
	)		
		if obj._contentFolder and printerData.markups.stroke.value then
			local stroke = printerData.character:FindFirstChildWhichIsA("UIStroke")
				or Instance.new("UIStroke", printerData.character)
			stroke.Thickness = printerData.markups.stroke.attributes.thickness
			stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
			stroke.Color = printerData.markups.stroke.attributes.color
			
			if tweens[stroke] then
				tweens[stroke]:Cancel()
			end
			
			local transTweenGoal = not onClear 
				and (
					printerData.markups.stroke.attributes.trans 
					or printerData.markups.trans.value
				) or 1 
			local dur = (not onClear or printerData.markups.clearTransDur.value == "inherit")
				and (printerData.markups.trans.attributes.tweenDur or 0)
				or printerData.markups.clearTransDur.value :: number
			
			if dur ~= 0 then
				stroke.Transparency = not onClear and printerData.markups.trans.attributes.tweenFrom
					or stroke.Transparency
				
				local tween = TweenService:Create(
					stroke,
					TweenInfo.new(
						dur,
						Enum.EasingStyle.Linear,
						Enum.EasingDirection.Out,
						not onClear and printerData.markups.trans.attributes.loopTween and -1 or 0,
						not onClear and printerData.markups.trans.attributes.loopTween and true or false
					),
					{Transparency = transTweenGoal}
				)
				
				tween.Completed:Once(function()
					if tweens[stroke] == tween then
						tweens[stroke] = nil
					end
				end)

				tweens[stroke] = tween
				tween:Play()
				
				if not onClear then
					local connection = obj.onRenderEnded:Once(function(stopped : boolean?)
						if stopped and not printerData.markups.trans.attributes.loopTween then
							tween:Cancel()

							stroke.Transparency = transTweenGoal
						end
					end)
					obj._contentFolder.Destroying:Once(function()	
						tween:Cancel()
						
						connection:Disconnect()
					end)
				end
			else
				stroke.Transparency = transTweenGoal
			end
		end
	end,
	convert = util.stringToBoolean,
	attributes = {
		trans = {
			convert = util.stringToNumber,
			unrequired = true
		},
		thickness = {
			convert = util.stringToNumber,
		},
		color = {
			convert = util.stringToColor3,
		},
	},
	valueAttributes = {},
}

return module
