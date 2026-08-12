--!strict

local types = require("../../Types")
local util = require("../../Util")

local name : "wait" = "wait"
local type_ : "selfClosing" = "selfClosing"
local appendToCurrentWord : true = true
local module : types.dataModule<typeof(name), typeof(type_), nil, nil, typeof(appendToCurrentWord)> = {
	type = type_,
	name = name,
	appendToCurrentWord = appendToCurrentWord,
	
	getSize = function(obj : types.hyperTextClassObject, markups : types.markups)
		return Vector2.zero
	end,
	onPrint_ = function(
		obj : types.hyperTextClassObject,
		markups : types.markups,
		index : number,
		row : Frame,
		updater : {[string] : (dt : number) -> ()}
	)
		if 
			not obj._pausedRender
			and not obj._ignoreIntervals
			and markups.wait.value > 0
		then
			local fromThread
			
			obj._waitMarkupThread = nil
			
			obj:PauseRender()

			obj._waitMarkupThread = task.delay(markups.wait.value, function()
				fromThread = true

				obj:ResumeRender()
			end)

			coroutine.yield()
			
			if not fromThread and obj._waitMarkupThread then
				task.cancel(obj._waitMarkupThread)
			end
		end 
	end,
	convert = util.stringToNumber,
	attributes = {},
	valueAttributes = {},
}

return module
