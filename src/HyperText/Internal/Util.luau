--!strict

local TextService = game:GetService("TextService")

local types = require("./Types")
local config = require("./Config")

local util = {}

util.DELETE_SYNTAX = "__HTDELETE__" :: any

local function deepCopy<T>(tbl : T) : T
	if type(tbl) == 'table' then
		local copy : any = {}

		for k, v in next, tbl, nil do
			copy[deepCopy(k)] = deepCopy(v)
		end

		setmetatable(copy, deepCopy(getmetatable(tbl :: any)))

		return copy
	else
		return tbl
	end
end
util.deepCopy = deepCopy

util.setCaseInsensitive = function<K, V>(dict : {[K] : V}, key : K, value : V)
	local lowerKey = string.lower(key)

	for k, v in pairs(dict) do
		if string.lower(k) == lowerKey then
			dict[k] = value

			return
		end
	end

	error(`Key {key} not found in {dict} (case-insensitive)`, 0)
end

util.indexCaseInsensitive = function<V>(dict : {[string] : V}, key : string) : (V, string)
	local lowerKey = string.lower(key)

	for k, v in pairs(dict) do
		if string.lower(k) == lowerKey then
			return v, k
		end
	end

	error(`Key {key} not found in {dict} (case-insensitive)`, 0)
end

util.safeIndexCaseInsensitive = function<V>(dict : {[string] : V}, key : string) : (V?, string?)
	local lowerKey = string.lower(key)

	for k, v in pairs(dict) do
		if string.lower(k) == lowerKey then
			return v, k
		end
	end

	return nil, nil
end

util.safeRequire = function(module : ModuleScript) : any
	local success, result = pcall(require, module)

	if not success then
		warn(`Failed to require module {module.Name}: {result}`)

		return nil
	else
		return result
	end
end

util.getEmptyMarkups = function() : types.markups
	local markups = util.deepCopy(config.DEFAULT_MARKUPS)

	for _, v in pairs(markups :: types.markupsIndexable) do
		v.value = nil

		for k, _ in pairs(v.attributes) do
			v.attributes[k] = nil
		end
		for _, attrs in pairs(v.valueAttributes) do
			for k, _ in pairs(attrs) do
				attrs[k] = nil
			end
		end
	end

	return markups
end

util.iterateMarkupDataModulesByPrintPriority = function(
	dataModules : {types.dataModuleLoose}
) : () -> types.dataModuleLoose?
	local orderedDataModules : {types.dataModuleLoose} = {}
	local prioritizedNames : {[string] : boolean} = {}

	for _, name in ipairs(config.PRINT_PRIORITY) do
		prioritizedNames[name] = true
	end

	for _, dataModule in ipairs(dataModules) do
		if not prioritizedNames[dataModule.name] then
			table.insert(orderedDataModules, dataModule)
		end
	end

	for _, name in ipairs(config.PRINT_PRIORITY) do
		for _, dataModule in ipairs(dataModules) do
			local dataModuleName = dataModule.name
			
			if dataModuleName == name then
				table.insert(orderedDataModules, dataModule)
			end
		end
	end

	local index = 0

	return function() : types.dataModuleLoose?
		index += 1

		return orderedDataModules[index]
	end
end

util.getAllMarkupDataModules = function(exclude : {types.markup}?) : {types.dataModuleLoose}
	local modules : {types.dataModuleLoose} = {}

	for _, v in ipairs(script.Parent.Markups:GetDescendants()) do
		if v:IsA("ModuleScript") and (not exclude or not table.find(exclude :: {string}, v.Name)) then
			local module : types.dataModuleLoose? = util.safeRequire(v :: ModuleScript)

			if module then
				table.insert(modules, module)
			end
		end
	end

	return modules
end

util.mergeMarkups = function(
	base : types.markups,
	new : types.markups
)
	local dataModules = util.getAllMarkupDataModules()
	
	for markup, data in pairs(new :: types.markupsIndexable) do
		if data.value ~= nil then
			if data.value == util.DELETE_SYNTAX then
				for _, dataModule in ipairs(dataModules) do
					if dataModule.name == markup then
						if dataModule.unrequired then
							(base :: types.markupsIndexable)[markup].value = nil
						else
							warn(
								debug.traceback(
									"Failed to delete the \""
										.. markup .. "\" markup: This markup cannot be deleted\nTraceback:"
								)
							)
						end
					end
				end
			else
				(base :: types.markupsIndexable)[markup].value = data.value
			end
		end

		for attr, value in pairs(data.attributes) do
			if value ~= nil then
				if value == util.DELETE_SYNTAX then
					for _, dataModule in ipairs(dataModules) do
						if dataModule.name == markup then
							for dataModuleAttr, data in pairs(dataModule.attributes) do
								if dataModuleAttr == attr then
									if data.unrequired then
										(base :: types.markupsIndexable)[markup].attributes[attr] = nil
									else
										warn(
											debug.traceback(
												"Failed to delete the \""
													.. attr .. "\" attribute of the \""
													.. markup .. "\" markup: This attribute cannot be deleted\nTraceback:"
											)
										)
									end
								end
							end
						end
					end
				else
					(base :: types.markupsIndexable)[markup].attributes[attr] = value
				end
			end
		end
		for value, attrs in pairs(data.valueAttributes) do
			for attr, attrValue in pairs(attrs) do
				if attrValue ~= nil then
					if attrValue == util.DELETE_SYNTAX then
						for _, dataModule in ipairs(dataModules) do
							if dataModule.name == markup then
								for dataModuleValue, dataModuleAttrs in pairs(dataModule.valueAttributes) do
									if dataModuleValue == value then
										for dataModuleAttr, data in pairs(dataModuleAttrs) do
											if dataModuleAttr == attr then
												if data.unrequired then
													(base :: types.markupsIndexable)[markup].valueAttributes[value][attr] = nil
												else
													warn(
														debug.traceback(
															"Failed to delete the \""
																.. attr .. "\" attribute of the \""
																.. value .. "\" value of the \""
																.. markup .. "\" markup: This attribute cannot be deleted\nTraceback:"
														)
													)
												end
											end
										end
									end
								end
							end
						end
					else
						(base :: types.markupsIndexable)[markup].valueAttributes[value][attr] = attrValue
					end
				end
			end
		end
	end
end

util.updateMarkups = function(
	base : types.markups,
	type_ : string,
	value : any,
	attrsValues : {{attr : string, schemaAttr : string, value : any, markupValue : string?}},
	stackable : boolean?
) : (any, {{attr : string, schemaAttr : string, value : any, markupValue : string?}})
	local previousAttrsValues = {}
	local base = base :: types.markupsIndexable
	local markup = util.indexCaseInsensitive(base, type_)
	local previousValue = markup.value == nil and util.DELETE_SYNTAX or markup.value
	local attrs = markup.attributes

	if value ~= nil then
		if value == util.DELETE_SYNTAX then
			markup.value = nil
		else
			markup.value = value
		end
	end

	for _, data in ipairs(attrsValues) do
		if not data.markupValue then
			local previousValue = util.safeIndexCaseInsensitive(attrs, data.attr)

			table.insert(previousAttrsValues, {
				attr = data.attr,
				schemaAttr = data.schemaAttr,
				value = previousValue,
			})

			if previousValue then
				util.setCaseInsensitive(attrs, data.attr, data.value)
			elseif data.value ~= nil then
				attrs[data.schemaAttr] = data.value
			end
		else
			local valueAttrs = util.indexCaseInsensitive(markup.valueAttributes, data.markupValue)
			local previousValue = util.safeIndexCaseInsensitive(valueAttrs, data.attr)

			table.insert(previousAttrsValues, {
				attr = data.attr,
				schemaAttr = data.schemaAttr,
				value = previousValue,
				markupValue = data.markupValue
			})

			if previousValue then
				util.setCaseInsensitive(valueAttrs, data.attr, data.value)
			elseif data.value ~= nil then
				valueAttrs[data.schemaAttr] = data.value
			end
		end
	end

	return previousValue, previousAttrsValues
end

local MAX_RETRIES = 5
local textBoundsCache : {
	[string] : {
		[number | string] : {
			[number] : {
				[Enum.FontWeight] : {
					[Enum.FontStyle] : Vector2
				}
			}
		}
	}
} = {}
util.fetchTextBounds = function(
	str : string,
	markups : types.markups,
	proportionalSize : number?
) : Vector2
	local styleEnum = markups.italic.value and Enum.FontStyle.Italic or Enum.FontStyle.Normal
	local byFont = textBoundsCache[str]
	local bySize = byFont and byFont[markups.font.value]
	local byWeight = bySize and bySize[proportionalSize or markups.size.value]
	local byStyle = byWeight and byWeight[markups.weight.value]
	local cached = byStyle and byStyle[styleEnum]

	if cached then
		return cached
	end

	local params = Instance.new("GetTextBoundsParams")
	params.Text = str
	params.Font = typeof(markups.font.value) == "string"
		and Font.new(markups.font.value, markups.weight.value, styleEnum)
		or Font.fromId(markups.font.value :: number, markups.weight.value, styleEnum)
	params.Size = proportionalSize or markups.size.value

	local retries = 0

	local function fetch() : Vector2
		local success, textBounds = pcall(function()			
			return TextService:GetTextBoundsAsync(params)
		end)

		if success then
			local byFont = textBoundsCache[str]
			if not byFont then
				byFont = {}
				textBoundsCache[str] = byFont
			end

			local bySize = byFont[markups.font.value]
			if not bySize then
				bySize = {}
				byFont[markups.font.value] = bySize
			end

			local byWeight = bySize[proportionalSize or markups.size.value]
			if not byWeight then
				byWeight = {}
				bySize[proportionalSize or markups.size.value] = byWeight
			end

			local byStyle = byWeight[markups.weight.value]
			if not byStyle then
				byStyle = {}
				byWeight[markups.weight.value] = byStyle
			end

			byStyle[styleEnum] = textBounds

			return textBounds
		else
			if retries < MAX_RETRIES then
				retries += 1

				return fetch()
			else
				warn("Failed to fetch text bounds: " .. tostring(textBounds))

				return Vector2.zero
			end
		end
	end

	return fetch()
end

util.removeEntryFromTransformUpdater = function(
	obj : types.hyperTextClassObject,
	entry : types.printerDataRowEntry,
	name : string
)
	if obj._transformRowEntries[entry] then
		local index = table.find(obj._transformRowEntries[entry], name)
		
		if index then
			table.remove(
				obj._transformRowEntries[entry],
				index
			)
			if #obj._transformRowEntries[entry] == 0 then
				obj._transformRowEntries[entry] = nil

				entry.position = Vector2.zero
				entry.rotation = 0
				entry.character.Position = UDim2.fromScale(0, 0)
				entry.character.Rotation = 0
			end
		end
	end
end

util.addEntryToTransformUpdater = function(
	obj : types.hyperTextClassObject,
	entry : types.printerDataRowEntry,
	name : string
)
	if not obj._transformRowEntries[entry] then
		obj._transformRowEntries[entry] = {name}
	else
		table.insert(obj._transformRowEntries[entry], name)
	end
end

util.getRandomFromRange = function(range : NumberRange) : number
	return (range.Max - range.Min) * math.random() + range.Min
end

util.stringToNumber = function(str : string, min : number?, max : number?) : number
	local number : number?
	
	if string.match(str, "^%-?%d*%.?%d+$") ~= nil then
		number = tonumber(str)
		
		if number == tonumber("inf") then
			error("given number value is too large", 0)
		elseif number == -tonumber("inf") :: number then
			error("given number value is too small", 0)
		end
	end
	
	if 
		number
		and (not min or number >= min)
		and (not max or number <= max)
	then
		return number
	end
	
	error(
		"\"" .. str .. "\" is not a valid number"
			.. (
				min and max
				and ", expected a number ranging from " .. min .. " to " .. max
				or min and ", expected a number above or equal to " .. min
				or max and ", expected a number below or equal to " .. max
				or ""
			),
		0
	)
end

util.stringToNumberRange = function(str : string) : NumberRange
	local min, max = string.match(str, "^([^,]+),([^,]+)$")
	min, max =
		min and util.stringToNumber(min),
		max and util.stringToNumber(max)

	if min and max then
		return NumberRange.new(min, max)
	else
		error("\"" .. str .. "\" is not a valid range format, expected min,max", 0)
	end
end

util.stringToVector2 = function(str : string) : Vector2
	local x, y = string.match(str, "^([^,]+),([^,]+)$")
	x, y =
		x and util.stringToNumber(x),
		y and util.stringToNumber(y)

	if x and y then
		return Vector2.new(x, y)
	else
		error("\"" .. str .. "\" is not a valid 2d vector format, expected x,y", 0)
	end
end

util.stringToBoolean = function(str : string) : boolean
	str = string.lower(str)

	if str == "true" or str == "false" then
		return str == "true"
	end

	error("\"" .. str .. "\" is not a valid boolean", 0)
end

util.stringToColor3 = function(str : string) : Color3
	local color = util.safeIndexCaseInsensitive(config.COLOR_SHORTCUTS :: {[string] : Color3}, str)
	if color then
		return color
	end

	local r, g, b = string.match(str, "^([^,]+),([^,]+),([^,]+)$")
	r, g, b =
		r and util.stringToNumber(r),
		g and util.stringToNumber(g),
		b and util.stringToNumber(b)

	if r and g and b then
		return Color3.fromRGB(r, g, b)
	else
		error("\"" .. str .. "\" is not a valid color format, expected r,g,b or a color shortcut", 0)
	end
end

util.stringToSingletonKey = function<T>(literal : T, value : string) : keyof<T>
	local expected = {}

	for k : string in pairs(literal :: any) do
		if string.lower(k) == string.lower(value) then
			return k :: keyof<typeof(literal)>
		end

		expected[#expected + 1] = "\"" .. k .. "\""
	end

	error(
		"\"" .. value .. "\" is not a valid value, expected "
			.. table.concat(expected, ", "),
		0
	)
end

util.stringToInheritable = function<T>(
	str : string,
	converter : (str : string, ...any) -> T
) : T | "inherit"
	str = string.lower(str)
	
	if str == "inherit" then
		return str
	end
	
	return converter(str)
end

util.stringToColor3Pack = function(value : string) : {Color3}
	local colorPack = {}
	local startIndex = 1

	while startIndex <= #value do
		local separatorIndex = string.find(value, ";", startIndex, true)
		local colorString = if separatorIndex
			then string.sub(value, startIndex, separatorIndex - 1)
			else string.sub(value, startIndex)

		colorPack[#colorPack + 1] = util.stringToColor3(colorString)

		if not separatorIndex then
			break
		end

		startIndex = separatorIndex + 1
	end

	return colorPack
end

local WEIGHTS_MAP : {[string] : Enum.FontWeight} = {
	["thin"] = Enum.FontWeight.Thin,
	["extralight"] = Enum.FontWeight.ExtraLight,
	["light"] = Enum.FontWeight.Light,
	["regular"] = Enum.FontWeight.Regular,
	["medium"] = Enum.FontWeight.Medium,
	["semibold"] = Enum.FontWeight.SemiBold,
	["bold"] = Enum.FontWeight.Bold,
	["extrabold"] = Enum.FontWeight.ExtraBold,
	["heavy"] = Enum.FontWeight.Heavy,
}
util.stringToFontWeight = function(str : string) : Enum.FontWeight
	return util.safeIndexCaseInsensitive(WEIGHTS_MAP, str)
		or error("\"" .. str .. "\" is not a valid member of \"Enum.FontWeight\"", 0)
end

return util
