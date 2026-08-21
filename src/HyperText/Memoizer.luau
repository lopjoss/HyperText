--[[
	v1.0.0

	Memoizer implementation by @lopjoss

	caching a table works by making the schema's tail a dictionary with a key
	value pair where the key is a singleton "value" and the value is your table

	note that:
	- schemas are meant to have one singular path; multiple keys is not supported
	- recursive fetching of the same schema path is not supported and will never complete
]]

local util = require("./Util")
local signal = require("./Signal")

const RECORD_NIL = function() : any
	return nil
end

type uncertainSchema = {[any] : uncertainSchema}?

type function isSchemaTailUDTF(layer : type) : boolean
	return not (layer:is("table") and (
		not layer:readproperty(types.singleton("value"))
	))
end

type function getValueFromSchemaTailUDTF(tail : type) : type
	if tail:is("table") then
		local value = tail:readproperty(types.singleton("value"))

		if value then
			return value
		else
			error("no value singleton key found in schema's tail of table type")
		end
	else
		return tail
	end
end

type function getTailValueFromSchema(schema : type) : type
	assert(schema:is("table"), "schema must be a table type")

	local current : type = schema

	while true do
		local indexer = current:readindexer()
		
		if indexer then 
			if not isSchemaTailUDTF(indexer.result) then
				current = indexer.result
			else
				return getValueFromSchemaTailUDTF(indexer.result)
			end
		else
			error("no indexer found in schema layer")
		end
	end
end

export type function fetchingSchema(schema : type) : type
	assert(schema:is("table"), "schema must be a table type")

	local current : type = schema

	while true do
		local indexer = current:readindexer()
		
		if indexer then
			if not isSchemaTailUDTF(indexer.result) then
				local new = indexer.result
				current:setindexer(indexer.index, new)
				current = new
			else
				current:setindexer(indexer.index, types.newfunction(
					nil,
					{
						head = {getValueFromSchemaTailUDTF(indexer.result)}
					}
				))

				break
			end
		else
			error("no indexer found in schema layer")
		end
	end

	return schema
end

type function pendingSchema(schema : type) : type
	assert(schema:is("table"), "schema must be a table type")

	local current : type = schema

	while true do
		local indexer = current:readindexer()
		
		if indexer then
			if not isSchemaTailUDTF(indexer.result) then
				local new = indexer.result
				current:setindexer(indexer.index, new)
				current = new
			else
				current:setindexer(indexer.index, types.newtable(
					nil,
					{
						index = types.number,
						readresult = types.thread,
						writeresult = types.thread,
					}
				))

				break
			end
		else
			error("no indexer found in schema layer")
		end
	end

	return schema
end

local function isSchemaTail(layer : any) : boolean
	return not (type(layer) == "table" and not layer["value"])
end

local function getValueFromSchemaTail(tail : any) : any
	if type(tail) == "table" then
		return tail["value"]
	else
		return tail
	end
end

local function iterateSchema(schema : {[any] : any})
	local currentSchemaLayer : {[unknown] : any} = schema
	local completed = false

	return function() : (unknown?, any)
		if not completed then
			local k, v = next(currentSchemaLayer)

			if k ~= nil then
				if not isSchemaTail(v) then
					currentSchemaLayer = v
				else
					completed = true
				end
				
				return k, v
			else
				error("no key value pair found in schema layer")
			end
		else
			return nil
		end
	end
end

local function getDictionaryLength(dict : {[any] : any}) : number
	local amount = 0

	for _, _ in pairs(dict) do
		amount += 1
	end

	return amount
end

local module = {}
module.__index = module

type classContent<T> = {
	_cache : T,
	_pending : pendingSchema<T>
}

type classMethods<T> = {
	_ClearPending : (
		self : classType<T>,
		schema : T,
		throwResult : boolean?
	) -> (),
	Record : (
		self : classType<T>,
		schema : T
	) -> (),
	Get : (
		self : classType<T>,
		schema : fetchingSchema<T>
	) -> getTailValueFromSchema<T>,
}

export type classType<T> = classContent<T> & classMethods<T>

module.new = function<T>() : classType<T>
	local classContent : classContent<T> = {
		_cache = {},
		_pending = {} :: pendingSchema<T>,
	}

	return setmetatable(classContent, module) :: any
end

module._ClearPending = function<T>(
	self : classType<T>,
	schema : T,
	throwResult : boolean?
)
	local pathBranchRootKey : any = next(schema)
	local pathBranchRootLayer : {[any] : any} = self._pending
	local currentPendingSchemaLayer : {[any] : uncertainSchema}? = self._pending

	for k, v in iterateSchema(schema) do
		local nextPendingSchemaLayer = currentPendingSchemaLayer
			and currentPendingSchemaLayer[k]

		if nextPendingSchemaLayer then
			if not isSchemaTail(v) then
				currentPendingSchemaLayer = nextPendingSchemaLayer

				if getDictionaryLength(currentPendingSchemaLayer) > 1 then
					pathBranchRootLayer = currentPendingSchemaLayer
					pathBranchRootKey = next(v)
				end
			else
				local threads = nextPendingSchemaLayer :: {thread}

				pathBranchRootLayer[pathBranchRootKey] = nil
				
				for _, thread in ipairs(threads) do
					pcall(function()
						task.spawn(
							thread,
							not throwResult,
							if v ~= RECORD_NIL then v else RECORD_NIL()
						)
					end)
				end
			end
		else
			break
		end
	end
end

module.Record = function<T>(
	self : classType<T>,
	schema : T
)
	local currentCacheSchemaLayer : {[any] : uncertainSchema} = self._cache
	local currentPendingSchemaLayer : {[any] : uncertainSchema}? = self._pending

	for k, v in iterateSchema(schema) do
		local nextCacheSchemaLayer = currentCacheSchemaLayer[k]
		local nextPendingSchemaLayer = currentPendingSchemaLayer
			and currentPendingSchemaLayer[k]

		if not isSchemaTail(v) then
			local newCacheSchemaLayer

			if not nextCacheSchemaLayer then
				newCacheSchemaLayer = {}
				currentCacheSchemaLayer[k] = newCacheSchemaLayer
			else
				newCacheSchemaLayer = nextCacheSchemaLayer
			end
	
			currentCacheSchemaLayer = newCacheSchemaLayer
			currentPendingSchemaLayer = nextPendingSchemaLayer
		else
			currentCacheSchemaLayer[k] = v
	
			if nextPendingSchemaLayer then
				self:_ClearPending(schema)
			end
		end
	end
end

module.Get = function<T>(
	self : classType<T>,
	schema : fetchingSchema<T>
) : getTailValueFromSchema<T>
	local currentCacheSchemaLayer : {[any] : uncertainSchema}? = self._cache

	for k, v in iterateSchema(schema) do
		local nextCacheSchemaLayer = currentCacheSchemaLayer and currentCacheSchemaLayer[k]

		if not isSchemaTail(v) then
			currentCacheSchemaLayer = nextCacheSchemaLayer
		elseif nextCacheSchemaLayer ~= nil then
			nextCacheSchemaLayer = nextCacheSchemaLayer :: getTailValueFromSchema<T>
			
			return if nextCacheSchemaLayer ~= RECORD_NIL 
				then getValueFromSchemaTail(nextCacheSchemaLayer)
				else RECORD_NIL()
		else
			local currentPendingSchemaLayer : {[any] : uncertainSchema} = self._pending
			local isInitiater = false
			local threads : {thread} = {}
	
			for k, v in iterateSchema(schema) do
				local nextPendingSchemaLayer = currentPendingSchemaLayer[k]
	
				if not isSchemaTail(v) then
					local newPendingSchemaLayer
	
					if not nextPendingSchemaLayer then
						newPendingSchemaLayer = {}
						currentPendingSchemaLayer[k] = newPendingSchemaLayer
					else
						newPendingSchemaLayer = nextPendingSchemaLayer
					end
	
					currentPendingSchemaLayer = newPendingSchemaLayer
				elseif nextPendingSchemaLayer then
					threads = nextPendingSchemaLayer :: {thread}
				else
					isInitiater = true

					currentPendingSchemaLayer[k] = threads
				end
			end
	
			local success : boolean, value : any

			if isInitiater then
				local completed = false
				local signal = signal.new()

				task.spawn(function()
					success, value = pcall(v)
	
					if type(value) == "table" then
						value = {
							value = value
						}
					end

					local newSchema = util.deepCopy(schema)
					local currentNewSchemaLayer : {[any] : any} = newSchema
					for k, v in iterateSchema(newSchema) do
						if isSchemaTail(v) then
							currentNewSchemaLayer[k] = value == nil
								and RECORD_NIL
								or value
						else
							currentNewSchemaLayer = currentNewSchemaLayer[k]
						end
					end
	
					if success then
						self:Record(newSchema)
					else
						self:_ClearPending(newSchema, true)
					end

					signal:Fire()

					completed = true
				end)

				if not completed then
					signal:Wait()
				end
			else
				table.insert(threads, coroutine.running())

				success, value = coroutine.yield()
			end

			if success then
				return getValueFromSchemaTail(value)
			else
				error(`failed to fetch value: {value}`)
			end
		end
	end

	error("schema iteration did not return any value")
end

return module
