--!strict

local TweenService = game:GetService("TweenService")

local types = require("../../Types")
local util = require("../../Util")

local objTweens : {[GuiObject] : {Tween}} = {}

local name : "shadow" = "shadow"
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
		if obj._contentFolder and printerData.markups.shadow.value then
			if printerData.character.Parent == printerData.row then
				obj:_CreateRowEntryContainer(printerData, name)
			end
			
			local shadow = (printerData.character.Parent :: GuiObject):FindFirstChild("Shadow") :: TextLabel? 
				or printerData.character:Clone()
			local characterTextSizeConstraint = printerData.character:FindFirstChildWhichIsA("UITextSizeConstraint") :: UITextSizeConstraint
			local shadowTextSizeConstraint = shadow:FindFirstChildWhichIsA("UITextSizeConstraint") :: UITextSizeConstraint
			local shadowStroke = shadow:FindFirstChildWhichIsA("UIStroke")
			
			if shadowStroke then
				for _, v in ipairs(shadowStroke:GetChildren()) do
					v:Destroy()
				end
			end

			for _, v in ipairs(shadow:GetChildren()) do
				if not v:IsA("UITextSizeConstraint") and not v:IsA("UIStroke") then
					v:Destroy()
				end
			end
			
			if not shadow.Parent then
				shadow.TextColor3 = printerData.markups.shadow.attributes.color
				if shadowStroke then
					shadowStroke.Color = printerData.markups.shadow.attributes.color
					shadowStroke.Transparency = not printerData.markups.trans.attributes.tweenDur
						and printerData.markups.stroke.attributes.trans
						or shadowStroke.Transparency
				end
				shadow.Position = UDim2.fromScale(
					printerData.markups.shadow.attributes.offset.X,
					printerData.markups.shadow.attributes.offset.Y
				)
				shadow.Name = "Shadow"
				shadow.ZIndex = printerData.character.ZIndex - 1
				shadow.TextTransparency = not printerData.markups.trans.attributes.tweenDur
					and printerData.markups.shadow.attributes.trans 
					or printerData.character.TextTransparency
				shadow.BackgroundTransparency = 1
				shadow.Parent = printerData.character.Parent
			end
			
			
			if objTweens[shadow] then
				for _, tween in ipairs(objTweens[shadow]) do
					tween:Cancel()
				end
			end
			
			local transTweenGoal = not onClear 
				and (
					printerData.markups.shadow.attributes.trans
					or printerData.markups.trans.value
				) or 1
			local strokeTransTweenGoal = not onClear
				and (
					printerData.markups.shadow.attributes.trans
					or printerData.markups.stroke.attributes.trans
					or printerData.markups.trans.value
				) or 1
			local dur = (not onClear or printerData.markups.clearTransDur.value == "inherit")
				and (printerData.markups.trans.attributes.tweenDur or 0)
				or printerData.markups.clearTransDur.value :: number
			
			if dur ~= 0 then
				shadow.TextTransparency = not onClear and printerData.markups.trans.attributes.tweenFrom
					or shadow.TextTransparency
				
				local tweens : {Tween} = {}
				table.insert(
					tweens, 
					TweenService:Create(
						shadow,
						TweenInfo.new(
							dur,
							Enum.EasingStyle.Linear,
							Enum.EasingDirection.Out,
							not onClear and printerData.markups.trans.attributes.loopTween and -1 or 0,
							not onClear and printerData.markups.trans.attributes.loopTween and true or false
						),
						{TextTransparency = transTweenGoal}
					)
				)
				
				if shadowStroke then
					shadowStroke.Transparency = not onClear and printerData.markups.trans.attributes.tweenFrom
						or shadowStroke.Transparency
					
					table.insert(
						tweens, 
						TweenService:Create(
							shadowStroke,
							TweenInfo.new(
								dur,
								Enum.EasingStyle.Linear,
								Enum.EasingDirection.Out,
								not onClear and printerData.markups.trans.attributes.loopTween and -1 or 0,
								not onClear and printerData.markups.trans.attributes.loopTween and true or false
							),
							{Transparency = strokeTransTweenGoal}
						)
					)
				end
				
				tweens[1].Completed:Once(function()
					if objTweens[shadow] == tweens then
						objTweens[shadow] = nil
					end
				end)
				
				objTweens[shadow] = tweens
				
				for _, tween in ipairs(tweens) do
					tween:Play()
				end
				
				if not onClear then
					local connection = obj.onRenderEnded:Once(function(stopped : boolean?)
						if stopped and not printerData.markups.trans.attributes.loopTween then
							for _, tween in ipairs(tweens) do
								tween:Cancel()
							end
							
							shadow.TextTransparency = transTweenGoal							
							
							if shadowStroke then
								shadowStroke.Transparency = strokeTransTweenGoal
							end
						end
					end)
					obj._contentFolder.Destroying:Once(function()	
						for _, tween in ipairs(tweens) do
							tween:Cancel()
						end
						
						connection:Disconnect()
					end)
				end
			else
				shadow.TextTransparency = transTweenGoal
				
				if shadowStroke then
					shadowStroke.Transparency = strokeTransTweenGoal
				end
			end
			
			if not onClear then
				local function syncShadowSize()
					shadowTextSizeConstraint.MinTextSize = characterTextSizeConstraint.MinTextSize
					shadowTextSizeConstraint.MaxTextSize = characterTextSizeConstraint.MaxTextSize
					shadow.TextSize = printerData.character.TextSize
				end

				characterTextSizeConstraint:GetPropertyChangedSignal("MinTextSize"):Connect(syncShadowSize)
				printerData.character:GetPropertyChangedSignal("TextSize"):Connect(syncShadowSize)
				printerData.character:GetPropertyChangedSignal("Text"):Connect(function()
					shadow.Text = printerData.character.Text
				end)
				printerData.character:GetPropertyChangedSignal("Position"):Connect(function()
					shadow.Position = UDim2.fromScale(
						printerData.character.Position.X.Scale + printerData.markups.shadow.attributes.offset.X,
						printerData.character.Position.Y.Scale + printerData.markups.shadow.attributes.offset.Y
					)
				end)
				printerData.character:GetPropertyChangedSignal("Rotation"):Connect(function()
					shadow.Rotation = printerData.character.Rotation
				end)
			end
		end
	end,
	convert = util.stringToBoolean,
	attributes = {
		color = {
			convert = util.stringToColor3,
		},
		offset = {
			convert = util.stringToVector2,
		},
		trans = {
			convert = util.stringToNumber,
			unrequired = true,
		}
	},
	valueAttributes = {},
}

return module
