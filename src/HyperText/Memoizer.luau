--!strict

--[[
	v1.3.1

	Memoizer implementation by @lopjoss

	caching a table works by making the schema's tail a dictionary with a key
	value pair where the key is a singleton "value" and the value is your table

	note that schemas are meant to have one singular path; multiple keys is not
	supported
]]

type schemaLayer = {[any] : schemaLayer}
type uncertainSchemaLayer = {[any] : uncertainSchemaLayer?}
type pendingSchemaTail = {
	pending : {thread},
	initiator : thread
}
type cacheRecord = {
	key : any,
	layer : schemaLayer
}

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
			error("No value singleton key found in schema's tail of table type")
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
			error("No indexer found in schema layer")
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
			error("No indexer found in schema layer")
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
					{
						[types.singleton("pending")] = types.newtable(
								nil,
							{
								index = types.number,
								readresult = types.thread,
								writeresult = types.thread,
							}	
						),
						[types.singleton("initiator")] = types.thread,
					}
				))

				break
			end
		else
			error("No indexer found in schema layer")
		end
	end

	return schema
end

const RECORD_NIL = function() : any
	return nil
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

local function iterateSchema(schema : schemaLayer)
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
				error("No key value pair found in schema layer")
			end
		else
			return nil
		end
	end
end

local function hasMultipleBranches(schema : schemaLayer) : boolean
	local first = next(schema)

	return first ~= nil and next(schema, first) ~= nil
end

local module = {}
module.__index = module

type classContentCacheCeiling<T> = classContentBase<T> & {
	_keyByLayer : {[schemaLayer] : any},
	_parentByLayer : {[schemaLayer] : schemaLayer},

	_maxCacheRecords : number,
	_cacheRecords : {[number] : cacheRecord},
	_cacheRecordsCount : number,
	_oldestCacheRecordIndex : number,
	_cacheRecordsInsertionIndex : number,
}

type classContentBase<T> = {
	_cache : T,
	_pending : pendingSchema<T>,
	_maxAttempts : number,
}

type classContent<T> = {
	_maxCacheRecords : number?
} & (
	classContentCacheCeiling<T> | (
		classContentBase<T> & {
			_maxCacheRecords : nil
		}
	)
)

type classMethods<T> = {
	_ClearPending : (
		self : classType<T>,
		schema : T,
		throwResult : boolean?
	) -> (),
	_PruneCacheRecord : (
		self : classContentCacheCeiling<T> & classMethods<T>,
		index : number
	) -> (),
	ClearCache : (
		self : classType<T>
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

module.new = function<T>(
	maxAttempts : number?,
	maxCacheRecords : number?
) : classType<T>
	local classContent: classContent<T>

	if maxCacheRecords ~= nil then
		local withCacheCeiling : classContentCacheCeiling<T> = {
			_cache = {},
			_pending = {} :: pendingSchema<T>,
			_maxAttempts = math.max(maxAttempts or 1, 1),

			_maxCacheRecords = math.max(1, math.round(maxCacheRecords)),
			_cacheRecords = {},
			_cacheRecordsCount = 0,
			_oldestCacheRecordIndex = 1,
			_cacheRecordsInsertionIndex = 1,
			_keyByLayer = {},
			_parentByLayer = {},
		}

		classContent = withCacheCeiling :: any
	else
		local base : classContentBase<T> = {
			_cache = {},
			_pending = {} :: pendingSchema<T>,
			_maxAttempts = math.max(
				maxAttempts and math.round(maxAttempts) or 1,
				1
			),
			_maxCacheRecords = nil,
		}

		classContent = base :: any
	end

	return setmetatable(classContent, module) :: any
end

module._ClearPending = function<T>(
	self : classType<T>,
	schema : T,
	throwResult : boolean?
)
	local branchRootKey : any = next(schema)
	local branchRootLayer : schemaLayer = self._pending
	local currentPendingSchemaLayer : schemaLayer = self._pending

	for k, v in iterateSchema(schema) do
		local nextPendingSchemaLayer = currentPendingSchemaLayer[k]

		if not isSchemaTail(v) then
			currentPendingSchemaLayer = nextPendingSchemaLayer

			if hasMultipleBranches(currentPendingSchemaLayer) then
				branchRootLayer = currentPendingSchemaLayer
				branchRootKey = next(v)
			end
		else
			nextPendingSchemaLayer = nextPendingSchemaLayer :: pendingSchemaTail

			if 
				coroutine.running() ~= nextPendingSchemaLayer.initiator
				and coroutine.status(nextPendingSchemaLayer.initiator) ~= "dead"
			then
				task.cancel(nextPendingSchemaLayer.initiator)
			end

			branchRootLayer[branchRootKey] = nil
			
			for _, thread in ipairs(nextPendingSchemaLayer.pending) do
				pcall(
					task.spawn,
					thread, 
					not throwResult, 
					if v ~= RECORD_NIL then v else RECORD_NIL()
				)
			end
		end
	end
end

module._PruneCacheRecord = function<T>(
	self : classContentCacheCeiling<T> & classMethods<T>,
	index : number
)
	local record = self._cacheRecords[index]
	local currentKey = record.key
	local currentLayer = record.layer

	while 
		currentLayer ~= self._cache
		and not hasMultipleBranches(currentLayer)
	do
		local previousLayer = currentLayer

		currentKey = self._keyByLayer[currentLayer]
		currentLayer = self._parentByLayer[currentLayer]

		self._keyByLayer[previousLayer] = nil
		self._parentByLayer[previousLayer] = nil
	end

	currentLayer[currentKey] = nil
end

module.ClearCache = function<T>(
	self : classType<T>
)
	self._cache = {}

	if self._maxCacheRecords then
		self._keyByLayer = {}
		self._parentByLayer = {}

		self._cacheRecordsCount = 0
		self._oldestCacheRecordIndex = 1
		self._cacheRecordsInsertionIndex = 1
		self._cacheRecords = {}
	end
end

module.Record = function<T>(
	self : classType<T>,
	schema : T
)
	local currentCacheSchemaLayer : {[any] : uncertainSchemaLayer?} = self._cache
	local currentPendingSchemaLayer : uncertainSchemaLayer? = self._pending

	for k, v in iterateSchema(schema) do
		local nextCacheSchemaLayer = currentCacheSchemaLayer[k]
		local nextPendingSchemaLayer = currentPendingSchemaLayer
			and currentPendingSchemaLayer[k]

		if not isSchemaTail(v) then
			local newCacheSchemaLayer : uncertainSchemaLayer

			if not nextCacheSchemaLayer then
				newCacheSchemaLayer = {}

				if self._maxCacheRecords then
					self._keyByLayer[newCacheSchemaLayer :: schemaLayer] = k
					self._parentByLayer[newCacheSchemaLayer :: schemaLayer] = currentCacheSchemaLayer :: schemaLayer
				end

				currentCacheSchemaLayer[k] = newCacheSchemaLayer
			else
				newCacheSchemaLayer = nextCacheSchemaLayer
			end
	
			currentCacheSchemaLayer = newCacheSchemaLayer
			currentPendingSchemaLayer = nextPendingSchemaLayer
		else
			currentCacheSchemaLayer[k] = v

			if nextCacheSchemaLayer == nil and self._maxCacheRecords then
				local record : cacheRecord = {
					layer = currentCacheSchemaLayer :: schemaLayer,
					key = k
				}

				if self._maxCacheRecords == self._cacheRecordsCount then
					self:_PruneCacheRecord(self._oldestCacheRecordIndex)

					self._cacheRecords[self._oldestCacheRecordIndex] = record
					self._oldestCacheRecordIndex += 1
					self._oldestCacheRecordIndex = ((self._oldestCacheRecordIndex - 1) % self._cacheRecordsCount) + 1 
				else
					self._cacheRecords[self._cacheRecordsInsertionIndex] = record
					self._cacheRecordsInsertionIndex += 1
					self._cacheRecordsCount += 1
				end
			end
						
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
	local currentCacheSchemaLayer : uncertainSchemaLayer? = self._cache

	for k, v in iterateSchema(schema) do
		local nextCacheSchemaLayer = currentCacheSchemaLayer and currentCacheSchemaLayer[k]

		if not isSchemaTail(v) then
			currentCacheSchemaLayer = nextCacheSchemaLayer
		elseif nextCacheSchemaLayer ~= nil then
			return if nextCacheSchemaLayer :: getTailValueFromSchema<T> ~= RECORD_NIL 
				then getValueFromSchemaTail(nextCacheSchemaLayer)
				else RECORD_NIL()
		else
			local currentPendingSchemaLayer : {[any] : uncertainSchemaLayer?} = self._pending
			local isInitiator = false
			local pendingSchemaTail : pendingSchemaTail
	
			for k, v in iterateSchema(schema) do
				local nextPendingSchemaLayer = currentPendingSchemaLayer[k]
	
				if not isSchemaTail(v) then
					local newPendingSchemaLayer : uncertainSchemaLayer
	
					if not nextPendingSchemaLayer then
						newPendingSchemaLayer = {}
						currentPendingSchemaLayer[k] = newPendingSchemaLayer
					else
						newPendingSchemaLayer = nextPendingSchemaLayer
					end
	
					currentPendingSchemaLayer = newPendingSchemaLayer
				elseif nextPendingSchemaLayer then
					pendingSchemaTail = nextPendingSchemaLayer :: pendingSchemaTail

					if pendingSchemaTail.initiator == coroutine.running() then
						error("Recursive fetching of the same schema path is not supported")
					end
				else
					local newSchema : T = {}
					local currentNewSchemaLayer : schemaLayer = newSchema
					
					for k, v in iterateSchema(schema) do
						if not isSchemaTail(v) then
							currentNewSchemaLayer[k] = {}
							currentNewSchemaLayer = currentNewSchemaLayer[k]
						end
					end
					
					isInitiator = true
					pendingSchemaTail = {
						pending = {},
						initiator = coroutine.create(function()
							local success : boolean, value : any

							for i = 1, self._maxAttempts do
								success, value = pcall(v)

								if success then
									break
								end
							end
			
							if type(value) == "table" then
								value = {
									value = value
								}
							end

							currentNewSchemaLayer[k] = value == nil
								and RECORD_NIL
								or value
			
							if success then
								self:Record(newSchema)
							else
								self:_ClearPending(newSchema, true)
							end
						end),
					}

					currentPendingSchemaLayer[k] = pendingSchemaTail :: uncertainSchemaLayer
				end
			end
			
			if isInitiator then
				task.defer(pendingSchemaTail.initiator)
			end
			
			table.insert(pendingSchemaTail.pending, coroutine.running())

			local success : boolean, value : any = coroutine.yield()
			
			if success then
				return getValueFromSchemaTail(value)
			else
				error(`Failed to fetch value: {value}`)
			end
		end
	end

	error("Schema iteration did not return any value")
end

return module
