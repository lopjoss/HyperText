-- TODO: add support for caching table values with singleton keys

--[[
	Memoizer by @lopjoss

	currently does not support caching table values with a primitive indexer
]]

local util = require("./Util")

const RECORD_NIL_SYNTAX = "__MEMO_SCHEMA_NIL"

type function getValueFromSchema(schema : type) : type
	assert(schema:is("table"), "schema must be a table type")

	local current : type = schema

	while true do
		local indexer = current:readindexer()
		
		if indexer then
			if not indexer.result:is("table") then
				return indexer.result
			else
				current = indexer.result
			end
		else
			error("no indexer")
		end
	end
end

type function shaveSchema(schema : type) : type
	assert(schema:is("table"), "schema must be a table type")

	local current : type = schema

	while true do
		local indexer = current:readindexer()
		
		if indexer then
			if indexer.result:is("table") then
				local new = indexer.result
				current:setindexer(indexer.index, new)
				current = new
			else
				current:setindexer(indexer.index, types.newfunction(
					nil,
					{
						head = {indexer.result}
					}
				))

				break
			end
		else
			error("no indexer")
		end
	end

	return schema
end

local function parseSchema<T>(
	schema : {[any] : any},
	callback : (k : any, v : any, currentSchemaLayer : {[any] : any}) -> T?
) : T?
	local currentSchemaLayer : {[any] : any} = schema

	while true do
		local iterator, state = pairs(currentSchemaLayer)
		local k, v = iterator(state)

		if k ~= nil then
			local returned = callback(k, v, currentSchemaLayer)

			if returned then
				return returned
			elseif type(v) == "table" then
				currentSchemaLayer = v
			else
				break
			end
		else
			error("no key value pair found in schema")
		end
	end

	return nil
end

local module = {}
module.__index = module

export type classType<T> = setmetatable<{
	_cache : T,
	_pending : T,
}, typeof(module)>

module.new = function<T>() : classType<T>
	local self = setmetatable({
		_cache = {},
		_pending = {},
	}, module)

	return self
end

module.ClearPending = function<T>(
	self : classType<T>,
	schema : T,
	throwResult : boolean?
)
	local pending = self._pending[pathKey]

	if pending then
		self._pending[pathKey] = nil
		
		for _, thread in ipairs(pending) do
			task.spawn(
				thread,
				not throwResult,
				result ~= RECORD_NIL_SYNTAX and result or nil
			)
		end
	end
end

module.Record = function<T>(
	self : classType<T>,
	schema : T
)
	local currentCacheSchemaLayer : {[any] : any} = self._cache

	parseSchema(schema, function(k, v)
		if type(v) == "table" then
			if not currentCacheSchemaLayer[k] then
				currentCacheSchemaLayer[k] = {}
			end

			currentCacheSchemaLayer = currentCacheSchemaLayer[k]
		else
			currentCacheSchemaLayer[k] = v

			self:ClearPending(schema, v)
		end

		return nil
	end)
end

module.Get = function<T>(
	self : classType<T>,
	schema : shaveSchema<T>
) : getValueFromSchema<T>
	local currentCacheSchemaLayer : {[any] : any}? = self._cache

	local value = parseSchema(schema, function(k, v) : getValueFromSchema<T>?
		if type(v) == "table" then
			currentCacheSchemaLayer = currentCacheSchemaLayer and currentCacheSchemaLayer[k]
		elseif currentCacheSchemaLayer and currentCacheSchemaLayer[k] ~= nil then
			local cachedValue = currentCacheSchemaLayer[k]

			return cachedValue
		else
			local currentPendingSchemaLayer : {[any] : any} = self._pending
			local isInitiater = false

			local threads = parseSchema(schema, function(k, v) : {thread}?
				if type(v) == "table" then
					if not currentPendingSchemaLayer[k] then
						currentPendingSchemaLayer[k] = {}
					end

					currentPendingSchemaLayer = currentPendingSchemaLayer[k]
				elseif currentPendingSchemaLayer[k] then
					return currentPendingSchemaLayer[k]
				else
					isInitiater = true
					currentPendingSchemaLayer[k] = {}

					return currentPendingSchemaLayer[k]
				end

				return nil
			end)

			if threads then
				local success : boolean, value : getValueFromSchema<T>

				if isInitiater then
					success, value = pcall(v :: () -> getValueFromSchema<T>)

					local newSchema = util.deepCopy(schema)
					parseSchema(newSchema, function(k, newSchemaValue, currentSchemaLayer)
						if type(newSchemaValue) ~= "table" then
							currentSchemaLayer[k] = value
						end

						return nil
					end)

					if success then
						self:Record(newSchema)
					else
						self:ClearPending(newSchema, true)
					end
				else
					table.insert(threads, coroutine.running())

					success, value = coroutine.yield()
				end

				if success then
					return value
				else
					error(`failed to fetch value: {value}`)
				end
			else
				error("received no pending thread table")
			end
		end

		return nil
	end)

	if value then
		return value ~= RECORD_NIL_SYNTAX 
			and value
			or nil :: getValueFromSchema<T>
	else
		error("no value received from parse")
	end
end

return module
