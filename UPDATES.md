--[[ TODO:
	- custom fonts
	- classes
	- responsive kerning
	- applyToWhitespace field in markup datamodule
	- remove extreme hot paths
	- make pausing preserve interval and wait markup delays once resumed
]]

--[[	v4.2.1		10-10-2026

	FIXES:
		fixed an annoying issue where the stroke markup would have an incorrect size when created

]]

--[[	v4.2.0		6-9-2026

	ADDITIONS:
		added caching limits in configs
		added the bgImg markup

	CHANGES:
		typewriter sounds are now preloaded during parsing, preventing delays when the soundId markup changes during rendering
		image sizes for flipbook effects are now fetched during construction, so flipbook images appear immediately instead of popping in after their size has been fetched
		the parser now warns if it finds an opening tag with no assigned value or attributes, which it now won't process
		the module now errors if it finds a markup or attribute missing from the default markups or if you assign an invalid value to any markup or attribute, the latter also applies when you update an object's default markups, but it'll warn instead
		image emitting markups have now the possiblity to be stacked, meaning nested tag pairs will all be applied
		self-closing markups tags do not necessarily need an assigned value anymore, if no value is assigned it'll use its default value
		all image markup now support images from URI's

	FIXES:
		fixed plain images being inserted at the start of a new row
		fixed wiggle anim rotation not being uniform across different scales
		fixed attributes which are set to false not being able to be set to nil
		fixed a leading br markup not creating a line break
		fixed a leading invisible self closing markup make the first visible character yield
		fixed shadow not resizing correctly during character scaling
		fixed the grow animation not looping

]]

--[[	v4.1.0		9-8-2026

	ADDITIONS:
		added the renderEvent markup and the .renderEvent signal
		added the flipbookLayout, flipbookFreq, flipbookLoop, and flipbookReverse attributes to the img and emitimg markups

]]

--[[	v4.0.3		8-8-2026

	CHANGES:
		drastically improved the performance of live text scaling
		text should be even less unevenly spread at smaller sizes
		if you have a render configured for horizontal automatic sizing it now warns when wrapped is true and sets it to false

	FIXES:
		fixed a minor rendering issue where hyphens obtain the wrong width
]]


--[[	v4.0.2		7-8-2026

	FIXES:
		unevenly spread text shouldn't occur anymore (can still be slightly present with certain fonts or smaller sizes)
		fixed a bug where if you'd change the container's scale during construction text might overshoot out of the container during rendering

]]

--[[	v4.0.1		6-8-2026

	FIXES:
		fixed one critical bug where if you'd render in a container that changes in size the rendered text wouldn't obtain the correct width

]]

--[[	v4.0.0		5-8-2026

	ADDITIONS:
		method documentation comments are now back
		added the rot attribute to the wiggle animation
		added the maxRot attribute to the shake markup
		added the spacing attribute to the gradient and strokeGradient markups
		there is now an extra security measurement which warns when an user tries to delete a markup which cannot be deleted through updating an object's defaults
		added the applyTransform attribute to all image emitting markups
		added the Presets demo
		added the decode markup
		added the freq and fade attribute to the shake markup
		added the grow animation
		added the text shadow markup
		added the Animations demo
		added the exp attribute to the bounce animation
		there is now semantic input validation on all applicable markups or attributes
		added the clearAnim markup
		added the clearInterval markup
		added the tweenFrom, tweenDur, and the loopTween attribute to the trans markup
		added the clearTransDur markup
		
	CHANGES:
		onRenderEnded is now a Signal instead of a BindableEvent, making it alot more versatile
		the transparent animation, tweenTrans, and the tweenTrans attribute have been removed, use the trans markup with its new attributes instead
		the trans attribute of the img markup can now be deleted and it'll inherit the text's transparency if so
		performance has been reasonably improved by cutting back on the amount of UI instances being used
		removed the .empty field because it's just extra bug surface for a fairly niche convenience that is easy to implement externally
		image emitting markups and the gradient markup now apply to inline images
		the pre-render functionality has been removed, to get the expected size of a render now without actually rendering anything, use the new constructOnly parameter and the new :GetConstructionSize() method instead
		:GetRenderedTextBounds() has been removed, use :GetConstructionSize() instead
		removed the move attribute from the gradient markups, instead just use the moveSpeed attribute for movement 
		the gradient and strokeGradient colors attribute now only accept up to 18 colros

		for anyone who has made their own markups:
		string values passed to converts aren't always in lowercase anymore!
		printPriority has been removed, there is now a priority table in config
		markups arent automatically applied to whitespace anymore
		check the readme for more detailed info

	FIXES:
		fixed a bug where the soundId markup would not play any other sounds after one has failed to load
		fixed a bug where the thickness attribute of the stroke markup would just straight up not work... sory guys
		fixed server rendering waiting forever
		fixed an issue where an animated text with the mark markup highlighting it would also animate that highlighting
		fixed an issue where the value of the interval markup would not be applied to the first character after the opening tag
		fixed a bug where an animation on an inline image with a set transparency would tween that image to the value of the trans markup instead
		fixed an issue with the sizeConstraint markup where the rows would be incorrectly sized
		fixed some instabilities with word fitting and splitting
		closing tags put directly in a word now doesn't plit the word into 2 seperate words anymore
		fixed a bug where many whitespaces would not create new rows
		fixed one visually critical but quite uncommon rendering bug where if you apply a markup directly after the splitting point of a word the dash inherits that markup
		horizontally moving gradients shouldn't jump to snap anymore while rendering with intervals
		an error during a render shouldn't leave an object in a broken state anymore
		fixed an issue where the font markup would allow invalid fonts
		fixed a bug where 19 or more gradient colors would error
		fixed an issue where the wait markup's delayed thread would retain the object after calling :Clear() which would unnecessarily occupy memory
		fixed a bug where calling :CompleteRender() would not be immediate cus it would wait for the markup interval
		fixed loads of other smaller bugs and issues

]]

--[[	v3.2.0		9-7-2026

	ADDITIONS:
		added the move, moveDir, and moveSpeed attributes to the gradient markup
		added the strokeGradient markup

	CHANGES:
		renamed the slide animation rotation attribute and the gradient rotation attribute to rot
		replaced the color1 and color2 attribute of the gradient markup with the colors attribute so now any amount of colors are supported

]]

--[[	v3.1.0		7-7-2026

	ADDITIONS:
		added the :GetPlainText() method

]]

--[[	v3.0.0		28-6-2026

	ADDITIONS:
		added config.DELETE_MARKUP_VALUE_SYNTAX
		added the gradient markup
		added the tweenTransDur attribute to the anim markup

	CHANGES:
		its now possible to easily create and integrate your own markups or attributes (see the readme)
		multi byte UTF-8 characters (emoji's, accents, etc) are now supported
		the parser now warns when multiple of the same attributes have been found in a markup tag
		textbounds cache lookup is now a ton faster
		the parser is now way more stable and crash resistant
		you can now remove the emitimg markup by settings its value to /
		.empty now only becomes true once actual text or images have been visually rendered instead of just when a render starts
		the fog and shiny effect now use the same attributes as the emitImg markup
		attributes are now integrated into the markups, so .newAttributes() has been removed
		renamed .newMarkup() to .newMarkups()
		renamed the xalign markup to horizontalAlignment and the yalign markup to verticalAlignment
		renamed :UpdateDefaultMarkup() to :UpdateDefaultMarkups()
		if you want to remove a markup or attribute by changing an object's defaults, you must set its value now to HyperText.DELETE

	FIXES:
		fixed a bug where :GetRenderedTextBounds() could add an unwanted extra line to the height value
		fixed a bug where markups or attributes with a value of nil which are given to be set into an object's defaults dont get set
		fixed a bug where certain markups wouldn't get removed by setting their value to / 
		fixed the br markup where its value is more than 1 not displaying any empty new lines
		fixed a bug where the volume attribute would not change the volume of the cached typewriter sound
		fixed a bug where changing the dir markup of certain animations would error
		fixed a bug where the closing tag of certain markups would not remove it in specific situations
		fixed some of the documentation to be more accurate
		fixed some smelly state logic and type errors
		fixed a bug where animations wouldn't apply to images
		fixed a bug where an opening tag could influence the markup of an image printed before it
		fixed a bug where markups which take in a NumberRange value formatted as min,max would not allow negatives or decimals
		fixed some minor memory leaks
		fixed a bug where images would still show in pre-renders
		fixed loads of other more technical bugs

]]

--[[	v2.2.1		4-4-2026

	CHANGES:
		the font markup now allows for numbers and strings, so rbxassetid://123 and 123 are valid

	FIXES:
		fixed a bug where if you'd assign a number to the soundid markup in a text it'd fail to load the sound
		fixed a bug where the warning for a failed parsing attempt of an attribute would error 
		fixed several minor rendering bugs
		
]]

--[[	v2.2.0		3-4-2026

	ADDITIONS:
		added a new attribute plain to the img markup which prevents animations and effects to be applied to it
		added the trans attribute to the stroke markup 

	CHANGES:
		onRenderEnded now ignores pre-renders
		
		when rendering in a container with absolute size enabled on one of its axis,
		that axis is now allowed to have an absolute size of 0 (only when the sizeConstraint
		markup is set correctly!)
		
		img markup now allows for the current animation and active effects to be applied to the image
		(use the new plain attribute if you do not want this)
		
		when wrapping is enabled, the img markup now checks whether the image fits on the current line, if not, it creates a new line
		
	FIXES:
		fixed a bug where when an image gets added at the start of a line it doesn't show up
		fixed a bug where where a really tall image might extend into other lines
		fixed a bug where an image from the img markup would receive an incorrect zindex
		fixed a bug where overflow warnings on the x axis would not be shown
]]

--[[	v2.1.0		28-3-2026

	ADDITIONS:
		added 2 new examples in the demo folder which shows how to render inside a container with AutomaticSize
		added a height attribute to the img markup
		added a new markup called sizeConstraint which doesn't use tags
		added a new markup called scaleDimension which doesn't use tags
		documented some markups which weren't documented before

	FIXES:
		fixed a bug where images would scale up when bigger text is printed after it
		fixed a bug where attributes of values were not recognized
		fixed a bug where a non looping shake markup would keep characters scattered when completing a render

]]

--[[	v2.0.2		28-2-2026

	FIXES:
		fixed a non-breaking error when clearing any render

	CHANGES:
		soundid markup now allows for numbers and strings, so rbxassetid://123 and 123 are valid
		renders are now only possible when an object's container has an absolute width AND height above 0 which could otherwise yield unwanted behaviour

]]

--[[	v2.0.1		14-2-2026

	FIXES:
		fixed a bug where the wait markup, placed directly after text, would wait before the text printed

	CHANGES:
		capitalization concerning tags, attributes or values in a render's text now don't matter anymore

]]

--[[ 	v2.0.0		9-2-2026

	FIXES:
	
		fixed a bug where where all animations would stop immediately when a render ended
		fixed a few other minor rendering bugs

	CHANGES:
	
		changed name to HyperText
		changed :GetRenderedDimensions() to :GetRenderedTextBounds()
		changed typewriterinterval markup to interval
		changed transparency markup to trans
		changed typewritersoundid markup to soundid
		changed .newProperties() to .newMarkup() and have it's content resemble actual markup tags
		changed :UpdateProperties() to :UpdateDefaultMarkup() and allow it to update attributes as well
		changed the naming convention for all values of anim markup from PascalCase to fully lowercase
		
		removed the stinky effect, use the new fog markup with a green color attribute instead
		removed config.REFERENCE_SIZE
		removed "None" value for anim markup, remove these markups instead by giving it a value of "/"
		removed animloop and animduration markup, use the dur and loop attributes of the anim markup
		for this instead
		removed all config values for animations and effects, alter the default attribute values instead
		removed FromTop and FromBottom from certain animations, use the dir attribute instead
		removed the effect markup, instead each effect is now an individual markup, so it's possible to
		stack them
		removed config.TYPEWRITER_SFX_VOLUME, change the default value of the volume attribute of the
		typewritersoundid markup instead
		
	ADDITIONS:
	
		improved TextBounds cache retrieval

		added a new markup called zindex (does not use tags) which determines the z index of
		all rendered GuiObjects, meant for use cases where the ZIndexBehaviour of the ScreenGui
		in which the container is nested in is set to Global. Defaults to 1. (credits to @maxencexz!)
		
		added a .newAttributes() function which gives you an empty dict typed as attributes
		which you can pass to the constructor or :UpdateDefaultMarkup()

		it's now also possible to add attributes to markup tags (e.g. <anim=wiggle dur=5 loop=true>)
		
		added the emitimg markup
		added the img markup
		added the stroke markup
		added the underline markup
		added the strike markup
		added the mark markup
		added the fog markup
]]

--[[	v1.0.0		23-12-2025
	
	release

]]
