local TweenService = game:GetService("TweenService")

local types = require("../../Types")
local tweens : {[GuiObject] : Tween} = {}

return 	function(
	obj : types.hyperTextClassObject,
	printerData : types.printerDataRowEntry,
	tweenFrom : number,
	tweenTo : number,
	onClear : boolean,
	dur : number?
)
	if obj._contentFolder then
		if tweens[printerData.character] then
			tweens[printerData.character]:Cancel()
		end
		
		if not dur or dur == 0 or tweenTo == tweenFrom then
			if printerData.character:IsA("TextLabel") then
				printerData.character.TextTransparency = tweenTo
			else
				printerData.character.ImageTransparency = tweenTo
			end
		else
			if printerData.character:IsA("TextLabel") then
				printerData.character.TextTransparency = tweenFrom
			else
				printerData.character.ImageTransparency = tweenFrom
			end
			
			local objTween = TweenService:Create(
				printerData.character,
				TweenInfo.new(
					dur,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out,
					not onClear and printerData.markups.trans.attributes.loopTween and -1 or 0,
					not onClear and printerData.markups.trans.attributes.loopTween and true or false
				),
				(
					printerData.character:IsA("TextLabel")
						and {TextTransparency = tweenTo}
						or {ImageTransparency = tweenTo}
				) :: {[string] : any}
			)
			
			objTween.Completed:Once(function()
				if tweens[printerData.character] == objTween then
					tweens[printerData.character] = nil
				end
			end)
			
			tweens[printerData.character] = objTween
			objTween:Play()

			if not onClear then
				local connection = obj.onRenderEnded:Once(function(stopped : boolean?)
					if stopped and not printerData.markups.trans.attributes.loopTween then
						objTween:Cancel()

						if printerData.character:IsA("TextLabel") then
							printerData.character.TextTransparency = tweenTo
						else
							printerData.character.ImageTransparency = tweenTo
						end
					end
				end)
				obj._contentFolder.Destroying:Once(function()	
					objTween:Cancel()
					
					connection:Disconnect()
				end)
			end
		end
	end
end