--!strict

local types = require("../../Types")

local name : "renderEvent" = "renderEvent"
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
		obj.renderEvent:Fire(markups.renderEvent.value)
	end,
	convert = function(value : string)
		return value
	end,
	attributes = {},
	valueAttributes = {},
}

return module
