--!strict

local scheduler = {}
scheduler.__index = scheduler

export type classType = typeof(
	setmetatable(
		{} :: {
			_queue : {
				{
					callback : () -> (),
					id : (number | string)?
				}
			},
			
			index : number?
		},
		scheduler
	)
)

scheduler.new = function() : classType
	local self = setmetatable(
		{
			_queue = {},
			
			index = nil :: number?
		},
		scheduler
	)
	
	return self
end

function scheduler.Append(
	self : classType,
	callback : () -> (),
	id : (number | string)?
) : number
	table.insert(self._queue, {
		callback = callback,
		id = id
	})
	
	return #self._queue
end

function scheduler.Insert(
	self : classType,
	pos : number, callback : () -> (),
	id : (number | string)?
)
	if pos <= #self._queue then
		table.insert(self._queue, pos, {
			callback = callback,
			id = id
		})
	else
		self:Append(callback, id)
	end
end

function scheduler.Iterate(
	self : classType,
	fromIndex : number?,
	ids : {(number | string)}?
)
	for i, entry in ipairs(self._queue) do
		if not fromIndex or i >= fromIndex then
			self.index = i
			
			if not ids or entry.id and table.find(ids, entry.id) then
				entry.callback()
			end
		end
	end
end

function scheduler.Empty(self : classType)
	self._queue = {}
end

return scheduler
