--!strict

local TextService = game:GetService("TextService")

local memoizer = require("./Memoizer")
local types = require("./Types")
local config = require("./Config")
local flipbookEffect = require("./Markups/Helpers/FlipbookEffect")

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

	for _, markup in pairs(markups :: types.markupsIndexable) do
		local isStackable = markup.stack and true or false
		local stackableMarkup = isStackable and markup :: types.stack<types.markupIndexable>
		local markup = not isStackable and markup :: types.markupIndexable
			or stackableMarkup and stackableMarkup._entryDefaultValues

		if markup then
			markup.value = nil
	
			for k, _ in pairs(markup.attributes) do
				markup.attributes[k] = nil
			end
			for _, attrs in pairs(markup.valueAttributes) do
				for k, _ in pairs(attrs) do
					attrs[k] = nil
				end
			end
		end

		-- if stackableMarkup then
		-- 	table.clear(stackableMarkup.stack)
		-- end
	end

	return markups
end

util.fireDataModuleOnPrint = function(
	obj : types.hyperTextClassObject,
	dataModule : types.dataModuleBase & types.pairedDescriminator,
	printerRowEntry : types.printerDataRowEntry,
	updater : {[string] : (dt : number) -> ()},
	onClear : boolean?
)
	if dataModule.onPrint then
		local constructionData = printerRowEntry.constructionDataRowEntry
		-- TODO: should remove this hot path
		local characterPosition = obj:_GetRowEntryPosition(printerRowEntry.index)
		local spans = util.indexCaseInsensitive(
			obj._constructionData.spans,
			dataModule.name
		)
		local onPrintSpanData : {types.onPrintMarkupSpanData} = {}

		for _, span in ipairs(spans) do
			-- TODO: should make this indexable
			if table.find(span.rowEntryIndices, printerRowEntry.index) then
				table.insert(onPrintSpanData, {
					stackIndex = span.stackIndex,
					rowEntryIndices = span.rowEntryIndices,
					characterSize = Vector2.new(
						constructionData.width,
						constructionData.height
					),
					characterPosition = characterPosition,
					spanSize = span.size,
					spanPosition = span.position,
				})
				
				if not dataModule.stackable then
					break
				end
			end
		end

		dataModule.onPrint(
			obj,
			printerRowEntry,
			dataModule.stackable and onPrintSpanData or onPrintSpanData[1],
			updater,
			onClear
		)
	end
end

util.fireAllDataModuleOnPrints = function(
	obj : types.hyperTextClassObject,
	printerRowEntry : types.printerDataRowEntry,
	updater : {[string] : (dt : number) -> ()},
	exclude : {types.markup}?,
	validate : ((dataModule : types.dataModuleLoose) -> boolean)?
)
	local dataModules = util.getAllMarkupDataModules(exclude)

	for dataModule in util.iterateMarkupDataModulesByPrintPriority(dataModules) do
		if 
			dataModule.type == "paired"
			and dataModule.onPrint
			and (not validate or validate(dataModule))
		then
			util.fireDataModuleOnPrint(obj, dataModule, printerRowEntry, updater)
		end
	end
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

	for _, v in ipairs({
		script.Parent.Markups.Paired,
		script.Parent.Markups.SelfClosing,
		script.Parent.Markups.Programmatic
	}) do
		for _, v in ipairs(v:GetChildren()) do
			if v:IsA("ModuleScript") and (not exclude or not table.find(exclude :: {string}, v.Name)) then
				local module : types.dataModuleLoose? = util.safeRequire(v :: ModuleScript)
	
				if module then
					table.insert(modules, module)
				end
			end
		end
	end

	return modules
end

util.mergeMarkups = function(
	base : types.markups,
	new : types.markups
)
	local function updateBase(
		markupName : string,
		dataModule : types.dataModuleLoose,
		baseMarkup : types.markupIndexable,
		markup : types.markupIndexable
	)
		if markup.value ~= nil then
			if markup.value == util.DELETE_SYNTAX then
				if dataModule.type == "paired" and dataModule.unrequired then
					baseMarkup.value = nil
				else
					warn(
						debug.traceback(
							"Failed to delete markup \""
								.. markupName .. "\": This markup cannot be deleted\nTraceback:"
						)
					)
				end
			else
				local success, errmsg = true, nil

				if dataModule.validateDefaultValue then
					success, errmsg = pcall(
						dataModule.validateDefaultValue,
						markup.value
					)
				end
				
				if success then
					baseMarkup.value = markup.value
				else
					warn(
						debug.traceback(
							"Failed to update markup \""
								.. markupName .. `\": {errmsg}\nTraceback:`
						)
					)
				end
			end
		end

		for attr, value in pairs(markup.attributes) do
			if value ~= nil then
				for dataModuleAttr, data in pairs(dataModule.attributes) do
					if dataModuleAttr == attr then
						if value == util.DELETE_SYNTAX then
							if data.unrequired then
								baseMarkup.attributes[attr] = nil
							else
								warn(
									debug.traceback(
										"Failed to delete attribute \""
											.. attr .. "\" of markup \""
											.. markupName .. "\": This attribute cannot be deleted\nTraceback:"
									)
								)
							end
						else
							local success, errmsg = true, nil

							if data.validateDefaultValue then
								success, errmsg = pcall(
									data.validateDefaultValue,
									value
								)
							end
							
							if success then
								baseMarkup.attributes[attr] = value
							else
								warn(
									debug.traceback(
										"Failed to update attribute \""
											.. attr .. "\" of markup \""
											.. markupName .. `\": {errmsg}\nTraceback:`
									)
								)
							end
						end
					end
				end
			end
		end

		for value, attrs in pairs(markup.valueAttributes) do
			for attr, attrValue in pairs(attrs) do
				if attrValue ~= nil then
					for dataModuleValue, dataModuleAttrs in pairs(dataModule.valueAttributes) do
						if dataModuleValue == value then
							for dataModuleAttr, data in pairs(dataModuleAttrs) do
								if dataModuleAttr == attr then
									if attrValue == util.DELETE_SYNTAX then
										if data.unrequired then
											baseMarkup.valueAttributes[value][attr] = nil
										else
											warn(
												debug.traceback(
													"Failed to delete attribute \""
														.. attr .. "\" of value \""
														.. value .. "\" of markup \""
														.. markupName .. "\": This attribute cannot be deleted\nTraceback:"
												)
											)
										end
									else
										local success, errmsg = true, nil

										if data.validateDefaultValue then
											success, errmsg = pcall(
												data.validateDefaultValue,
												attrValue
											)
										end
										
										if success then
											baseMarkup.valueAttributes[value][attr] = attrValue
										else
											warn(
												debug.traceback(
													"Failed to update attribute \""
													.. attr .. "\" of value \""
													.. value .. "\" of markup \""
													.. markupName .. `\": {errmsg}\nTraceback:`
												)
											)
										end
									end
								end
							end
						end
					end
				end
			end
		end				
	end

	local dataModules = util.getAllMarkupDataModules()
	
	for markupName, markup in pairs(new :: types.markupsIndexable) do
		for _, dataModule in ipairs(dataModules) do
			local name = dataModule.name

			if name == markupName then
				local isStackable = markup.stack and true or false
				local baseMarkup = not isStackable and (base :: types.markupsIndexable)[markupName] :: types.markupIndexable or nil
				local stackableBaseMarkup = isStackable and (base :: types.markupsIndexable)[markupName] :: types.stack<types.markupIndexable> or nil
				local stackableMarkup = isStackable and markup :: types.stack<types.markupIndexable>
				local markup = not isStackable and markup :: types.markupIndexable
		
				if stackableBaseMarkup and stackableMarkup and dataModule.type == "paired" then
					for i, markupEntry : index<index<types.stack<types.markupIndexable>, "stack">, number> in pairs(stackableMarkup.stack) do
						if markupEntry then
							if markupEntry == util.DELETE_SYNTAX then
								stackableBaseMarkup.stack[i] = nil
							else
								local baseMarkupEntry = stackableBaseMarkup.stack[i]

								if baseMarkupEntry then
									updateBase(markupName, dataModule, baseMarkupEntry, markupEntry)
								else
									local entry = util.deepCopy(stackableBaseMarkup._entryDefaultValues)
									updateBase(markupName, dataModule, entry, markupEntry)
	
									stackableBaseMarkup.stack[i] = entry
								end
							end
						end
					end
				elseif baseMarkup and markup then
					updateBase(markupName, dataModule, baseMarkup, markup)
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
	isStackable : boolean?,
	revertStack : boolean?
) : (any, {{attr : string, schemaAttr : string, value : any, markupValue : string?}})
	local previousAttrsValues : {{attr : string, schemaAttr : string, value : any, markupValue : string?}} = {}
	local markup = not isStackable and util.indexCaseInsensitive(base :: types.markupsIndexable, type_) :: types.markupIndexable?
	local stackableMarkup = isStackable and util.indexCaseInsensitive(base :: types.markupsIndexable, type_) :: types.stack<types.markupIndexable>?
	local previousValue : any

	if stackableMarkup then
		if not revertStack then
			previousValue = util.deepCopy(stackableMarkup.stack)
		end
	elseif markup then
		previousValue = markup.value == nil and util.DELETE_SYNTAX or markup.value
	end

	if value ~= nil then
		if value == util.DELETE_SYNTAX then
			if markup then
				markup.value = nil
			end
		elseif stackableMarkup then
			if not revertStack then
				local entry = util.deepCopy(stackableMarkup._entryDefaultValues)
				entry.value = value
				
				local _, i = util.getLastEntryFromStack(stackableMarkup.stack)
				stackableMarkup.stack[i + 1] = entry
			else
				stackableMarkup.stack = value
			end
		elseif markup then
			markup.value = value
		end
	end

	local attrs : index<types.markupIndexable, "attributes">? = markup and markup.attributes or nil
	local valueAttrs : index<types.markupIndexable, "valueAttributes">? = markup and markup.valueAttributes or nil
	if stackableMarkup then
		local entry = util.getLastEntryFromStack(stackableMarkup.stack)

		if entry then
			attrs = entry.attributes
			valueAttrs = entry.valueAttributes
		end
	end

	if not revertStack and attrs and valueAttrs then
		for _, data in ipairs(attrsValues) do
			if not data.markupValue then
				local attrPreviousValue = util.safeIndexCaseInsensitive(attrs, data.attr)

				table.insert(previousAttrsValues, {
					attr = data.attr,
					schemaAttr = data.schemaAttr,
					value = attrPreviousValue,
				})

				if attrPreviousValue ~= nil then
					util.setCaseInsensitive(attrs, data.attr, data.value)
				elseif data.value ~= nil then
					attrs[data.schemaAttr] = data.value
				end
			else
				local valueAttrs = util.indexCaseInsensitive(valueAttrs, data.markupValue)
				local previousValue = util.safeIndexCaseInsensitive(valueAttrs, data.attr)

				table.insert(previousAttrsValues, {
					attr = data.attr,
					schemaAttr = data.schemaAttr,
					value = previousValue,
					markupValue = data.markupValue,
				})

				if previousValue ~= nil then
					util.setCaseInsensitive(valueAttrs, data.attr, data.value)
				elseif data.value ~= nil then
					valueAttrs[data.schemaAttr] = data.value
				end
			end
		end
	end

	return previousValue, previousAttrsValues
end

type textBoundsCacheSchema = {
	[string] : {
		[number | string] : {
			[number] : {
				[Enum.FontWeight] : {
					[Enum.FontStyle] : Vector2
				}
			}
		}
	}
}

local textBoundsCache = memoizer.new<<textBoundsCacheSchema>>(
	5,
	config.MAX_TEXTBOUNDS_CACHE_RECORDS
)
util.textBoundsCache = textBoundsCache

util.getTextboundsCacheFetschinSchema = function(
	str : string,
	font : number | string,
	size : number,
	weight : Enum.FontWeight,
	style : Enum.FontStyle
) : memoizer.fetchingSchema<textBoundsCacheSchema>
	return {
		[str] = {
			[font] = {
				[size] = {
					[weight] = {
						[style] = function()
							local params = Instance.new("GetTextBoundsParams")
							params.Text = str
							params.Font = typeof(font) == "string"
								and Font.new(font, weight, style)
								or Font.fromId(font :: number, weight, style)
							params.Size = size

							return TextService:GetTextBoundsAsync(params)
						end
					}
				}
			}
		}
	}
end

util.fetchTextBounds = function(
	str : string,
	markups : types.markups,
	proportionalSize : number?
) : Vector2
	local fetschingSchema = util.getTextboundsCacheFetschinSchema(
		str,
		markups.font.value,
		proportionalSize or markups.size.value,
		markups.weight.value,
		markups.italic.value and Enum.FontStyle.Italic or Enum.FontStyle.Normal
	)
	
	return textBoundsCache:Get(fetschingSchema)
end

util.fullyCacheStackableImageMarkup = function(markup : types.stack<types.markupIndexable>, id : number?)
	for _, v in ipairs({markup.stack, {markup._entryDefaultValues} :: {types.markupIndexable?}}) do
		for _, markups in pairs(v) do
			if markups then
				util.cacheImageMarkup(markups, id)
			end
		end
	end
end

util.cacheImageMarkup = function(markup : types.markupIndexable, id : number?)
	if flipbookEffect.shouldApplyFlipbookEffect(markup.attributes) then
		local imageURI = not id and typeof(markup.value) == "string"
			and markup.value
			or "rbxassetid://" .. (id or markup.value)

		flipbookEffect.cacheImageSize(imageURI)
	end
end

util.cacheStackableImageMarkupLastEntry = function(stack : index<types.stack<types.markupIndexable>, "stack">, id : number?)
	local entry = util.getLastEntryFromStack(stack)

	util.cacheImageMarkup(entry, id)
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

util.getLastEntryFromStack = function<T>(
	stack : index<types.stack<T>, "stack">
) : (T, number)
	local i = 0

	for j, _ in pairs(stack) do
		if j > i then
			i = j
		end
	end

	return stack[i], i 
end

util.stringToURI = function(str : string) : string
	local success = pcall(function()
		return util.stringToNumber(str)
	end)
	if success then
		str = "rbxassetid://" .. tostring(str)
	end
	
	return str
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
