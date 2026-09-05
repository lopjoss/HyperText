--!strict

--[[
	HyperText v4.2.3

	Made by @lopjoss

	Github (view API, update log, available markups & attributes, and more):
	https://github.com/lopjoss/HyperText

	Devforum:
	https://devforum.roblox.com/t/hypertext-v413-easily-add-animations-effects-more-to-text-with-this-rich-text-module/4176619
]]

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local util = require("./Util")
local types = require("./Types")
local config = require("./Config")
local scheduler = require("./Scheduler")
local signal = require("./Signal")

local updater : {[string] : (dt : number) -> ()} = {}
local markupDataModules = util.getAllMarkupDataModules()
local defaultMarkupsIndexable = config.DEFAULT_MARKUPS :: types.markupsIndexable

local PARSER_APPEND_STRING_SCHEDULER_ID = 1
local PARSER_APPEND_WHITESPACE_SCHEDULER_ID = 2
local PARSER_APPEND_ROW_ENTRY_SCHEDULER_ID = 3

local HyperText = {}
local methods = {} :: types.hyperTextClassMethods
HyperText.__index = methods

HyperText.DELETE = util.DELETE_SYNTAX :: nil

export type classType = types.hyperTextClassObject

local function yieldWhile(callback : (elapsed : number) -> boolean)
	local elapsed = 0

	while callback(elapsed) do
		elapsed += RunService.Heartbeat:Wait()
	end
end

for dataModule in util.iterateMarkupDataModulesByPrintPriority(markupDataModules) do
	local isStackable = dataModule.type == "paired" and dataModule.stackable
	local markup = not isStackable 
		and defaultMarkupsIndexable[dataModule.name] :: types.markupIndexable
	local stackableMarkup = isStackable 
		and defaultMarkupsIndexable[dataModule.name] :: types.stack<types.markupIndexable>

	if markup or stackableMarkup then
		local function process(markup : types.markupIndexable)
			if markup.value ~= nil then
				if dataModule.validateDefaultValue then
					dataModule.validateDefaultValue(markup.value)
				end
			elseif dataModule.type ~= "paired" or not dataModule.unrequired then
				error(`Markup {dataModule.name} has no assigned value in the default markup list`)
			end

			for dataModuleAttr, data in pairs(dataModule.attributes) do
				local valid = false

				for attr, value in pairs(markup.attributes) do
					if attr == dataModuleAttr then
						valid = true

						if data.validateDefaultValue then
							data.validateDefaultValue(value)
						end

						break
					end
				end

				if not valid and not data.unrequired then
					error(`Attribute "{dataModuleAttr}" of markup "{dataModule.name}" was not found in the default markups list`)
				end
			end

			for dataModuleValue, dataModuleAttrs in pairs(dataModule.valueAttributes) do
				for dataModuleAttr, data in pairs(dataModuleAttrs) do
					local valueFound = false

					for value, attrs in pairs(markup.valueAttributes) do
						if value == dataModuleValue then
							valueFound = true

							local valid = false

							for attr, attrValue in pairs(attrs) do
								if attr == dataModuleAttr then
									valid = true

									if data.validateDefaultValue then
										data.validateDefaultValue(attrValue)
									end

									break
								end
							end

							if not valid and not data.unrequired then
								error(`Attribute "{dataModuleAttr}" of value "{value}" of markup "{dataModule.name}" was not found in the default markups list`)
							end

							break
						end
					end

					if not valueFound then
						error(`Value attributes of value "{dataModuleValue}" of markup "{dataModule.name}" were not found in the default markups list`)
					end
				end
			end
		end

		if markup then
			process(markup)
		elseif stackableMarkup then
			for _, markups in pairs(stackableMarkup.stack) do
				if markups then
					process(markups)
				end
			end

			process(stackableMarkup._entryDefaultValues)
		end
	else	
		error(`Markup "{dataModule.name}" was not found in the default markups list`)
	end
end

for dataModule in util.iterateMarkupDataModulesByPrintPriority(markupDataModules) do
	if dataModule.onDefaultMarkupsChanged then
		dataModule.onDefaultMarkupsChanged(config.DEFAULT_MARKUPS)
	end
end

--[[
	Creates and returns a new HyperText object.

	container: GuiObject
	The GuiObject that will contain any rendered content. When it gets destroyed, the object gets destroyed too.

	markups: markups?
	Calls <code>:UpdateDefaultMarkups()</code> with the given markups dict if provided.
	Obtained from calling <code>.newMarkups()</code>.
]]
HyperText.new = function(
	container : GuiObject,
	markups : types.markups?
) : types.hyperTextClassObject
	local self = setmetatable(
		{
			_container = container,
			_markups = util.deepCopy(config.DEFAULT_MARKUPS),
			_printerScheduler = scheduler.new(),
			_constructionScheduler = scheduler.new(),
			_rowEntriesTransformUpdaterId = HttpService:GenerateGUID(),
			_transformRowEntries = {},
			_constructionData = {
				rows = {},
				rowEntries = {},
				spans = {},
			},
			_printerData = {
				rowEntries = {},
			},
			
			rendering = false,
			onRenderEnded = signal.new(),
			renderEvent = signal.new(),
		},
		HyperText
	) :: types.hyperTextClassObject
	
	self._destroyCon = container.Destroying:Once(function()
		self:Destroy()
	end)
	
	updater[self._rowEntriesTransformUpdaterId] = function()
		task.defer(function()
			for entry, _ in pairs(self._transformRowEntries) do
				entry.character.Position = UDim2.fromScale(
					entry.position.X,
					entry.position.Y
				)
				entry.character.Rotation = entry.rotation

				entry.position = Vector2.zero
				entry.rotation = 0
			end
		end)
	end

	if markups then
		local success, result = pcall(function()
			self:UpdateDefaultMarkups(markups)
		end)

		if not success then
			self:Destroy()
			
			error(result, 0)
		end
	end

	return self
end

--[[
	Returns a full markups shaped dict with values/attributes emptied to nil, except for a stackable markup's stack, which retains its default stack entries. Used for updating an object's default markups. To delete an optional default markup or attribute, set its value to `HyperText.DELETE`. For stackable markups, the following operations can be done (note that stack tables behave as dictionaries, not arrays):

	```luau
	local markups = HyperText.newMarkups()

	-- alter an entry by getting it from a stack at a specific index
	local entry = markups.emitImg.stack[1]
	if entry then
		entry.value = 123
	end

	-- add to a stack at a specific index
	local entry = HyperText.insertStackEntry(markups.emitImg, 3)
	entry.value = 123

	-- remove from a stack
	markups.emitImg.stack[2] = HyperText.DELETE
	```
]]
HyperText.newMarkups = function()
	return util.getEmptyMarkups()
end

--[[
	Returns a new markup stack entry with values/attributes emptied to nil, which is inserted into a stackable markup at the given index. Negative or extremely large indices will cause unintended behaviour.
]]
HyperText.insertStackEntry = function<T>(
	markup : types.stack<T>,
	index : number
) : T
	local default = util.deepCopy(markup._entryDefaultValues)
	markup.stack[index] = default

	return default
end

methods.UpdateDefaultMarkups = function(
	self : types.hyperTextClassObject,
	markups : types.markups
)
	util.mergeMarkups(self._markups, markups)

	for dataModule in util.iterateMarkupDataModulesByPrintPriority(markupDataModules) do
		if dataModule.onDefaultMarkupsChanged then
			dataModule.onDefaultMarkupsChanged(self._markups)
		end
	end
end

methods.Render = function(
	self : types.hyperTextClassObject,
	text : string,
	yield : boolean?,
	wrapped : boolean?,
	constructOnly : boolean?
)
	local source, line = debug.info(2, "sl")
	local renderTraceback = string.format("Resulting from Render call at:\n%s Line %s", source, line)
	local destroyed = self._destroyed
	self._renderTraceback = renderTraceback
	
	local container = self._container
	
	self:Clear(true)
	
	if not destroyed then
		if container.AbsoluteSize.Magnitude > 0 then
			local automaticSizeX = self._markups.sizeConstraint.value == Enum.SizeConstraint.RelativeYY
				and self._markups.scaleDimension.value == "Y"
				and self._container.AutomaticSize == Enum.AutomaticSize.X
			
			if 
				container.AbsoluteSize.X ~= 0
				or automaticSizeX
			then
				local automaticSizeY = self._markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXX
					and self._container.AutomaticSize == Enum.AutomaticSize.Y
					and self._markups.scaleDimension.value == "X"
				
				if 
					container.AbsoluteSize.Y ~= 0
					or automaticSizeY
				then
					wrapped = wrapped or wrapped == nil and true
					if wrapped and automaticSizeX then
						warn("wrapped is set to true but the render is configured for horizontal automatic sizing, this is likely unintended")	
						
						wrapped = false
					end
					
					for _, v in pairs(self._constructionData :: {[string] : {any}}) do
						table.clear(v)
					end
					for _, v in pairs(self._printerData :: {[string] : {any}}) do
						table.clear(v)
					end
					
					local renderId = HttpService:GenerateGUID()
					self._renderId = renderId
					self._yieldingFromIntervalMarkup = false
					self._text = text
					local constructionMarkups = util.deepCopy(self._markups)
					self._constructionMarkups = constructionMarkups
					self._wrapped = wrapped
					self._pausedRender = false
					self._markupIndices = {}
					self._markupHistory = {}
					self._currentWord = {}
					self._ignoreIntervals = false
					self._clearingRender = false
					self._firstRowEntryIndex = nil
					self._printerScheduler:Empty()
					self._constructionScheduler:Empty()
					self._containerDefaultAbsoluteSize = container.AbsoluteSize

					for _, dataModule in ipairs(markupDataModules) do
						if dataModule.type == "paired" then
							self._constructionData.spans[dataModule.name] = {}

							if not dataModule.stackable then
								self:_CreateSpan(dataModule.name)
							else
								local defaultStack = (self._markups :: {[string] : types.stack<types.markupIndexable>})[dataModule.name].stack

								for i, markups in pairs(defaultStack) do
									self:_CreateSpan(dataModule.name, i)
								end
							end
						end
					end
					
					local contentFolder = Instance.new("Folder", container)
					contentFolder.Name = "HyperTextContent"
					self._contentFolder = contentFolder
					
					local executionThread = coroutine.create(function()
						self.rendering = true
						self._constructing = true

						local traceback : string?

						local success = xpcall(
							function()
								self:_CreateRow()
								self:_ParseText()
								self._constructionScheduler:Iterate()
							end,
							function(errmsg : any)
								traceback = debug.traceback("Cancelled render due to a construction error: " .. tostring(errmsg) .. "\nTraceback:")
							end
						)
						
						self._constructing = false

						if success and not constructOnly then
							self._constructionScheduler:Iterate(nil, {
								PARSER_APPEND_STRING_SCHEDULER_ID,
								PARSER_APPEND_ROW_ENTRY_SCHEDULER_ID
							})

							local currentWord = self._currentWord		

							if currentWord then
								local firstEntry = currentWord[1]

								if firstEntry.word then
									local first = utf8.graphemes(firstEntry.word.str)()

									self._firstRowEntryIndex = firstEntry.word.index + first - 1
								elseif firstEntry.selfClosingMarkup then
									self._firstRowEntryIndex = firstEntry.selfClosingMarkup.index
								end

								self._currentWord = nil
							end

							local layout = Instance.new("UIListLayout", self._contentFolder)
							layout.VerticalAlignment = constructionMarkups.verticalAlignment.value
							layout.SortOrder = Enum.SortOrder.Name
							self._layout = layout

							success = xpcall(
								function()
									self:_OverflowCheck()
									self:_MapConstructionData()
									self:_InitSpanData()
									self._printerScheduler:Iterate()
								end,
								function(errmsg : any)
									traceback = debug.traceback("Render aborted due to an error: " .. tostring(errmsg) .. "\nTraceback:")
								end
							)
							
							self.onRenderEnded:Fire(self._ignoreIntervals)
						end
						
						self.rendering = false

						if not success then
							error(traceback, 0)
						end
					end)

					self._executionThread = executionThread

					local success, errmsg = coroutine.resume(executionThread)

					if not success then
						warn(errmsg :: string .. renderTraceback)
					end

					if yield then
						yieldWhile(function()
							return self.rendering and self._renderId == renderId
						end)
					end
				else
					warn("Cannot render: object's container has an absolute height of 0\n" .. renderTraceback)
				end
			else
				warn("Cannot render: object's container has an absolute width of 0\n" .. renderTraceback)
			end
		else
			warn("Cannot render: object's container has an absolute size of 0, 0\n" .. renderTraceback)
		end
	else
		warn("Cannot render: object is destroyed")
	end
end

methods.CompleteRender = function(self : types.hyperTextClassObject)
	local rendering = self.rendering
	
	if rendering then
		self._ignoreIntervals = true

		self:ResumeRender(true)
	end
end

methods.PauseRender = function(self : types.hyperTextClassObject)
	if self._waitMarkupThread then
		task.cancel(self._waitMarkupThread)
	end

	self._pausedRender = true
end

methods.ResumeRender = function(
	self : types.hyperTextClassObject,
	_ignoreIntervalMarkupYield : boolean?
)
	local pausedRender = self._pausedRender
	local executionThread = self._executionThread
	local constructing = self._constructing

	if _ignoreIntervalMarkupYield or pausedRender then
		self._pausedRender = false
		
		if
			executionThread
			and not constructing
			and coroutine.status(executionThread) == "suspended"
			and (_ignoreIntervalMarkupYield or not self._yieldingFromIntervalMarkup)
		then
			local success, errmsg = coroutine.resume(
				executionThread,
				self._yieldingFromIntervalMarkup and 0 or nil
			)

			if not success then
				warn(errmsg)
			end
		end
	end
end

methods.Clear = function(self : types.hyperTextClassObject, instant : boolean?)
	local contentFolder = self._contentFolder

	if contentFolder then
		if self._executionThread then
			task.cancel(self._executionThread)	
		end
		if self._waitMarkupThread then
			task.cancel(self._waitMarkupThread)
		end
		
		if self._currentTypewriterSFX then
			self._currentTypewriterSFX:Stop()
		end

		self._nextTypewriterSFXTime = nil
		self._pausedRender = false
		self.rendering = false
		self._constructing = false
		self._fetchingTypewriterSFX = false

		if not instant then
			if self._clearingRender then
				return
			end
			
			self._clearingRender = true
			self._ignoreIntervals = false
			
			local latestEndTime : number?
			local renderId = self._renderId
			
			for _, entry in ipairs(self._printerData.rowEntries) do
				if not entry.whitespace then
					if entry.markups.clearInterval.value ~= 0 then
						self:_YieldFromInterval(
							entry.markups.clearInterval.value == "inherit"
								and entry.markups.interval.value
								or entry.markups.clearInterval.value :: number,
							entry.index
						)

						local clearingRender = self._clearingRender
						if not clearingRender or self._renderId ~= renderId then
							return
						end
					end
					
					for dataModule in util.iterateMarkupDataModulesByPrintPriority(markupDataModules) do
						if 
							dataModule.type == "paired"
							and dataModule.applyOnClear
							and dataModule.validate
							and dataModule.getClearingDuration
						then
							if dataModule.validate(entry.markups) then
								if entry.character:IsA("ImageLabel") and not dataModule.applyToImages then
									continue
								end
								
								local clearingDuration = dataModule.getClearingDuration(entry.markups)
								local endTime = os.clock() + clearingDuration
								
								latestEndTime = latestEndTime and math.max(latestEndTime, endTime) or endTime
								
								util.fireDataModuleOnPrint(
									self,
									dataModule,
									entry,
									updater,
									true
								)
							end
						end
					end
				end
			end
			
			if latestEndTime and os.clock() < latestEndTime then
				task.wait(latestEndTime - os.clock())
				
				local clearingRender = self._clearingRender
				if not clearingRender or self._renderId ~= renderId then
					return
				end
			end
		end
		
		contentFolder:Destroy()
		
		table.clear(self._transformRowEntries)
		
		for _, v in pairs(self._printerData :: {[string] : {any}}) do
			table.clear(v)
		end
		
		self._renderId = nil
		self._clearingRender = false
	end
end

methods.GetConstructionSize = function(self : types.hyperTextClassObject) : Vector2?
	local maxWidth = 0
	local accumulatedHeight = 0
	
	for _, row in ipairs(self._constructionData.rows) do
		accumulatedHeight += row.height
		
		if row.width > maxWidth then
			maxWidth = row.width
		end
	end
	
	return self._constructionScheduler.index and Vector2.new(maxWidth, accumulatedHeight) or nil
end

methods.GetPlainText = function(self : types.hyperTextClassObject) : string?
	local index = self._constructionScheduler.index
	local constructing = self._constructing
	
	if index and not constructing then
		self._constructionScheduler:Iterate(nil, {
			PARSER_APPEND_STRING_SCHEDULER_ID,
			PARSER_APPEND_WHITESPACE_SCHEDULER_ID
		})
		
		local text = ""
		
		if self._currentWord then
			for _, data in ipairs(self._currentWord) do
				if data.word then
					text ..= data.word.str
				end
			end
		end
		
		self._currentWord = nil
		
		return text
	end
	
	return nil
end

methods.Destroy = function(self : types.hyperTextClassObject)
	self._destroyed = true
	
	self:Clear(true)
	
	self._destroyCon:Disconnect()
	
	if self._currentTypewriterSFX then
		self._currentTypewriterSFX:Destroy()
		self._currentTypewriterSFX = nil
	end
	
	updater[self._rowEntriesTransformUpdaterId] = nil
	
	self.onRenderEnded:Destroy()
end

methods._GetProportionalSize = function(self : types.hyperTextClassObject, size : number) : (number, number)
	local containerDefaultAbsoluteSize = self._containerDefaultAbsoluteSize
	
	if containerDefaultAbsoluteSize then
		local scale = self._markups.scaleDimension.value == "X"
			and (self._container.AbsoluteSize.X / containerDefaultAbsoluteSize.X)
			or (self._container.AbsoluteSize.Y / containerDefaultAbsoluteSize.Y)
		
		return size * scale, scale
			
	end
	
	return 0, 1
end

methods._CreateRow = function(self : types.hyperTextClassObject, markups : types.markups?)
	table.insert(self._constructionData.rows, {
		height = markups and markups.size.value or 0,
		width = 0,
	})
end

methods._OverflowCheck = function(self : types.hyperTextClassObject)
	local size = self:GetConstructionSize()
	local text = self._text
	local renderTraceback = self._renderTraceback
	
	if size and text and renderTraceback then
		if 
			size.X > self._container.AbsoluteSize.X
			and not (
				self._markups.sizeConstraint.value == Enum.SizeConstraint.RelativeYY
					and self._markups.scaleDimension.value == "Y"
					and self._container.AutomaticSize == Enum.AutomaticSize.X
			)
		then
			warn(
				"Text \"" .. string.sub(text, 1, config.DEBUG_OVERFLOW_MAX_TEXT_LENGTH)
					.. (#text > config.DEBUG_OVERFLOW_MAX_TEXT_LENGTH and "..." or "")
					.. "\" horizontally overflowed from its container during construction\n"
					.. renderTraceback
			)
		end
		
		if 
			size.Y > self._container.AbsoluteSize.Y
			and not (
				self._markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXX
					and self._markups.scaleDimension.value == "X"
					and self._container.AutomaticSize == Enum.AutomaticSize.Y
			)
		then
			warn(
				"Text \"" .. string.sub(text, 1, config.DEBUG_OVERFLOW_MAX_TEXT_LENGTH)
					.. (#text > config.DEBUG_OVERFLOW_MAX_TEXT_LENGTH and "..." or "")
					.. "\" vertically overflowed from its container during construction\n"
					.. renderTraceback
			)
		end
	end
end

methods._CreateRowInstance = function(
	self : types.hyperTextClassObject,
	height : number,
	index : number
) : Frame
	local proportionalHeight = self:_GetProportionalSize(height)
	
	local row = Instance.new("Frame", self._contentFolder)
	row.SizeConstraint = self._markups.sizeConstraint.value
	row.Size = UDim2.fromScale(
		(
			self._markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXX
			or self._markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXY
		) 
			and 1
			or self._container.AbsoluteSize.X / self._container.AbsoluteSize.Y,
		self._markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXX 
			and proportionalHeight / self._container.AbsoluteSize.X
			or proportionalHeight / self._container.AbsoluteSize.Y
	)
	row.BackgroundTransparency = 1
	row.ZIndex = self._markups.ZIndex.value

	local digits = #tostring(#self._constructionData.rows)
	row.Name = string.format("Row%0" .. digits .. "d", index)
	
	local layout = Instance.new("UIListLayout", row)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = self._markups.horizontalAlignment.value

	return row
end

methods._CreateRowEntryContainer = function(
	self : types.hyperTextClassObject,
	printerData : types.printerDataRowEntry | types.printerDataRowEntry<false> | types.printerDataRowEntry<true>,
	suffix : string
) : Frame
	local proportionalWidth, scale = self:_GetProportionalSize(printerData.constructionDataRowEntry.width)
	local proportionalHeight = printerData.constructionDataRowEntry.height * scale

	local container = Instance.new(
		"Frame",
		printerData.row
	)
	container.Name = suffix .. "Container"
	container.BackgroundTransparency = 1
	container.ZIndex = printerData.markups.ZIndex.value
	container.SizeConstraint = printerData.markups.sizeConstraint.value
	container.LayoutOrder = printerData.index
	container.BorderSizePixel = 0
	container.Size = UDim2.fromScale(
		(
			printerData.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXY
				or printerData.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXX
		) and proportionalWidth / printerData.row.AbsoluteSize.X
			or proportionalWidth / printerData.row.AbsoluteSize.Y,
		(
			printerData.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXY
				or printerData.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeYY
		) and proportionalHeight / printerData.row.AbsoluteSize.Y
			or proportionalHeight / printerData.row.AbsoluteSize.X
	)

	local upperContainer =  #printerData.containers > 0
		and printerData.containers[#printerData.containers]
		or printerData.character

	if upperContainer then
		upperContainer.Size = UDim2.fromScale(1, 1)
		upperContainer.SizeConstraint = Enum.SizeConstraint.RelativeXY
		upperContainer.Parent = container
	end

	table.insert(printerData.containers, container)

	return container	
end

methods._YieldFromInterval = function(
	self : types.hyperTextClassObject,
	duration : number,
	index : number
)
	local ignoreIntervals = self._ignoreIntervals
	local firstEntryRowIndex = self._firstRowEntryIndex
	
	if
		duration ~= 0
		and firstEntryRowIndex
		and not ignoreIntervals
		and index > firstEntryRowIndex
	then
		self._yieldingFromIntervalMarkup = true
		
		yieldWhile(function(yieldDuration)
			return not self._ignoreIntervals and yieldDuration < duration
		end)
		
		self._yieldingFromIntervalMarkup = false
	end
end

methods._Print = function(
	self : types.hyperTextClassObject,
	currentWord : types.word,
	rowIndex : number,
	performAsWhiteSpace : boolean?
)
	local text = self._text
	
	if text then
		local rowData = self._constructionData.rows[rowIndex]
		local row : Frame
		
		if not rowData.instance then
			row = self:_CreateRowInstance(rowData.height, rowIndex)
			
			rowData.instance = row
		else
			row = rowData.instance
		end
		
		for _, data in ipairs(currentWord) do
			if data.word then
				for first, last in utf8.graphemes(data.word.str) do
					if data.word.splitCharacterIndex and last == #data.word.str then
						break
					end
					
					local baseEntry = self._constructionData.rowEntries[data.word.index + first - 1]
						:: types.constructionDataRowEntry<false>
					local dashEntry = self._constructionData.rowEntries[data.word.index + first - 1 + .5]
						:: types.constructionDataRowEntry<false>
										
					for i, entry in ipairs({baseEntry, dashEntry}) do
						self:_YieldFromInterval(
							data.word.markups.interval.value,
							data.word.index + first - 1
						)
						
						local proportionalWidth, scale = self:_GetProportionalSize(entry.height * entry.heightToWidthRatio)
						local proportionalHeight = entry.height * scale

						if self._pausedRender then
							coroutine.yield()
						end
						
						local character = i == 1
							and string.sub(data.word.str, first, last)
							or string.sub(data.word.str, last + 1, last + 1)
						local entryIndex = i == 1
							and data.word.index + first - 1
							or data.word.index + first - 1 + .5

						local textLabel = Instance.new("TextLabel", row)
						textLabel.BorderSizePixel = 0
						textLabel.LayoutOrder = entryIndex
						textLabel.RichText = true
						textLabel.BackgroundTransparency = 1
						textLabel.Text = character
						textLabel.TextXAlignment = Enum.TextXAlignment.Left
						textLabel.ZIndex = data.word.markups.ZIndex.value
						textLabel:SetAttribute("DefaultTextSize", Vector2.new(
							entry.height * entry.heightToWidthRatio,
							entry.height
						))
						textLabel.SizeConstraint = data.word.markups.sizeConstraint.value
						textLabel.Size = UDim2.fromScale(
							(
								data.word.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXY
									or data.word.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXX
							) and proportionalWidth / row.AbsoluteSize.X or proportionalWidth / row.AbsoluteSize.Y,
							(
								data.word.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeXY
									or data.word.markups.sizeConstraint.value == Enum.SizeConstraint.RelativeYY
							) and proportionalHeight / row.AbsoluteSize.Y or proportionalHeight / row.AbsoluteSize.X
						)
						
						textLabel:SetAttribute("DEBUG_HTWRatio", entry.heightToWidthRatio)
						
						local printerRowEntry : types.printerDataRowEntry<false> = {
							character = textLabel,
							row = row,
							constructionDataRowEntry = entry :: types.constructionDataRowEntry<false>,
							markups = data.word.markups,
							index = entryIndex,
							whitespace = performAsWhiteSpace,
							
							containers = {},
							position = Vector2.zero,
							rotation = 0,
						}
						
						table.insert(self._printerData.rowEntries, printerRowEntry :: types.printerDataRowEntry)

						local constraint = Instance.new("UITextSizeConstraint", textLabel)
						constraint.MinTextSize = proportionalHeight
						constraint.MaxTextSize = proportionalHeight
						
						local function resize(fromAbsoluteSize : boolean?)
							local defaultTextSize = textLabel:GetAttribute("DefaultTextSize") :: Vector2
							local _, scale = self:_GetProportionalSize(defaultTextSize.X)
							local proportionalHeight = defaultTextSize.Y * scale
							
							constraint.MinTextSize = 0
							
							constraint.MaxTextSize = proportionalHeight
							constraint.MinTextSize = math.clamp(proportionalHeight, 0, 100)
							
							textLabel.TextSize = proportionalHeight
						end

						textLabel:GetAttributeChangedSignal("DefaultTextSize"):Connect(resize)
						
						local connection = self._container:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
							resize(true)
						end)
						textLabel.Destroying:Once(function()
							connection:Disconnect()
						end)

						if not performAsWhiteSpace then
							util.fireAllDataModuleOnPrints(
								self,
								printerRowEntry :: types.printerDataRowEntry,
								updater
							)
						end
					end
				end
			elseif data.selfClosingMarkup then
				for dataModule in util.iterateMarkupDataModulesByPrintPriority(markupDataModules) do
					if 
						dataModule.type == "selfClosing"
						and string.lower(dataModule.name) == string.lower(data.selfClosingMarkup.type_)
						and dataModule.onPrint_
					then
						if dataModule.yieldFromIntervalOnPrint then
							self:_YieldFromInterval(
								data.selfClosingMarkup.markups.interval.value,
								data.selfClosingMarkup.index
							)
							
							if self._pausedRender then
								coroutine.yield()
							end
						end
						
						dataModule.onPrint_(
							self,
							data.selfClosingMarkup.markups,
							data.selfClosingMarkup.index,
							row,
							updater
						)
						
						break
					end
				end
			end
		end
	end
end

methods._Construct = function(
	self : types.hyperTextClassObject,
	performAsWhitespace : boolean?
)
	local constructionMarkups = self._constructionMarkups
	local schedulerIndex = self._constructionScheduler.index
	local currentWord = self._currentWord
	local containerDefaultAbsoluteSize = self._containerDefaultAbsoluteSize

	if 
		constructionMarkups
		and currentWord
		and schedulerIndex
		and containerDefaultAbsoluteSize
	then
		local rowIndex = #self._constructionData.rows
		local wrapped = self._wrapped

		self._currentWord = nil

		if wrapped then
			local appends = 0
			local rowData = self._constructionData.rows[rowIndex]
			
			local width = containerDefaultAbsoluteSize.X
			local epsilon = math.max(1e-4, width * 1e-6)
			local containerWidth = width + epsilon
			
			local function getSelfClosingMarkupSize(
				type_ : string,
				markups : types.markups
			) : Vector2
				for _, dataModule in ipairs(markupDataModules) do
					if
						dataModule.type == "selfClosing"
						and string.lower(dataModule.name) == string.lower(type_)
						and dataModule.getSize
					then
						return dataModule.getSize(self, markups)
					end
				end

				error("Failed to get the size of self closing markup \"" .. type_ .. "\"", 0)
			end

			local splitEntryIndex : number?
			local splitByteEnd : number?
			local splitCharacterIndex : number?
			local splitWithDash = false

			while true do
				local wordWidth = 0
				local overflowed = false
				local dashSplitEntryIndex : number?
				local dashSplitByteEnd : number?
				local dashSplitCharacterIndex : number?
				local atomicSplitEntryIndex : number?
				local preAtomicSplitEntryIndex : number?
				local preAtomicSplitByteEnd : number?
				local lastFittingEntryIndex : number?
				local lastFittingByteEnd : number?

				for i, data in ipairs(currentWord) do
					if data.word then
						for first, last in utf8.graphemes(data.word.str) do
							local character = string.sub(data.word.str, first, last)
							local size = data.word.markups.size.value
							local maxTextBounds = util.fetchTextBounds(
								character,
								data.word.markups,
								math.huge
							)
							local characterWidth = size * maxTextBounds.X / maxTextBounds.Y
							
							if rowData.width + wordWidth + characterWidth <= containerWidth then
								wordWidth += characterWidth
								lastFittingEntryIndex = i
								lastFittingByteEnd = last

								local dashMaxTextBounds = util.fetchTextBounds(
									"-",
									data.word.markups,
									math.huge
								)
								local dashWidth = size * dashMaxTextBounds.X / dashMaxTextBounds.Y

								if rowData.width + wordWidth + dashWidth <= containerWidth then
									dashSplitEntryIndex = i
									dashSplitByteEnd = last
									dashSplitCharacterIndex = data.word.index + first - 1
								end
							else
								overflowed = true

								break
							end
						end
					elseif data.selfClosingMarkup then
						local markupSize = getSelfClosingMarkupSize(
							data.selfClosingMarkup.type_,
							data.selfClosingMarkup.markups
						)
						local markupWidth = markupSize.X

						if rowData.width + wordWidth + markupWidth <= containerWidth then
							wordWidth += markupWidth
							lastFittingEntryIndex = i
							lastFittingByteEnd = nil

							if markupWidth > 0 then
								atomicSplitEntryIndex = i
							end
						else
							overflowed = true
							preAtomicSplitEntryIndex = lastFittingEntryIndex
							preAtomicSplitByteEnd = lastFittingByteEnd
						end
					end

					if overflowed then
						break
					end
				end

				if not overflowed then
					break
				end
				
				if performAsWhitespace then
					self:_CreateRow()

					return
				elseif
					rowData.width > 0
					and (
						wordWidth < containerWidth * config.SPLIT_WORD_AT_FRACTION
						or not dashSplitEntryIndex
							and not atomicSplitEntryIndex
							and not preAtomicSplitEntryIndex
					)
				then
					self:_CreateRow()

					rowIndex += 1
					rowData = self._constructionData.rows[rowIndex]
				elseif preAtomicSplitEntryIndex then
					splitEntryIndex = preAtomicSplitEntryIndex
					splitByteEnd = preAtomicSplitByteEnd
					splitCharacterIndex = nil
					splitWithDash = false

					break
				elseif
					dashSplitEntryIndex
					and (
						not atomicSplitEntryIndex
						or dashSplitEntryIndex > atomicSplitEntryIndex
					)
				then
					splitEntryIndex = dashSplitEntryIndex
					splitByteEnd = dashSplitByteEnd
					splitCharacterIndex = dashSplitCharacterIndex
					splitWithDash = true

					break
				elseif atomicSplitEntryIndex then
					splitEntryIndex = atomicSplitEntryIndex
					splitByteEnd = nil
					splitCharacterIndex = nil
					splitWithDash = false

					break
				else
					error("Container's width is too small for the first character and dash to be printed", 0)
				end
			end

			if splitEntryIndex then
				local splitData = currentWord[splitEntryIndex]
				local splitWord = splitData and splitData.word

				if splitWord then
					if not splitByteEnd then
						error("Failed to split the current word at a text entry", 0)
					end

					local originalString = splitWord.str
					local remainder = string.sub(originalString, splitByteEnd + 1)
					local remainderIndex = splitWord.index + splitByteEnd
					local remainderMarkups = splitWord.markups

					splitWord.str = string.sub(originalString, 1, splitByteEnd)

					if splitWithDash then
						splitWord.str ..= "-"
						splitWord.splitCharacterIndex = splitCharacterIndex
					else
						splitWord.splitCharacterIndex = nil
					end

					if remainder ~= "" then
						self._constructionScheduler:Insert(schedulerIndex + 1 + appends, function()
							self:_AppendStringToCurrentWord(
								remainder,
								remainderIndex,
								remainderMarkups
							)
						end)

						appends += 1
					end
					
					self:_CreateRow()
				elseif splitData.selfClosingMarkup then
					self:_CreateRow()
				elseif not splitData then
					error("Failed to split the current word at a valid entry", 0)
				end

				local currentWordLength = #currentWord

				for i = splitEntryIndex + 1, currentWordLength do
					local data = currentWord[i]
					currentWord[i] = nil

					if data.word then
						local wordString = data.word.str
						local wordIndex = data.word.index
						local wordMarkups = data.word.markups

						self._constructionScheduler:Insert(schedulerIndex + 1 + appends, function()
							self:_AppendStringToCurrentWord(wordString, wordIndex, wordMarkups)
						end)

						appends += 1
					elseif data.selfClosingMarkup then
						local markupType = data.selfClosingMarkup.type_
						local markupIndex = data.selfClosingMarkup.index
						local markupMarkups = data.selfClosingMarkup.markups

						self._constructionScheduler:Insert(schedulerIndex + 1 + appends, function()
							self:_AppendSelfClosingMarkupToCurrentWord(
								markupType,
								markupIndex,
								markupMarkups
							)
						end)

						appends += 1
					end
				end

				self._constructionScheduler:Insert(schedulerIndex + 1 + appends, function()
					self:_Construct()
				end)
			end
		end

		local rowData = self._constructionData.rows[rowIndex]

		for _, data in ipairs(currentWord) do
			if data.word then
				for first, last in utf8.graphemes(data.word.str) do
					if data.word.splitCharacterIndex and last == #data.word.str then
						break
					end
					
					local character = string.sub(data.word.str, first, last)
					local size = data.word.markups.size.value
					local maxTextBounds = util.fetchTextBounds(
						character,
						data.word.markups,
						math.huge
					)
					local heightToWidthRatio = maxTextBounds.X / maxTextBounds.Y
					local characterWidth = size * heightToWidthRatio
					
					local entryData : types.constructionDataRowEntry = {
						str = character,
						height = size,
						width = characterWidth,
						rowIndex = rowIndex,
						heightToWidthRatio = heightToWidthRatio,
					}
					self._constructionData.rowEntries[data.word.index + first - 1] = entryData
					rowData.width += characterWidth

					if 
						data.word.splitCharacterIndex
						and data.word.splitCharacterIndex == data.word.index + first - 1
					then
						for _, spans in pairs(self._constructionData.spans) do
							for _, spanData in pairs(spans) do
								local index = table.find(spanData.rowEntryIndices, data.word.splitCharacterIndex)
								
								if index then
									table.insert(
										spanData.rowEntryIndices,
										index + 1,
										data.word.splitCharacterIndex + .5
									)
								end
							end
						end
						
						local dashMaxTextBounds = util.fetchTextBounds(
							"-",
							data.word.markups,
							math.huge
						)
						heightToWidthRatio = dashMaxTextBounds.X / dashMaxTextBounds.Y
						characterWidth = size * heightToWidthRatio
						entryData = table.clone(entryData)
						
						entryData.width = characterWidth
						entryData.str = "-"
						entryData.heightToWidthRatio = heightToWidthRatio
						
						self._constructionData.rowEntries[data.word.splitCharacterIndex + .5] = entryData
						rowData.width += characterWidth
					end

					if size > rowData.height then
						rowData.height = size
					end
				end
			elseif data.selfClosingMarkup then
				for _, dataModule in ipairs(markupDataModules) do
					if 
						dataModule.type == "selfClosing"
						and string.lower(dataModule.name) == string.lower(data.selfClosingMarkup.type_)
						and dataModule.getSize
					then
						local size = dataModule.getSize(self, data.selfClosingMarkup.markups)
						
						self._constructionData.rowEntries[data.selfClosingMarkup.index] = {
							height = size.Y,
							width = size.X,
							rowIndex = rowIndex,
						}
						rowData.width += size.X

						if size.Y > rowData.height then
							rowData.height = size.Y
						end
					end
				end
			end
		end

		self._printerScheduler:Append(function()
			self:_Print(currentWord, rowIndex, performAsWhitespace)
		end)
	end
end

methods._AppendSelfClosingMarkupToCurrentWord = function(
	self : types.hyperTextClassObject,
	type_ : string,
	index : number,
	markups : types.markups
)
	local currentWord = self._currentWord or {}

	table.insert(
		currentWord,
		{
			selfClosingMarkup = {
				type_ = type_,
				index = index,
				markups = markups
			}
		}
	)

	self._currentWord = currentWord
end

methods._AppendSelfClosingMarkupToSpans = function(
	self : types.hyperTextClassObject,
	index : number
)
	for _, dataModule in ipairs(markupDataModules) do
		if dataModule.type == "paired" then
			local spans = util.indexCaseInsensitive(self._constructionData.spans, dataModule.name)

			for i = #spans, 1, -1  do
				local spanData = spans[i]

				if not spanData.closed then
					table.insert(spanData.rowEntryIndices, index)

					if not dataModule.stackable then
						break
					end
				end
			end
		end
	end
end

methods._AppendStringToCurrentWord = function(
	self : types.hyperTextClassObject,
	str : string,
	index : number,
	markups : types.markups?
)
	local constructionMarkups = self._constructionMarkups

	if constructionMarkups then
		markups = markups or util.deepCopy(constructionMarkups)
		local currentWord = self._currentWord or {}

		table.insert(
			currentWord,
			{
				word = {
					str = str,
					index = index,
					markups = markups,
				}
			}
		)

		self._currentWord = currentWord
	end
end

methods._AppendStringToSpans = function(
	self : types.hyperTextClassObject,
	str : string,
	index : number
)
	for first, last in utf8.graphemes(str) do
		for _, dataModule in ipairs(markupDataModules) do
			if dataModule.type == "paired" then
				local spans = util.indexCaseInsensitive(self._constructionData.spans, dataModule.name)
				
				for i = #spans, 1, -1  do
					local spanData = spans[i]
					
					if not spanData.closed then
						table.insert(spanData.rowEntryIndices, index + first - 1)
						
						if not dataModule.stackable then
							break
						end
					end
				end
			end
		end
	end
end

methods._MapConstructionData = function(self : types.hyperTextClassObject)
	local rows : types.mappedConstructionData = {}
	
	for i, entry in pairs(self._constructionData.rowEntries) do
		if not rows[entry.rowIndex] then
			local rowData = self._constructionData.rows[entry.rowIndex]
			local positionY = 0
			
			for rowIndex, row in ipairs(self._constructionData.rows) do
				if rowIndex < entry.rowIndex then
					positionY += row.height
				else
					break
				end
			end

			rows[entry.rowIndex] = {
				height = rowData.height,
				rowEntries = {},
				positionY = positionY,
				width = rowData.width,
				rowEntryIndices = {},
			}
		end
		
		table.insert(rows[entry.rowIndex].rowEntries, {
			str = entry.str,
			width = entry.width,
			height = entry.height,
			rowIndex = entry.rowIndex,
			index = i,
			positionX = 0,
		})
		table.insert(rows[entry.rowIndex].rowEntryIndices, i)
	end
	
	for rowIndex, row in pairs(rows) do
		local offsetX = 0
		
		table.sort(row.rowEntries, function(
			a : index<typeof(row.rowEntries), number>,
			b : index<typeof(row.rowEntries), number>
		)
			return a.index < b.index
		end)
		
		for 
			i = (
				self._markups.horizontalAlignment.value == Enum.HorizontalAlignment.Right
					and #row.rowEntries
					or 1
			),
			(
				self._markups.horizontalAlignment.value == Enum.HorizontalAlignment.Right 
					and 1
					or #row.rowEntries
			),
			(
				self._markups.horizontalAlignment.value == Enum.HorizontalAlignment.Right
					and -1
					or 1
			)
		do
			local entry = row.rowEntries[i]

			local positionX = self._markups.horizontalAlignment.value == Enum.HorizontalAlignment.Left
				and offsetX
				or self._markups.horizontalAlignment.value == Enum.HorizontalAlignment.Right
				and self._container.AbsoluteSize.X - offsetX - entry.width
				or row.width > 0 
				and (
					offsetX > 0
					and (offsetX / row.width - .5) * row.width + self._container.AbsoluteSize.X / 2
					or self._container.AbsoluteSize.X / 2 - row.width / 2
				)
				or self._container.AbsoluteSize.X / 2

			entry.positionX = positionX
			offsetX += entry.width
		end
	end

	self._mappedConstructionData = rows
end

methods._InitSpanData = function(self : types.hyperTextClassObject)
	local mappedConstructionData = self._mappedConstructionData
	
	if mappedConstructionData then
		for _, spans in pairs(self._constructionData.spans) do
			for _, spanData in ipairs(spans) do
				local spanRows : {[number] : index<types.mappedConstructionData, number>} = {}
				local earliestEntryPos = math.huge
				local lastestEntryPosAndWidth = -math.huge
				
				--TODO: fix this crap by making it indexable
				for _, index in ipairs(spanData.rowEntryIndices) do
					for _, row in pairs(mappedConstructionData) do
						if table.find(row.rowEntryIndices, index) then
							if not table.find(spanRows, row) then
								table.insert(spanRows, row)

								for _, entry in ipairs(row.rowEntries) do
									if table.find(spanData.rowEntryIndices, entry.index) then
										if entry.positionX < earliestEntryPos then
											earliestEntryPos = entry.positionX
										end
										if entry.positionX + entry.width > lastestEntryPosAndWidth then
											lastestEntryPosAndWidth = entry.positionX + entry.width
										end
									end
								end
							end

							break
						end
					end
				end

				if #spanRows > 0 then
					local height = 0

					if #spanRows == 1 then
						local tallestEntryHeight = 0

						for _, entry in ipairs(spanRows[1].rowEntries) do
							if 
								entry.height > tallestEntryHeight
								and table.find(spanData.rowEntryIndices, entry.index)
							then
								tallestEntryHeight = entry.height
							end
						end

						height = tallestEntryHeight
					elseif #spanRows > 1 then
						local lastRow = spanRows[#spanRows]
						local firstRow = spanRows[1]
						local distance = (lastRow.positionY + lastRow.height / 2) - (firstRow.positionY + firstRow.height / 2)

						for _, row in ipairs({lastRow, firstRow}) do
							local tallestEntryHeight = 0

							for _, entry in ipairs(row.rowEntries) do
								if 
									entry.height > tallestEntryHeight
									and table.find(spanData.rowEntryIndices, entry.index)
								then
									tallestEntryHeight = entry.height
								end
							end

							height += tallestEntryHeight / 2
						end	

						height += distance
					end

					local firstRow = spanRows[1]
					local firstRowTallestEntryHeight = 0

					for _, entry in ipairs(firstRow.rowEntries) do
						if 
							entry.height > firstRowTallestEntryHeight
							and table.find(spanData.rowEntryIndices, entry.index)
						then
							firstRowTallestEntryHeight = entry.height
						end			
					end

					spanData.position = Vector2.new(
						earliestEntryPos,
						firstRow.positionY + firstRow.height / 2 - firstRowTallestEntryHeight / 2
					)
					spanData.size = Vector2.new(lastestEntryPosAndWidth - earliestEntryPos, height)
				end
			end
		end
	end
end

methods._GetRowEntryPosition = function(
	self : types.hyperTextClassObject,
	index : number
) : Vector2
	if self._mappedConstructionData then
		for _, row in pairs(self._mappedConstructionData) do
			for _, entry in ipairs(row.rowEntries) do
				if entry.index == index then
					return Vector2.new(entry.positionX, row.positionY + row.height / 2 - entry.height / 2)
				end
			end
		end
	end

	error("row entry index not found in construction data", 0)
end

methods._CreateSpan = function(
	self : types.hyperTextClassObject,
	type_ : string,
	stackIndex : number?
)
	local span = util.indexCaseInsensitive(self._constructionData.spans, type_)
	
	table.insert(span, {
		stackIndex = stackIndex,
		rowEntryIndices = {},
		position = Vector2.zero,
		size = Vector2.zero,
	})
end

methods._CloseLastSpan = function(self : types.hyperTextClassObject, type_ : string)
	local spans = util.indexCaseInsensitive(self._constructionData.spans, type_)
	
	for i = #spans, 1, -1 do
		local span = spans[i]
		
		if not span.closed then
			span.closed = true
			
			break
		end
	end
end

methods._ParseAttrs = function(
	self : types.hyperTextClassObject,
	i : number,
	markupValueEndPos : number,
	tagEndPos : number,
	markupValue : string?,
	markupAttrs : types.dataModuleLooseAttrs,
	markupValuesAttrs : types.dataModuleLooseValueAttrs
) : {{attr : string, schemaAttr : string, value : any, markupValue : string?}}
	local text = self._text
	local renderTraceback = self._renderTraceback
	local attrsValues : {{attr : string, schemaAttr : string, value : any, markupValue : string?}} = {}
	
	if 
		text
		and renderTraceback
	then
		if markupValueEndPos + 1 < tagEndPos then
			local t = text

			local j = markupValueEndPos + 1
			while j < tagEndPos do
				local _, attrTypeStartPos = string.find(t, "%S", j)
				local attrTypeEndPos = string.match(t, "[^>=%s]+()", j) -- captures index of first whitespace or > or = 
				local attrValueEndPos = string.match(t, "[^>%s]+()", j) -- captures index of first whitespace or > 

				if 
					attrTypeEndPos
					and attrValueEndPos
					and attrTypeStartPos
					and attrTypeStartPos < tagEndPos
				then
					if attrTypeEndPos < attrValueEndPos - 1 then
						local attrType = 
							string.sub(
								t,
								attrTypeStartPos,
								attrTypeEndPos - 1
							)
						local attrValue = string.sub(t, attrTypeEndPos + 1, attrValueEndPos - 1)
						local markupValueAttrs = markupValue
							and util.safeIndexCaseInsensitive(markupValuesAttrs, markupValue)
						local markupAttributes = markupAttrs
						
						local attr, schemaAttrType
						if markupAttributes then
							attr, schemaAttrType = util.safeIndexCaseInsensitive(markupAttributes, attrType)
						end
						if markupValueAttrs and not attr and not schemaAttrType then
							attr, schemaAttrType = util.safeIndexCaseInsensitive(markupValueAttrs, attrType)
						end
						
						if attr and schemaAttrType then
							local fromMarkupValue = markupValueAttrs and 
								util.safeIndexCaseInsensitive(markupValueAttrs, attrType) and markupValue
							local alreadyDefined = false
							
							for _, v in ipairs(attrsValues) do
								if 
									string.lower(v.attr) == string.lower(attrType)
									and (v.markupValue and string.lower(v.markupValue)) == (fromMarkupValue and string.lower(fromMarkupValue))
								then
									alreadyDefined = true

									break
								end
							end
							
							if not alreadyDefined then
								local deleteAttr = attrValue == config.DELETE_MARKUP_VALUE_SYNTAX
								
								if (deleteAttr and attr.unrequired) or not deleteAttr then
									local success : boolean
									local convertedValue : any
									
									if deleteAttr then
										success = true
									else
										success, convertedValue = pcall(attr.convert, attrValue)
									end
									
									if success then
										table.insert(attrsValues, {
											attr = attrType,
											schemaAttr = schemaAttrType,
											value = convertedValue,
											markupValue = fromMarkupValue,
										})
									else
										warn(
											"Failed to parse attribute \""
												.. string.sub(
													t,
													attrTypeStartPos,
													attrValueEndPos - 1
												)
												.. "\" of tag \"" .. string.sub(t, i, tagEndPos) 
												.. "\": " .. convertedValue
												.. "\n" .. renderTraceback
										)
									end
								else
									warn(
										"Failed to parse attribute \""
											.. string.sub(
												t,
												attrTypeStartPos,
												attrValueEndPos - 1
											)
											.. "\" of tag \"" .. string.sub(t, i, tagEndPos) 
											.. "\": this attribute cannot be deleted"
											.. "\n" .. renderTraceback
									)
								end
							else
								warn(
									"Failed to parse attribute \""
										.. string.sub(
											t,
											attrTypeStartPos,
											attrValueEndPos - 1
										)
										.. "\" of tag \"" .. string.sub(t, i, tagEndPos) 
										.. "\": this attribute has already been defined\n"
										.. renderTraceback
								)
							end
						else
							warn(
								"Failed to parse attribute \""
									.. string.sub(
										t,
										attrTypeStartPos,
										attrValueEndPos - 1
									)
									.. "\" of tag \"" .. string.sub(t, i, tagEndPos) 
									.. "\": \"".. attrType .."\" is not a valid attribute\n"
									.. renderTraceback
							)
						end
					else
						warn(
							"Failed to parse attribute \""
								.. string.sub(
									t,
									attrTypeStartPos,
									attrTypeEndPos - 1
								)
								.. "\" of tag \"" .. string.sub(t, i, tagEndPos) 
								.. "\": no assigned value found\n"
								.. renderTraceback
						)
					end

					j = attrValueEndPos + 1
				else
					j = tagEndPos
				end
			end
		end
	end
	
	return attrsValues
end

methods._ParseText = function(self : types.hyperTextClassObject)
	local text = self._text
	local renderTraceback = self._renderTraceback
	
	if
		text
		and renderTraceback
	then
		local i = 1
		local t = text
		local markupStackEntries : {[string] : number} = {}
		local markupHistory : {string} = {}
		
		for dataModule in util.iterateMarkupDataModulesByPrintPriority(markupDataModules) do
			if dataModule.type == "paired" and dataModule.stackable then
				local stackableMarkups = self._markups :: {[string] : types.stack<types.markupIndexable>}
				local defaultStack = (stackableMarkups)[dataModule.name].stack

				markupStackEntries[dataModule.name] = 0

				for _, markups in pairs(defaultStack) do
					if markups then
						markupStackEntries[dataModule.name] += 1
					end
				end
			end
		end

		while i <= #t do
			local i_local = i
			local char = string.sub(t, i, i)
			
			if char ~= "<" and not string.match(char, "%s") then
				local word, endPos = string.match(t, "([^<%s]+)()", i) -- captures string from i to a whitespace or < 
				if word then
					self._constructionScheduler:Append(function()
						self:_AppendStringToCurrentWord(word, i_local)
					end, PARSER_APPEND_STRING_SCHEDULER_ID)
					self._constructionScheduler:Append(function()
						self:_AppendStringToSpans(word, i_local)
					end)
				end
				
				i = endPos or #t
			elseif string.match(char, "%s") then
				self._constructionScheduler:Append(function()
					self:_Construct()
				end)
				self._constructionScheduler:Append(function()
					self:_AppendStringToCurrentWord(char, i_local)
				end, PARSER_APPEND_WHITESPACE_SCHEDULER_ID)
				self._constructionScheduler:Append(function()
					self:_Construct(true)
				end)
				
				i += 1
			elseif char == "<" then
				if string.sub(t, i + 1, i + 1) ~= "/" then
					local typeEndPos = string.match(t, "[^=>%s]+()", i) -- captures index of first whitespace or > or =
					local valueEndPos = string.match(t, "[^>%s]+()", i) -- captures index of first whitespace or >
					local _, tagEndPos = string.find(t, ">", i)

					if tagEndPos and valueEndPos and typeEndPos then
						local markupType = string.sub(t, i + 1, typeEndPos - 1)
						local markupValue = typeEndPos and typeEndPos < valueEndPos - 1
							and string.sub(t, typeEndPos + 1, valueEndPos - 1)
							or nil
						
						for j, dataModule in ipairs(markupDataModules) do
							if string.lower(dataModule.name) == string.lower(markupType) then
								if dataModule.type == "paired" then
									local deleteMarkup = markupValue
										and markupValue == config.DELETE_MARKUP_VALUE_SYNTAX
									
									if (deleteMarkup and dataModule.unrequired) or not deleteMarkup then
										local success : boolean
										local convertedValue : any

										if deleteMarkup then
											success = true
											convertedValue = util.DELETE_SYNTAX
										elseif markupValue then
											success, convertedValue = pcall(dataModule.convert, markupValue)
										end
										
										if success or not markupValue then
											local attrsValues = self:_ParseAttrs(i, valueEndPos, tagEndPos, markupValue, dataModule.attributes, dataModule.valueAttributes)

											if success or #attrsValues > 0 then
												if not dataModule.stackable or convertedValue or markupStackEntries[dataModule.name] > 0 then
													if dataModule.stackable then
														markupStackEntries[dataModule.name] += 1
													end
													
													table.insert(markupHistory, 1, markupType)
													
													self._constructionScheduler:Append(function()
														if self._constructionMarkups then
															self:_ApplyMarkup(markupType, convertedValue, attrsValues, dataModule.stackable)
	
															if dataModule.onConstruction then
																local markups = util.deepCopy(self._constructionMarkups)
																
																dataModule.onConstruction(
																	self,
																	markups
																)
															end
	
															if markupValue then
																if dataModule.stackable then
																	local _, stackIndex = util.getLastEntryFromStack(
																		util.indexCaseInsensitive(
																			self._constructionMarkups :: {[string] : types.stack<types.markupIndexable>},
																			markupType
																		).stack
																	)

																	self:_CreateSpan(markupType, stackIndex)
																else
																	self:_CreateSpan(markupType)
																end
															end
														end
													end)
												else
													warn(
														"Failed to parse tag \""
															.. string.sub(t, i, tagEndPos) 
															.. "\": no entries in markup stack found"
															.. "\n" .. renderTraceback
													)
												end
											else
												warn(
													"Failed to parse tag \""
														.. string.sub(t, i, tagEndPos) 
														.. "\": no assigned value or attributes found"
														.. "\n" .. renderTraceback
												)
											end
										else
											warn(
												"Failed to parse tag \""
													.. string.sub(t, i, tagEndPos) 
													.. "\": " .. convertedValue
													.. "\n" .. renderTraceback
											)
										end
									elseif deleteMarkup then
										warn(
											"Failed to parse tag \""
												.. string.sub(t, i, tagEndPos) 
												.. "\": this markup cannot be deleted"
												.. "\n" .. renderTraceback
										)
									end
								elseif dataModule.type == "selfClosing" then
									local success : boolean
									local convertedValue : any

									if markupValue then
										success, convertedValue = pcall(dataModule.convert, markupValue)
									end

									if success or not markupValue then
										local attrsValues = self:_ParseAttrs(i, valueEndPos, tagEndPos, markupValue, dataModule.attributes, dataModule.valueAttributes)
										
										if not dataModule.appendToCurrentWord then
											self._constructionScheduler:Append(function()
												self:_Construct()
											end)
										end
										
										self._constructionScheduler:Append(
											function()
												if self._constructionMarkups then
													local markups = util.deepCopy(self._constructionMarkups)

													util.updateMarkups(markups, markupType, convertedValue, attrsValues)

													if dataModule.onConstruction then
														dataModule.onConstruction(
															self,
															markups
														)
													end
													
													if dataModule.appendToCurrentWord then
														self:_AppendSelfClosingMarkupToCurrentWord(
															markupType,
															tagEndPos,
															markups
														)
													end
												end
											end,
											dataModule.appendToCurrentWord
												and PARSER_APPEND_ROW_ENTRY_SCHEDULER_ID
												or nil
										)
										if dataModule.appendToCurrentWord then
											self._constructionScheduler:Append(function()
												self:_AppendSelfClosingMarkupToSpans(tagEndPos)
											end)
										end
									else
										warn(
											"Failed to parse tag \""
												.. string.sub(t, i, tagEndPos) 
												.. "\": " .. convertedValue
												.. "\n" .. renderTraceback
										)
									end
								end
								
								break
							elseif j == #markupDataModules then
								warn(
									"Failed to parse tag \"" 
										.. string.sub(t, i, tagEndPos)
										.. "\": \"".. markupType .."\" is not a valid tag\n"
										.. renderTraceback
								)
							end
						end

						i = tagEndPos + 1
					else
						warn(
							"Failed to parse tag \""
								.. string.sub(t, i, #t)
								.. "\": no closing angle bracket found\n"
								.. renderTraceback
						)

						break
					end
				else
					local _, tagEndPos = string.find(t, ">", i)

					if tagEndPos then
						local markupType = string.sub(t, i + 2, tagEndPos - 1)
						
						for j, dataModule in ipairs(markupDataModules) do
							if dataModule.type == "paired" and string.lower(dataModule.name) == string.lower(markupType) then
								if #markupHistory > 0 then
									for k, v in ipairs(markupHistory) do
										if string.lower(v) == string.lower(markupType) then
											if dataModule.stackable then
												markupStackEntries[dataModule.name] -= 1
											end

											table.remove(markupHistory, k)
											
											self._constructionScheduler:Append(function()
												self:_RemoveMarkup(markupType, dataModule.stackable)
												self:_CloseLastSpan(markupType)
											end)

											break
										elseif k == #markupHistory then
											warn(
												"Failed to parse tag \"</"
													.. markupType .. ">\": no opening tag found\n"
													.. renderTraceback
											)
										end
									end
								else
									warn(
										"Failed to parse tag \"</"
											.. markupType .. ">\": no opening tag found\n"
											.. renderTraceback
									)
								end
								
								break
							elseif j == #markupDataModules then
								warn(
									"Failed to parse tag \"</"
										.. markupType .. ">\": \"" 
										.. markupType .. "\" is not a valid tag\n"
										.. renderTraceback
								)
							end
						end
						
						i = tagEndPos + 1
					else
						local _, whitespacePos = string.find(t, "%s", i)
						
						warn(
							"Failed to parse tag \""
								.. string.sub(t, i, whitespacePos or #t)
								.. "\": no closing angle bracket found\n"
								.. renderTraceback
						)

						break
					end
				end
			end
		end
		
		self._constructionScheduler:Append(function()
			self:_Construct()
		end)
	end
end

methods._ApplyMarkup = function(
	self : types.hyperTextClassObject,
	type_ : string,
	value : any,
	attrsValues : {{
		attr : string,
		schemaAttr : string,
		value : any,
		markupValue : string?,
	}},
	stackable : boolean?
)
	local constructionMarkups = self._constructionMarkups
	
	if self._markupHistory and constructionMarkups then
		local previousMarkupValue, previousAttrsValues = util.updateMarkups(
			constructionMarkups,
			type_,
			value,
			attrsValues,
			stackable,
			false
		)
		
		table.insert(self._markupHistory, 1, {
			type = type_,
			value = previousMarkupValue,
			attrsValues = previousAttrsValues,
		})
	end
end

methods._RemoveMarkup = function(
	self : types.hyperTextClassObject,
	type_ : string,
	stackable : boolean?
)
	local constructionMarkups = self._constructionMarkups
	
	if self._markupHistory and constructionMarkups then
		for i, v in ipairs(self._markupHistory) do
			if string.lower(v.type) == string.lower(type_) then
				util.updateMarkups(
					constructionMarkups,
					v.type,
					v.value,
					v.attrsValues,
					stackable,
					stackable
				)
				
				table.remove(self._markupHistory, i)
				
				break
			end
		end
	end
end

RunService.Heartbeat:Connect(function(dt)
	debug.profilebegin("HyperText Updater")
	
	for id, callback in pairs(updater) do
		if updater[id] then
			local success, errmsg = pcall(callback, dt)

			if not success then
				warn(errmsg :: string)
				
				updater[id] = nil
			end
		end
	end

	debug.profileend()
end)

return HyperText
