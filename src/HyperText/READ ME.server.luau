--[[
	To see the API or other info, check the main module
	See Config to alter any settings

	If you encounter any bugs or have any questions DM me on discord @lopjoss

    How to make your own markups:

    1. Define the markup schema in the markups type in Internal/Types:
        - Add a key whose name matches the markup.
        - Give it value, attributes, and valueAttributes fields.
        - Optional value and attribute types must include nil.
        - valueAttributes is keyed by each markup value that has its own
          attributes.

        Example:

        pulse : {
            value : boolean?,
            attributes : {
                speed : number,
                color : Color3?,
            },
            valueAttributes : {},
        },

    2. Add the markup to DEFAULT_MARKUPS in Internal/Config:
        - Add value, attributes, and valueAttributes tables matching Types.
        - Provide defaults for every required attribute and value-specific
          attribute.
        - Optional values and attributes can be omitted or set to nil.

        For the pulse schema above:

        pulse = {
            value = nil,
            attributes = {
                speed = 1,
            },
            valueAttributes = {},
        },

    3. Add a ModuleScript below Markups/Paired or Markups/SelfClosing. The
       folders are organizational; all descendant ModuleScripts are discovered
       automatically. Clone the closest existing markup when possible.

       Every data module needs:
        - name as a singleton string matching the key in Types
        - type set to "paired" or "selfClosing"
        - convert to parse the tag's string value into the type from Types
        - attributes and valueAttributes converter dictionaries
        - unrequired = true when the markup value type is optional

       Attribute converters use this shape:

        attributes = {
            speed = {
                convert = util.stringToNumber,
            },
            color = {
                convert = util.stringToColor3,
                unrequired = true,
            },
        }

       valueAttributes has the same converter shape nested below each possible
       markup value. A converter should return the correctly typed value or
       throw for invalid input. Set unrequired = true for each optional
       attribute.

       The generic arguments of types.dataModule are:

        types.dataModule<
            markupName,
            markupType,
            applyToImages,
            applyOnClear,
            appendToCurrentWord
        >

       The final three arguments default to nil. When enabling one, declare it
       as a singleton true and pass typeof(variable), as existing modules do.

    Paired markups:

        local name : "pulse" = "pulse"
        local type_ : "paired" = "paired"
        local module : types.dataModule<typeof(name), typeof(type_)> = {
            name = name,
            type = type_,
            unrequired = true,
            convert = util.stringToBoolean,
            attributes = {
                speed = {
                    convert = util.stringToNumber,
                },
                color = {
                    convert = util.stringToColor3,
                    unrequired = true,
                },
            },
            valueAttributes = {},

            onPrint = function(obj, printerData, spanData, updater)
                -- apply the current markup to printerData.character
            end,
        }

        return module

        onPrint receives the HyperText object, the current printer row entry,
        the position and size of the character and markup span, and an updater
        dictionary for per-frame work.

        To apply a paired markup to inline images, set applyToImages = true,
        pass it as the third dataModule generic, and type the character as
        TextLabel | ImageLabel.

        To run a markup while text is being cleared, set applyOnClear = true
        and pass it as the fourth generic. Also implement:
        - validate(markups) -> boolean
        - getClearingDuration(markups) -> number
        - onPrint with an additional onClear boolean parameter

        If application order matters, add the markup name to
        PRINT_PRIORITY in Internal/Config. Unlisted markups run first; listed
        markups then run from top to bottom.

    Self-closing markups:

        Self-closing markups have two execution modes.

        Structural mode leaves appendToCurrentWord unset. Implement the
        optional onConstruction(obj, markups, rowIndex) callback to modify
        construction. See br for an example.

        Inline mode sets appendToCurrentWord = true and passes it as the fifth
        dataModule generic:

        local name : "customInline" = "customInline"
        local type_ : "selfClosing" = "selfClosing"
        local appendToCurrentWord : true = true
        local module : types.dataModule<
            typeof(name),
            typeof(type_),
            nil,
            nil,
            typeof(appendToCurrentWord)
        > = {
            name = name,
            type = type_,
            appendToCurrentWord = appendToCurrentWord,
            convert = util.stringToNumber,
            attributes = {},
            valueAttributes = {},

            getSize = function(obj, markups)
                return Vector2.zero
            end,
            onPrint_ = function(obj, markups, index, row, updater)
                -- create or perform the inline entry
            end,
        }

        return module

        Inline self-closing markups must implement getSize for layout and
        onPrint_ for delivery. Set yieldFromIntervalOnPrint = true when the
        normal typewriter interval should run before onPrint_.

        Useful examples:
        - color for a basic paired markup
        - anim for attributes and image support
        - clearAnim for clearing hooks
        - br for structural self-closing construction
        - wait for a zero-size inline self-closing action
        - img for a rendered inline self-closing object

    Keep the schema in Types, defaults in Config, and converter dictionaries in
    the data module synchronized. Their names and value types are checked by
    the dataModule type, so mismatches should be fixed instead of cast away.
]]