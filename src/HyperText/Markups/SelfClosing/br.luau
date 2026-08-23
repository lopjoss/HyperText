--!strict

local types = require("../../Types")
local util = require("../../Util")

local name : "br" = "br"
local type_ : "selfClosing" = "selfClosing"
local module : types.dataModule<typeof(name), typeof(type_)> = {
	type = type_,
	name = name,
	
	onConstruction = function(
		obj : types.hyperTextClassObject,
		markups : types.markups
	)
		for i = 1, markups.br.value do
			obj:_CreateRow(markups)
		end
		
		obj._printerScheduler:Append(function()
			local created = 0

			for i, row in ipairs(obj._constructionData.rows) do
				if not row.instance and created < markups.br.value then
					local rowInstance = obj:_CreateRowInstance(row.height, i)

					row.instance = rowInstance

					created += 1
				end
			end
		end)
	end,
	convert = function(value : string)
		return math.floor(util.stringToNumber(value, 1))
	end,
	attributes = {},
	valueAttributes = {},
}

return module
