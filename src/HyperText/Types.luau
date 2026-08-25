--!strict

local scheduler = require("./Scheduler")
local signal = require("./Signal")

local module = {}

module.literal = {
	animations = {
		slide = true,
		bounce = true,
		wiggle = true,
		grow = true,
	},
	verticalDir = {
		up = true,
		down = true
	},
	horizontalDir = {
		left = true,
		right = true,
	},
}

type function required(t : type)
	local parts = {}

	local function add(part : type)
		if part:is("never") or part:is("nil") then
			return
		end

		if part:is("singleton") and part:value() == nil then
			return
		end

		table.insert(parts, part)
	end

	if t:is("union") then
		for _, part in t:components() do
			add(part)
		end
	else
		add(t)
	end

	return types.unionof(table.unpack(parts))
end

type function isOptional(t : type) : boolean
	if t:is("nil") then
		return true
	end

	if t:is("singleton") and t:value() == nil then
		return true
	end

	if t:is("union") then
		for _, part in t:components() do
			if isOptional(part) then
				return true
			end
		end
	end

	return false
end

type function unique(t : type)
	local parts = {}

	local function add(part : type)
		if part:is("never") then
			return
		end

		if part:is("union") then
			for _, component in part:components() do
				add(component)
			end

			return
		end

		for _, existing in parts do
			if existing == part then
				return
			end
		end

		table.insert(parts, part)
	end

	add(t)

	return types.unionof(table.unpack(parts))
end

type function createAttrConverters(attrs : type)
	local result = types.newtable()
	
	local function add(component : type)
		for key, prop in component:properties() do
			local valueType = prop.read

			if valueType then
				local converterType = types.newtable({
					[types.singleton("convert")] = types.newfunction(
						{head = {types.string}, tail = types.any},
						{head = {required(valueType)}}
					),
					[types.singleton("validateDefaultValue")] = types.optional(
						types.newfunction(
							{head = {required(valueType)}}
						)
					),
					[types.singleton("unrequired")] = if isOptional(valueType)
						then types.singleton(true)
						else types.optional(types.singleton(false)),
				})

				result:setproperty(key, converterType)
			end
		end
	end
	
	if attrs.tag == "intersection" then
		for _, component in attrs:components() do
			add(component)
		end
	else
		add(attrs)
	end

	return result
end
type function createValueAttrConverters(valueAttrs : type)
	local result = types.newtable()
	
	local function add(component : type)
		for valueKey, prop in component:properties() do
			local attrsType = prop.read

			if attrsType then
				result:setproperty(valueKey, createAttrConverters(attrsType))
			end
		end
	end

	if valueAttrs.tag == "intersection" then
		for _, component in valueAttrs:components() do
			add(component)
		end
	else
		add(valueAttrs)
	end

	return result
end
type function createUpdater()
	local updaterFunctionType = types.newfunction(
		{head = {types.number}},
		{head = {}}
	)

	return types.newtable(
		nil,
		{
			index = types.string,
			readresult = updaterFunctionType,
			writeresult = updaterFunctionType,
		}
	)
end
type function createDataModuleOnPrint(
	isSelfClosingMarkup : type,
	applyOnClear : boolean?,
	
	markupsType : type,
	hyperTextClassObjectType : type,
	onPrintMarkupSnanDataType : type,
	frameType : type,
	guiObjectType : type,
	vector2Type : type,
	textLabelType : type,
	imageLabelType : type
)
	local head = {
		hyperTextClassObjectType,
		createPrinterDataRowEntry(
			isSelfClosingMarkup,
			
			markupsType,
			frameType,
			guiObjectType,
			vector2Type,
			textLabelType,
			imageLabelType
		),
		onPrintMarkupSnanDataType,
		createUpdater(),
	}

	if applyOnClear then
		table.insert(head, applyOnClear)
	end

	return types.optional(
		types.newfunction(
			{
				head = head,
			},
			{
				head = {},
			}
		)
	)
end
type function createDataModuleGetSize(
	hyperTextClassObjectType : type,
	markupsType : type,
	vector2Type : type
)
	return types.newfunction(
		{
			head = {
				hyperTextClassObjectType,
				markupsType,
			}
		},
		{
			head = {
				vector2Type,
			}
		}
	)
end
type function createSelfClosingMarkupDataModuleOnPrint(
	hyperTextClassObjectType : type,
	markupsType : type,
	frameType :  type
)
	return types.newfunction(
		{
			head = {
				hyperTextClassObjectType,
				markupsType,
				types.number,
				frameType,
				createUpdater()
			}
		},
		{
			head = {}
		}
	)
end
type function createDataModuleOnConstruction(
	hyperTextClassObjectType : type,
	markupsType : type
)
	return types.optional(
		types.newfunction(
			{
				head = {
					hyperTextClassObjectType,
					markupsType
				}
			},
			{
				head = {}
			}
		)
	)
end
type function createDataModuleGetClearingDuration(markupsType : type)
	return types.newfunction(
		{
			head = {markupsType}
		},
		{
			head = {types.number}
		}
	)
end
type function createDataModuleValidate(markupsType : type)
	return types.newfunction(
		{
			head = {markupsType}
		},
		{
			head = {types.boolean}
		}
	)
end
type function createDataModule(
	markupName : type,
	moduleType : type,
	applyToImages : type,
	appendToCurrentWord : type,
	applyOnClear : type,
	
	hyperTextClassObjectType : type,
	onPrintMarkupSnanDataType : type,
	markupsType : type,
	frameType,
	guiObjectType,
	vector2Type,
	textLabelType,
	imageLabelType
)
	local markup = markupsType:readproperty(markupName)
	
	if markup == nil then
		error("invalid markup name")
	end

	local isStackable = markup:readproperty(types.singleton("stack")) and true or false

	if isStackable then
		local entryType = markup:readproperty(types.singleton("_entryDefaultValues"))

		if entryType then
			markup = entryType
		else
			error("no default entry type found for stackable markup")
		end
	end
	
	local markupValue = markup:readproperty(types.singleton("value"))
	local attrs = markup:readproperty(types.singleton("attributes"))
	local valueAttrs = markup:readproperty(types.singleton("valueAttributes"))
	
	local applyToImagesType = applyToImages:value()
		and types.singleton(true)
		or types.optional(types.singleton(false))
	local applyOnClearType = applyOnClear:value()
		and types.singleton(true)
		or types.optional(types.singleton(false))

	local type_ = {
		[types.singleton("name")] = markupName,
		[types.singleton("type")] = moduleType,
		[types.singleton("convert")] = types.newfunction(
			{head = {types.string}, tail = types.any},
			{head = {required(markupValue)}}
		),
		[types.singleton("validateDefaultValue")] = types.optional(
			types.newfunction(
				{head = {required(markupValue)}}
			)
		),
		[types.singleton("onDefaultMarkupsChanged")] = types.optional(
			types.newfunction(
				{head = {markupsType}}
			)
		),
		[types.singleton("appendToCurrentWord")] = appendToCurrentWord,
		[types.singleton("applyToImages")] = applyToImagesType,
		[types.singleton("applyOnClear")] = applyOnClearType,
		[types.singleton("attributes")] = createAttrConverters(attrs),
		[types.singleton("valueAttributes")] = createValueAttrConverters(valueAttrs),
		[types.singleton("onConstruction")] = createDataModuleOnConstruction(
			hyperTextClassObjectType,
			markupsType
		)
	}
	
	if moduleType:value() == "paired" then
		local stackableType = isStackable
			and types.singleton(true)
			or types.optional(types.singleton(false))
		local unrequiredType = isOptional(markupValue)
			and not isStackable
			and types.singleton(true)
			or types.optional(types.singleton(false))
			
		type_[types.singleton("unrequired")] = unrequiredType
		type_[types.singleton("stackable")] = stackableType
		type_[types.singleton("onPrint")] = createDataModuleOnPrint(
			applyToImages:value() and types.unknown or types.singleton(false),
			applyOnClear:value() and types.boolean or nil,
			
			markupsType,
			hyperTextClassObjectType,
			onPrintMarkupSnanDataType,
			frameType,
			guiObjectType,
			vector2Type,
			textLabelType,
			imageLabelType
		)

		if applyOnClear:value() then
			type_[types.singleton("getClearingDuration")] = createDataModuleGetClearingDuration(markupsType)
			type_[types.singleton("validate")] = createDataModuleValidate(markupsType)
		end
	elseif moduleType:value() == "selfClosing" then
		if appendToCurrentWord:value() then
			type_[types.singleton("yieldFromIntervalOnPrint")] = types.optional(types.boolean)
			type_[types.singleton("getSize")] = createDataModuleGetSize(
				hyperTextClassObjectType,
				markupsType,
				vector2Type
			)
			type_[types.singleton("onPrint_")] = createSelfClosingMarkupDataModuleOnPrint(
				hyperTextClassObjectType,
				markupsType,
				frameType
			)
		end
	end
		
	return types.newtable(type_)
end
export type dataModuleType = "paired" | "selfClosing"
type dataModuleLooseAttrBase = {
	convert : (value : string) -> any,
	validateDefaultValue : ((value : any) -> ())?,
	unrequired : boolean?,
}
export type dataModuleLooseAttrs = {[string] : dataModuleLooseAttrBase}
export type dataModuleLooseValueAttrs = {[string] : {[string] : dataModuleLooseAttrBase}}
export type dataModuleLoose = {
	convert : (value : string) -> any,
	name : string,
	type : dataModuleType,
	unrequired : boolean?,
	attributes : dataModuleLooseAttrs,
	valueAttributes : dataModuleLooseValueAttrs,
	onConstruction : createDataModuleOnConstruction<hyperTextClassObject, markups>,
	validateDefaultValue : ((value : any) -> ())?,
	onDefaultMarkupsChanged : ((markups : markups) -> ())?,
} & (
	{
		type : "paired",
		applyToImages : boolean?,
		applyOnClear : boolean?,
		stackable : boolean?,
		onPrint : createDataModuleOnPrint<
			unknown,
			boolean?,
		
			markups,
			hyperTextClassObject,
			onPrintMarkupSpanData,
			Frame,
			GuiObject,
			Vector2,
			TextLabel,
			ImageLabel
		>,
		getClearingDuration : createDataModuleGetClearingDuration<markups>,
		validate : createDataModuleValidate<markups>
	}
	| {
		type : "selfClosing",
		appendToCurrentWord : boolean?,
		yieldFromIntervalOnPrint : boolean?,
		onPrint_ : createSelfClosingMarkupDataModuleOnPrint<hyperTextClassObject, markups, Frame>?,
		getSize : createDataModuleGetSize<hyperTextClassObject, markups, Vector2>?,
	}
)
export type dataModule<
	markup,
	type,
	applyToImages = nil,
	applyOnClear = nil,
	appendToCurrentWord = nil
> = createDataModule<
	markup,
	type,
	applyToImages,
	appendToCurrentWord,
	applyOnClear,
	
	any, --hyperTextClassObject, (this reaches the limits of luau's type solver)
	onPrintMarkupSpanData,
	markups,
	Frame,
	GuiObject,
	Vector2,
	TextLabel,
	ImageLabel
>

export type onPrintMarkupSpanData = {
	characterPosition : Vector2,
	characterSize : Vector2,
	spanPosition : Vector2,
	spanSize : Vector2
}
export type spanData = {
	rowEntryIndices : {number},
	closed : boolean?,
	position : Vector2,
	size : Vector2
}
export type word = {
	{
		word : {
			str : string,
			index : number,
			markups : markups,
			splitCharacterIndex : number?,
		}?,
		selfClosingMarkup : {
			type_ : string,
			index : number,
			markups : markups,
		}?
	}
}
export type mappedConstructionData = {
	[number] : {
		height : number,
		width : number,
		rowEntries : {
			constructionDataRowEntry & {
				positionX : number,
				index : number,
			}
		},
		rowEntryIndices : {number},
		positionY : number,
	}
}
export type row = {
	width : number,
	height : number,
	instance : Frame?,
}
type function createConstructionDataRowEntry(isSelfClosingMarkup : type)
	local type_ = {
		[types.singleton("width")] = types.number,
		[types.singleton("height")] = types.number,
		[types.singleton("rowIndex")] = types.number,
	}
	
	if isSelfClosingMarkup == types.unknown then
		type_[types.singleton("str")] = types.optional(types.string)
		type_[types.singleton("heightToWidthRatio")] = types.optional(types.number)
	elseif not isSelfClosingMarkup:value() then
		type_[types.singleton("str")] = types.string
		type_[types.singleton("heightToWidthRatio")] = types.number
	else
		type_[types.singleton("str")] = types.singleton(nil)
		type_[types.singleton("heightToWidthRatio")] = types.singleton(nil)
	end
	
	return types.newtable(type_)
end
export type constructionDataRowEntry<T = unknown> = createConstructionDataRowEntry<T>
type function createPrinterDataRowEntry(
	isSelfClosingMarkup : type,
	
	markupsType : type,
	frameType : type,
	guiObjectType : type,
	vector2Type : type,
	textLabelType : type,
	imageLabelType : type
)	
	local type_ = {
		[types.singleton("row")] = frameType,
		[types.singleton("markups")] = markupsType,
		[types.singleton("index")] = types.number,
		[types.singleton("whitespace")] = types.optional(types.boolean),
		[types.singleton("containers")] = types.newtable(
			nil,
			{
				index = types.number,
				readresult = guiObjectType,
				writeresult = guiObjectType,
			}
		),
		[types.singleton("position")] = vector2Type,
		[types.singleton("rotation")] = types.number,
		[types.singleton("constructionDataRowEntry")] = createConstructionDataRowEntry(isSelfClosingMarkup),
		[types.singleton("character")] = if isSelfClosingMarkup == types.unknown
			then types.unionof(textLabelType, imageLabelType)
			elseif isSelfClosingMarkup:value()
			then imageLabelType
			else textLabelType,
	}
	
	return types.newtable(type_)
end
export type printerDataRowEntry<T = unknown> = createPrinterDataRowEntry<
	T,
	
	markups,
	Frame,
	GuiObject,
	Vector2,
	TextLabel,
	ImageLabel
>
export type hyperTextClassContent = {
	_container : GuiObject,
	_markups : markups,
	_printerScheduler : scheduler.classType,
	_constructionScheduler : scheduler.classType,
	_destroyCon : RBXScriptConnection,
	_yieldingFromIntervalMarkup : boolean,
	_rowEntriesTransformUpdaterId : string,
	_transformRowEntries : {
		[printerDataRowEntry] : {string}
	},
	_constructionData : {
		rows : {row},
		rowEntries : {[number] : constructionDataRowEntry},
		spans : {
			[string] : {spanData}
		}
	},
	_printerData : {
		rowEntries : {printerDataRowEntry}
	},
	rendering : boolean,
	onRenderEnded : signal.classType<boolean?>,
	renderEvent : signal.classType<string>,

	_constructing : boolean?,
	_destroyed : boolean?,
	_text : string?,
	_renderId : string?,
	_waitMarkupThread : thread?,
	_layout : UIListLayout?,
	_wrapped : boolean?,
	_constructionMarkups : markups?,
	_firstRowEntryIndex : number?,
	_mappedConstructionData : mappedConstructionData?,
	_clearingRender : boolean?,
	_renderTraceback : string?,
	_executionThread : thread?,
	_pausedRender : boolean?,
	_contentFolder : Folder?,
	_containerDefaultAbsoluteSize : Vector2?,
	_markupHistory : {
		{
			type : string,
			value : any,
			attrsValues : {{
				attr : string,
				schemaAttr : string,
				value : any,
				markupValue : string?,
			}},
		}
	}?,
	_ignoreIntervals : boolean?,
	_currentWord : word?,
	_markupIndices : {[string] : number}?,
	_fetchingTypewriterSFX : boolean?,
	_nextTypewriterSFXTime : number?,
	_currentTypewriterSFX : Sound?,
}
export type hyperTextClassMethods = {
	UpdateDefaultMarkups : typeof(
		--[[
			Merges the given markups dictionary into the object's default markups. This method may yield.

			markups: markups
			The dict, obtained from calling <code>.newMarkups().</code>
		]]
		function(
			self : hyperTextClassObject,
			markups : markups
		) end
	),
	Render : typeof(
		--[[
			Renders the given text inside the object's container and applies the object's default markups & attributes to it. Stops any previous render and clears its text.

			text: string
			The text (including its markups) that is going to be rendered.
			
			yield: boolean?
		    Indicates whether the render should yield the calling thread.
			
			wrapped: boolean?
			Indicates whether the rendered content should wrap inside the object's container. Defaults to true.

			constructOnly: boolean?
			Indicates whether this render should only be constructed internally, not rendered. This parameter is meant to be used with <code>:GetConstructionSize()</code> to get the expected size of a render without actually rendering anything.
		]]
		function(
			self : hyperTextClassObject,
			text : string,
			yield : boolean?,
			wrapped : boolean?,
			constructOnly : boolean?
		) end
	),
	CompleteRender : typeof(
		--[[
			Skips all remaining render intervals immediately. It does not skip or wait for yielding parsing or construction work, including resource fetching and custom callbacks, so it may return before the render finishes.
		]]
		function(
			self : hyperTextClassObject
		) end
	),
	PauseRender : typeof(
		--[[
			Pauses a render.
		]]
		function(
			self : hyperTextClassObject
		) end
	),
	ResumeRender : typeof(
		--[[
			Resumes a paused render.
		]]
		function(
			self : hyperTextClassObject,
			_ignoreIntervalMarkupYield : boolean?
		) end
	),
	Clear : typeof(
		--[[
			Stops a render and clears any rendered content. Yields the calling thread until all clearing markups have completed.
			
			instant: boolean?
			Ignores the clearing markups and clears the text instantly.
		]]
		function(
			self : hyperTextClassObject,
			instant : boolean?
		) end
	),
	GetConstructionSize : typeof(
		--[[
			Returns the final width and height of the last render.
		]]
		function(
			self : hyperTextClassObject
		) : Vector2? return nil :: any end
	),
	GetPlainText : typeof(
		--[[
			Returns the text used in the last render with all markup tags removed.
		]]
		function(
			self : hyperTextClassObject
		) : string? return nil :: any end
	),
	Destroy : typeof(
		--[[
			Stops a render, clears any rendered content, and destroys owned instances.
		]]
		function(
			self : hyperTextClassObject
		) end
	),

	_GetProportionalSize : (self : hyperTextClassObject, size : number) -> (number, number),
	_CreateRow : (self : hyperTextClassObject, markups : markups?) -> (),
	_OverflowCheck : (self : hyperTextClassObject) -> (),
	_CreateRowInstance : (self : hyperTextClassObject, height : number, index : number) -> Frame,
	_CreateRowEntryContainer : (
		self : hyperTextClassObject,
		entry : printerDataRowEntry | printerDataRowEntry<false> | printerDataRowEntry<true>,
		suffix : string
	) -> Frame,
	_YieldFromInterval : (
		self : hyperTextClassObject,
		duration : number,
		index : number
	) -> (),
	_Print : (
		self : hyperTextClassObject,
		word : word,
		rowIndex : number,
		performAsWhiteSpace : boolean?
	) -> (),
	_AppendStringToCurrentWord : (
		self : hyperTextClassObject,
		str : string,
		index : number,
		markups : markups?
	) -> (),
	_AppendStringToSpans : (
		self : hyperTextClassObject,
		str : string,
		index : number
	) -> (),
	_AppendSelfClosingMarkupToSpans : (
		self : hyperTextClassObject,
		index : number
	) -> (),
	_AppendSelfClosingMarkupToCurrentWord : (
		self : hyperTextClassObject,
		type_ : string,
		index : number,
		markups : markups
	) -> (),
	_Construct : (
		self : hyperTextClassObject,
		performAsWhiteSpace : boolean?
	) -> (),
	_MapConstructionData : (self : hyperTextClassObject ) -> (),
	_InitSpanData : (self : hyperTextClassObject) -> (),
	_GetRowEntryPosition : (
		self : hyperTextClassObject,
		index : number
	) -> Vector2,
	_CreateSpan : (self : hyperTextClassObject, type_ : string) -> (),
	_CloseLastSpan : (self : hyperTextClassObject, type_ : string) -> (),
	_ParseAttrs : (
		self : hyperTextClassObject,
		i : number,
		markupValueEndPos : number,
		tagEndPos : number,
		markupValue : string?,
		markupAttrs : dataModuleLooseAttrs,
		markupValueAttrs : dataModuleLooseValueAttrs
	) -> {{
		attr : string,
		schemaAttr : string,
		value : any,
		markupValue : string?,
	}},
	_ParseText : (self : hyperTextClassObject) -> (),
	_ApplyMarkup : (
		self : hyperTextClassObject,
		type_ : string,
		value : any,
		attrsValues : {{
			attr : string,
			schemaAttr : string,
			value : any,
			markupValue : string?,
		}},
		stackable : boolean?
	) -> (),
	_RemoveMarkup : (
		self : hyperTextClassObject,
		type_ : string,
		stackable : boolean?
	) -> (),
}
export type hyperTextClassObject = hyperTextClassContent & hyperTextClassMethods

export type emitImgAttrs = {
	color : Color3,
	aspectRatio : number,
	rate : number,
	chance : number,
	lifetime : NumberRange,
	velX : NumberRange,
	velY : NumberRange,
	rotVel : NumberRange,
	accelX : NumberRange,
	accelY : NumberRange,
	startTrans : NumberRange,
	endTrans : NumberRange,
	startSize : NumberRange,
	endSize : NumberRange,
	startPosX : NumberRange,
	startPosY : NumberRange,
	startRot : NumberRange,
	applyTransform : boolean,
}
export type imgAttrs = {
	plain : boolean,
	height : number,
	aspectRatio : number,
	color : Color3,
	trans : number?
}
export type gradientAttrs = {
	colors : {Color3},
	rot : number,
	individual : boolean,
	moveDir : keyof<typeof(module.literal.horizontalDir)>,
	moveSpeed : number,
	spacing : number,
}
export type animAttrs = {
	dur : number,
	loop : boolean,
}
export type flipbookAttrs = {
	flipbookLayout : Vector2?,
	flipbookFreq : number,
	flipbookLoop : boolean,
	flipbookReverse : boolean,
}
export type animValueAttrs = {
	slide : {
		dir : keyof<typeof(module.literal.verticalDir)>,
		offset : number,
		rot : number,
	},
	bounce : {
		dir : keyof<typeof(module.literal.verticalDir)>,
		offset : number,
		exp : number,
	},
	wiggle : {
		freq : number,
		offset : number,
		amp : number,
		rot : boolean,
	},
	grow : {
		exp : number,
		startScale : number,
	}
}
export type emitImageAttrsConverters = createAttrConverters<emitImgAttrs>
export type gradientAttrsConverters = createAttrConverters<gradientAttrs>
export type animAttrsConverters = createAttrConverters<animAttrs>
export type animValueAttrsConverters = createValueAttrConverters<animValueAttrs>
export type flipbookAttrsConverts = createAttrConverters<flipbookAttrs>
export type imgAttrsConverters = createAttrConverters<imgAttrs>
type inherit<T> = T | "inherit"
export type stack<T> = {stack : {[number] : T?}, _entryDefaultValues : T}
export type markups = {
	-- self closing tag markups
	wait : {
		value : number,
		attributes : {},
		valueAttributes : {},
	},
	br : {
		value : number,
		attributes : {},
		valueAttributes : {},
	},
	img : {
		value : number,
		attributes : imgAttrs & flipbookAttrs,
		valueAttributes : {},
	},
	renderEvent : {
		value : string,
		attributes : {},
		valueAttributes : {},
	},
	
	-- paired tags markups
	color : {
		value : Color3,
		attributes : {},
		valueAttributes : {},
	},
	font : {
		value : string | number,
		attributes : {},
		valueAttributes : {},
	},
	size : {
		value : number,
		attributes : {},
		valueAttributes : {},
	},
	interval : {
		value : number,
		attributes : {},
		valueAttributes : {},
	},
	clearInterval : {
		value : inherit<number>,
		attributes : {},
		valueAttributes : {},
	},
	soundId : {
		value : (number | string)?,
		attributes : {
			volume : number
		},
		valueAttributes : {},
	},
	anim : {
		value : keyof<typeof(module.literal.animations)>?,
		attributes : animAttrs,
		valueAttributes : animValueAttrs,
	},
	clearAnim : {
		value : inherit<keyof<typeof(module.literal.animations)>>?,
		attributes : animAttrs,
		valueAttributes : animValueAttrs,
	},
	weight : {
		value : Enum.FontWeight,
		attributes : {},
		valueAttributes : {},
	},
	italic : {
		value : boolean,
		attributes : {},
		valueAttributes : {},
	},
	trans : {
		value : number,
		attributes : {
			tweenDur : number?,
			tweenFrom : number,
			loopTween : boolean,
		},
		valueAttributes : {},
	},
	clearTransDur : {
		value : inherit<number>,
		attributes : {},
		valueAttributes : {},
	},
	stroke : {
		value : boolean,
		attributes : {
			trans : number?,
			thickness : number,
			color : Color3,
		},
		valueAttributes : {},
	},
	underline : {
		value : boolean,
		attributes : {},
		valueAttributes : {},
	},
	strike : {
		value : boolean,
		attributes : {},
		valueAttributes : {},
	},
	mark : {
		value : boolean,
		attributes : {
			color : Color3,
			trans : number,
		},
		valueAttributes : {},
	},
	shiny : stack<{
		value : boolean,
		attributes : emitImgAttrs & flipbookAttrs,
		valueAttributes : {},
	}>,
	fog : stack<{
		value : boolean,
		attributes : emitImgAttrs & flipbookAttrs,
		valueAttributes : {},
	}>,
	rainbow : {
		value : boolean,
		attributes : {
			freq : number,
			offset : number,
		},
		valueAttributes : {},
	},
	shake : {
		value : boolean,
		attributes : {
			maxOffset : number,
			dur : number,
			loop : boolean,
			maxRot : number,
			freq : number?,
			fade : boolean,
		},
		valueAttributes : {},
	},
	gradient : {
		value : boolean,
		attributes : gradientAttrs,
		valueAttributes : {},
	},
	strokeGradient : {
		value : boolean,
		attributes : gradientAttrs,
		valueAttributes : {},
	},
	emitImg : stack<{
		value : number,
		attributes : emitImgAttrs & flipbookAttrs,
		valueAttributes : {},
	}>,
	decode : {
		value : boolean,
		attributes : {
			freq : number?,
			dur : number,
			loop : boolean,
		},
		valueAttributes : {},
	},
	shadow : {
		value : boolean,
		attributes : {
			color : Color3,
			offset : Vector2,
			trans : number?,
		},
		valueAttributes : {},
	},
	
	-- untagged markups
	horizontalAlignment : {
		value : Enum.HorizontalAlignment,
		attributes : {},
		valueAttributes : {},
	},
	verticalAlignment : {
		value : Enum.VerticalAlignment,
		attributes : {},
		valueAttributes : {},
	},
	scaleDimension : {
		value : "X" | "Y",
		attributes : {},
		valueAttributes : {},
	},
	sizeConstraint : {
		value : Enum.SizeConstraint,
		attributes : {},
		valueAttributes : {},
	},
	ZIndex : {
		value : number,
		attributes : {},
		valueAttributes : {},
	},
}
export type markup = keyof<markups>
export type markupIndexable = {
	value : any,
	attributes : {
		[string]: any
	},
	valueAttributes : {
		[string] : {
			[string] : any
		}
	},
	stack : nil,
}
export type markupsIndexable = {
	[string] : markupIndexable | stack<markupIndexable>
}

return module
