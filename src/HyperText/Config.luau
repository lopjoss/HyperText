--!strict

local types = require("./Types")

local config = {}

-- color shortcuts used for color values of markups or attributes
config.COLOR_SHORTCUTS = {}
config.COLOR_SHORTCUTS.white        = Color3.fromRGB(255, 255, 255)
config.COLOR_SHORTCUTS.black        = Color3.fromRGB(0, 0, 0)
config.COLOR_SHORTCUTS.red          = Color3.fromRGB(255, 70, 70)
config.COLOR_SHORTCUTS.darkred      = Color3.fromRGB(150, 0, 0)
config.COLOR_SHORTCUTS.lightred     = Color3.fromRGB(255, 170, 170)
config.COLOR_SHORTCUTS.green        = Color3.fromRGB(70, 255, 70)
config.COLOR_SHORTCUTS.darkgreen    = Color3.fromRGB(0, 120, 0)
config.COLOR_SHORTCUTS.lightgreen   = Color3.fromRGB(170, 255, 170)
config.COLOR_SHORTCUTS.blue         = Color3.fromRGB(70, 130, 255)
config.COLOR_SHORTCUTS.darkblue     = Color3.fromRGB(0, 70, 160)
config.COLOR_SHORTCUTS.lightblue    = Color3.fromRGB(170, 210, 255)
config.COLOR_SHORTCUTS.yellow       = Color3.fromRGB(255, 199, 32)
config.COLOR_SHORTCUTS.darkyellow   = Color3.fromRGB(170, 150, 0)
config.COLOR_SHORTCUTS.lightyellow  = Color3.fromRGB(255, 250, 170)
config.COLOR_SHORTCUTS.orange       = Color3.fromRGB(255, 140, 40)
config.COLOR_SHORTCUTS.darkorange   = Color3.fromRGB(200, 100, 0)
config.COLOR_SHORTCUTS.lightorange  = Color3.fromRGB(255, 200, 140)
config.COLOR_SHORTCUTS.purple       = Color3.fromRGB(170, 70, 255)
config.COLOR_SHORTCUTS.darkpurple   = Color3.fromRGB(100, 0, 180)
config.COLOR_SHORTCUTS.lightpurple  = Color3.fromRGB(220, 180, 255)
config.COLOR_SHORTCUTS.pink         = Color3.fromRGB(255, 100, 200)
config.COLOR_SHORTCUTS.darkpink     = Color3.fromRGB(180, 0, 100)
config.COLOR_SHORTCUTS.lightpink    = Color3.fromRGB(255, 180, 230)
config.COLOR_SHORTCUTS.cyan         = Color3.fromRGB(100, 220, 255)
config.COLOR_SHORTCUTS.darkcyan     = Color3.fromRGB(0, 150, 180)
config.COLOR_SHORTCUTS.lightcyan    = Color3.fromRGB(180, 240, 255)
config.COLOR_SHORTCUTS.gray         = Color3.fromRGB(150, 150, 150)
config.COLOR_SHORTCUTS.darkgray     = Color3.fromRGB(80, 80, 80)
config.COLOR_SHORTCUTS.lightgray    = Color3.fromRGB(220, 220, 220)

--[[
	the value of which you must set applicable markups or attributes to in
	order to delete it
]]
config.DELETE_MARKUP_VALUE_SYNTAX = "/"

--[[
	the minimum interval between typewriter sounds
]]
config.MIN_TYPEWRITER_SFX_INTERVAL = .065

--[[
	for any cache record limit config note that:
	- if the amount of cache records exceeds this limit, the oldest cache
	  record will be evicted
	- set it to nil for there to be no limit
	- cache is shared between all objects
]]
--[[
	the maximum amount of typewriter sounds which can be cached at once

	note that:
	this is meant to evict sounds of old / unused renders from cache, but
	it does not guarantee that only unused sounds will get evicted, so a low
	limit could mean that a render which uses a sound that got evicted while
	its rendering has to fetch it back which could cause delays in SFX
]]
config.MAX_TYPEWRITER_SFX_CACHE_RECORDS = 50

--[[
	the maximum amount of image sizes (vector2's) which can be cached at once
	(used for flipbook effects)

	the same notice of the typewriter SFX cache applies here
]]
config.MAX_FLIPBOOK_IMG_SIZE_CACHE_RECORDS = 1000

--[[
	the maximum amount of individual character's textbounds which can be cached
	at once 
]]
config.MAX_TEXTBOUNDS_CACHE_RECORDS = 500

--[[	
	any word wider than this fraction of the container's width which doesn't
	fit on the current row will be split instead of being fully moved to a
	new row
]]
config.SPLIT_WORD_AT_FRACTION = .3

--[[
	the max amount of characters of a render's text displayed for debugging
	when overflowing
]]
config.DEBUG_OVERFLOW_MAX_TEXT_LENGTH = 40

--[[
	default markup and attribute values for all objects

	(must include every markup and attribute, unless optional ones must be
	deleted by default, in that case you can leave those out)
]]
local DEFAULT_MARKUPS : types.markups = {
	color = {
		value = Color3.new(1, 1, 1),
		attributes = {},
		valueAttributes = {},
	},
	font = {
		value = "rbxasset://fonts/families/FredokaOne.json",
		attributes = {},
		valueAttributes = {},
	},
	size = {
		value = 16,
		attributes = {},
		valueAttributes = {},
	},
	horizontalAlignment = {
		value = Enum.HorizontalAlignment.Left,
		attributes = {},
		valueAttributes = {},
	},
	verticalAlignment = {
		value = Enum.VerticalAlignment.Top,
		attributes = {},
		valueAttributes = {},
	},
	scaleDimension = {
		value = "Y",
		attributes = {},
		valueAttributes = {},
	},
	sizeConstraint = {
		value = Enum.SizeConstraint.RelativeXY,
		attributes = {},
		valueAttributes = {},
	},
	interval = {
		value = .015,
		attributes = {},
		valueAttributes = {},
	},
	clearInterval = {
		value = 0,
		attributes = {},
		valueAttributes = {},
	},
	anim = {
		value = "slide",
		attributes = {
			dur = .5,
			loop = false,
		},
		valueAttributes = {
			slide = {
				dir = "down",
				offset = .75,
				rot = 55,
			},
			bounce = {
				dir = "down",
				offset = .75,
				exp = 1,
			},
			wiggle = {
				freq = .75,
				offset = .12,
				amp = .3,
				rot = true,
			},
			grow = {
				exp = 5,
				startScale = 0,
			}
		},
	},
	clearAnim = {
		value = nil,
		attributes = {
			dur = .5,
			loop = false,
		},
		valueAttributes = {
			slide = {
				dir = "down",
				offset = .75,
				rot = 55,
			},
			bounce = {
				dir = "down",
				offset = .75,
				exp = 1,
			},
			wiggle = {
				freq = .75,
				offset = .12,
				amp = .3,
				rot = true,
			},
			grow = {
				exp = 5,
				startScale = 0,
			}
		},
	},
	weight = {
		value = Enum.FontWeight.Regular,
		attributes = {},
		valueAttributes = {},
	},
	italic = {
		value = false,
		attributes = {},
		valueAttributes = {},
	},
	trans = {
		value = 0,
		attributes = {
			tweenFrom = 1,
			loopTween = false
		},
		valueAttributes = {},
	},
	clearTransDur = {
		value = 0,
		attributes = {},
		valueAttributes = {},
	},
	ZIndex = {
		value = 1,
		attributes = {},
		valueAttributes = {},
	}	,
	mark = {
		value = false,
		attributes = {
			color = config.COLOR_SHORTCUTS.yellow,
			trans = .5,
		},
		valueAttributes = {},
	},
	rainbow = {
		value = false,
		attributes = {
			freq = .5,
			offset = 0.05,
		},
		valueAttributes = {},
	},
	shake = {
		value = false,
		attributes = {
			maxOffset = .05,
			dur = 2,
			loop = false,
			maxRot = 10,
			fade = true,
		},
		valueAttributes = {},
	},
	stroke = {
		value = false,
		attributes = {
			trans = nil,
			thickness = .025,
			color = Color3.new(0, 0, 0),
		},
		valueAttributes = {},
	},
	underline = {
		value = false,
		attributes = {},
		valueAttributes = {},
	},
	strike = {
		value = false,
		attributes = {},
		valueAttributes = {},
	},
	shiny = {
		stack = {},
		_entryDefaultValues = {
			value = false,
			attributes = {
				color = Color3.fromRGB(255, 255, 255),
				aspectRatio = .66,
				rate = .75,
				chance = 50,
				lifetime = NumberRange.new(2, 2.75),
				velX = NumberRange.new(0, 0),
				velY = NumberRange.new(0, 0),
				rotVel = NumberRange.new(0, 0),
				accelX = NumberRange.new(0, 0),
				accelY = NumberRange.new(-.25, -.15),
				startTrans = NumberRange.new(0, 0),
				endTrans = NumberRange.new(1, 1),
				startSize = NumberRange.new(.5, .6),
				endSize = NumberRange.new(.2, .3),
				startPosX = NumberRange.new(-.5, .5),
				startPosY = NumberRange.new(-.5, .5),
				startRot = NumberRange.new(0, 0),
				applyTransform = true,
				flipbookFreq = 1,
				flipbookLoop = false,
				flipbookReverse = false,
			},
			valueAttributes = {},
		}
	},
	fog = {
		stack = {},
		_entryDefaultValues = {
			value = false,
			attributes = {
				color = Color3.fromRGB(130, 130, 130),
				aspectRatio = 1,
				rate = 2,
				chance = 80,
				lifetime = NumberRange.new(5, 7),
				velX = NumberRange.new(0, 0),
				velY = NumberRange.new(0, 0),
				rotVel = NumberRange.new(-40, 40),
				accelX = NumberRange.new(-.15, .15),
				accelY = NumberRange.new(-.15, .15),
				startTrans = NumberRange.new(.9, .95),
				endTrans = NumberRange.new(1, 1),
				startSize = NumberRange.new(1, 2),
				endSize = NumberRange.new(4, 5),
				startPosX = NumberRange.new(-.5, .5),
				startPosY = NumberRange.new(-.5, .5),
				startRot = NumberRange.new(-360, 360),
				applyTransform = true,
				flipbookFreq = 1,
				flipbookLoop = false,
				flipbookReverse = false,
			},
			valueAttributes = {},
		}
	},
	gradient = {
		value = false,
		attributes = {
			colors = {Color3.fromRGB(85, 170, 255), Color3.fromRGB(255, 85, 0)},
			rot = 0,
			individual = false,
			moveDir = "right",
			spacing = 0,
			moveSpeed = 0,
		},
		valueAttributes = {},
	},
	strokeGradient = {
		value = false,
		attributes = {
			colors = {Color3.fromRGB(85, 170, 255), Color3.fromRGB(255, 85, 0)},
			rot = 0,
			individual = false,
			moveDir = "right",
			spacing = 0,
			moveSpeed = 0,
		},
		valueAttributes = {},
	},
	emitImg = {
		stack = {},
		_entryDefaultValues = {
			value = 0,
			attributes = {
				color = Color3.fromRGB(255, 255, 255),
				aspectRatio = 1,
				rate = 4,
				chance = 25,
				lifetime = NumberRange.new(1, 3),
				velX = NumberRange.new(-.25, .25),
				velY = NumberRange.new(-1.25, -1),
				rotVel = NumberRange.new(-70, 70),
				accelX = NumberRange.new(-.2, .2),
				accelY = NumberRange.new(1.75, 2),
				startTrans = NumberRange.new(0, 0),
				endTrans = NumberRange.new(1, 1),
				startSize = NumberRange.new(.75, 1),
				endSize = NumberRange.new(.3, .5),
				startPosX = NumberRange.new(-.5, .5),
				startPosY = NumberRange.new(-.5, .5),
				startRot = NumberRange.new(-360, 360),
				applyTransform = true,
				flipbookFreq = 1,
				flipbookLoop = false,
				flipbookReverse = false,
			},
			valueAttributes = {},
		}
	},
	soundId = {
		value = nil,
		attributes = {
			volume = .5,
		},
		valueAttributes = {},
	},
	decode = {
		value = false,
		attributes = {
			dur = .5,
			loop = false,
		},
		valueAttributes = {},
	},
	shadow = {
		value = false,
		attributes = {
			color = Color3.fromRGB(0, 0, 0),
			offset = Vector2.new(.15, .125),
		},
		valueAttributes = {},
	},
	img = {
		value = 0,
		attributes = {
			plain = false,
			height = 1,
			aspectRatio = 1,
			color = Color3.fromRGB(255, 255, 255),
			flipbookFreq = 1,
			flipbookLoop = false,
			flipbookReverse = false,
		},
		valueAttributes = {},
	},
	bgImg = {
		stack = {},
		_entryDefaultValues = {
			value = 0,
			attributes = {
				trans = 0,
				color = Color3.fromRGB(255, 255, 255),
				flipbookFreq = 1,
				flipbookLoop = false,
				flipbookReverse = false,
			},
			valueAttributes = {}
		}
	},
	br = {
		value = 0,
		attributes = {},
		valueAttributes = {},
	},
	wait = {
		value = 0,
		attributes = {},
		valueAttributes = {},
	},
	renderEvent = {
		value = "",
		attributes = {},
		valueAttributes = {},
	},
}
config.DEFAULT_MARKUPS = DEFAULT_MARKUPS

-- shiny markup image id
config.SHINY_IMG_ID = 115010102642915

-- fog markup image id
config.FOG_IMG_ID = 122434532

--[[
	the order in which markups are applied from top to bottom, the ones left out
	are applied first
	
	don't change this unless you know what you're doing
]]
local PRINT_PRIORITY : {types.markup} = {
	-- needs the character's text transparency to be finalized
	"stroke",
	
	-- overwrites the character's text color
	"gradient",
	
	-- needs the character's text to be finalized
	"decode",
	
	-- needs the stroke to be created or not
	"strokeGradient",
	
	-- needs everything about the character to be finalized and needs the final character container
	"shadow",
	
	-- needs anything that reads the character's text transparency to go before
	"anim",
	
	-- need the final character container for the applyTransform attribute
	"emitImg",
	"fog",
	"shiny",
}
config.PRINT_PRIORITY = PRINT_PRIORITY

return config
