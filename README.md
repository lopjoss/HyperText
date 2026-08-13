# HyperText

HyperText is an advanced rich-text renderer for Roblox. It uses markup tags to style, animate, pace, and manipulate text, including gradients, images, typewriter effects, particles, clearing animations, and custom markups.

## General rules and behavior

Paired tags apply a markup to enclosed content:

```text
<color=red>Hello</color>
<anim=wiggle dur=1 loop=true>Animated text</anim>
```

Self-closing tags execute immediately:

```text
<img=123456789>
<br=1>
<wait=.5>
<renderEvent=finished>
```

Attributes are written inside the opening tag:

```text
<anim=wiggle dur=2 loop=true freq=3>
```

You can change an attribute without providing a new markup value:

```text
<anim loop=true>Text</anim>
```

General behavior:

- Tag, attribute, and predefined value capitalization does not matter.
- Arbitrary values such as font paths remain case-sensitive.
- Raw newlines are ignored. Use `<br=1>` instead.
- Literal `<` characters outside valid tags are unsupported.
- Optional markups and attributes can be removed with `/`.
- When updating default markups, use `HyperText.DELETE` instead of `/`.
- Destroying the container automatically destroys its HyperText object.

> Very small text or certain fonts may occasionally position a character one pixel unevenly because fractional positions and sizes ultimately have to be rasterized onto the pixel grid. There is no fixing this.

## Markup reference

### Paired markups

<details>
<summary><code>anim</code></summary>

The animation of the rendered content that plays when actively rendering. This markup can be deleted.

<table>
<tr><th>Luau value</th><td><code>("slide" | "bounce" | "wiggle" | "grow")?</code></td></tr>
<tr><th>ASCII value</th><td><code>slide | bounce | wiggle | grow | /</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `dur` | `number` | `number` | The duration of the animation, only accepts a number above or equal to 0. |
| `loop` | `boolean` | `true \| false` | Whether the animation should continuously reverse and repeat. |

#### Attributes for value `slide`

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `dir` | `"up" \| "down"` | `up \| down` | The direction in which the animated text moves. |
| `offset` | `number` | `number` | A fraction of text's size to offset the x and y starting position. |
| `rot` | `number` | `number` | The rotation in degrees when starting. |

#### Attributes for value `bounce`

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `dir` | `"up" \| "down"` | `up \| down` | The direction in which the animated text moves. |
| `offset` | `number` | `number` | A fraction of text's size to offset the y starting position. |
| `exp` | `number` | `number` | The exponent applied to the bouncing animation progress (Higher values produce deeper, more pronounced rebounds). |

#### Attributes for value `wiggle`

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `freq` | `number` | `number` | The sine wave frequency in Hz (higher value = wiggling faster). |
| `offset` | `number` | `number` | A fraction of one sine wave oscillation offset per character. |
| `amp` | `number` | `number` | A fraction of text's size which acts as the amplitude of the sine wave. |
| `rot` | `boolean` | `true \| false` | Whether each character aligns with the wave's tangent. |

#### Attributes for value `grow`

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `startScale` | `number` | `number` | The scale at which the rendered content starts before growing to its full size. |
| `exp` | `number` | `number` | The exponent applied to the eased animation progress (Higher values amplify the Back easing overshoot). |

</details>

<details>
<summary><code>clearAnim</code></summary>

The animation of the rendered content that plays when clearing the render. This markup has the same attributes as the `anim` markup, but ignores the `loop` attribute. Set its value to `"inherit"` for it to inherit the anim's values. This markup can be deleted.

<table>
<tr><th>Luau value</th><td><code>("slide" | "bounce" | "wiggle" | "grow" | "inherit")?</code></td></tr>
<tr><th>ASCII value</th><td><code>slide | bounce | wiggle | grow | inherit | /</code></td></tr>
</table>

</details>

<details>
<summary><code>color</code></summary>

The color of the rendered text. Can make use of shortcuts like red, green, blue, etc instead. Check the config module to see all those shortcuts.

<table>
<tr><th>Luau value</th><td><code>Color3</code></td></tr>
<tr><th>ASCII value</th><td><code>r,g,b | configured color shortcut</code></td></tr>
</table>

</details>

<details>
<summary><code>font</code></summary>

The font used for the rendered text.

<table>
<tr><th>Luau value</th><td><code>string | number</code></td></tr>
<tr><th>ASCII value</th><td><code>font family path | asset ID</code></td></tr>
</table>

</details>

<details>
<summary><code>italic</code></summary>

Indicates whether the rendered text should be italic or not.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

</details>

<details>
<summary><code>weight</code></summary>

The font weight of the rendered text.

<table>
<tr><th>Luau value</th><td><code>Enum.FontWeight</code></td></tr>
<tr><th>ASCII value</th><td><code>font weight name</code></td></tr>
</table>

</details>

<details>
<summary><code>trans</code></summary>

The transparency of the rendered text.

<table>
<tr><th>Luau value</th><td><code>number</code></td></tr>
<tr><th>ASCII value</th><td><code>number</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `tweenDur` | `number?` | `number \| /` | The duration of the transparency tween in seconds. If this attribute is deleted, transparency is applied immediately. |
| `tweenFrom` | `number` | `number` | The transparency from which the tween starts. |
| `loopTween` | `boolean` | `true \| false` | Whether the transparency tween should continuously reverse and repeat. |

</details>

<details>
<summary><code>clearTransDur</code></summary>

The duration over which it should make the rendered text fully transparent when calling `:Clear()`. Set its value to `"inherit"` for it to inherit the trans's `tweenDur` attribute value.

<table>
<tr><th>Luau value</th><td><code>number | "inherit"</code></td></tr>
<tr><th>ASCII value</th><td><code>number | inherit</code></td></tr>
</table>

</details>

<details>
<summary><code>size</code></summary>

The size of the rendered content in pixels. Supports sizes between 0 and 100. Unaffected by any `UIScale` applied to the container.

<table>
<tr><th>Luau value</th><td><code>number</code></td></tr>
<tr><th>ASCII value</th><td><code>number</code></td></tr>
</table>

</details>

<details>
<summary><code>shake</code></summary>

Shakes the rendered content.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `maxOffset` | `number` | `number` | The max possible fraction of text's size to offset the x and y starting position. |
| `dur` | `number` | `number` | The duration of the shake. |
| `loop` | `boolean` | `true \| false` | Whether the shake should loop or not. |
| `maxRot` | `number` | `number` | The max possible shake rotation in degrees. |
| `freq` | `number?` | `number \| /` | The number of shake position and rotation updates per second. If this attribute is deleted, the shake updates every frame. |
| `fade` | `boolean` | `true \| false` | Whether the shake strength gradually slows down as the effect approaches the end of its duration. |

</details>

<details>
<summary><code>rainbow</code></summary>

Cycles the rendered content's color through the colors of a rainbow, with each character slightly color shifted.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `freq` | `number` | `number` | The hue cycle frequency in Hz (higher value = changing color faster). |
| `offset` | `number` | `number` | A fraction of one hue cycle offset per character. |

</details>

<details>
<summary><code>emitImg</code></summary>

Emits an image with the given ID as a particle effect from the rendered content. This markup can be deleted and also inherits the flipbook attributes from the `img` markup.

<table>
<tr><th>Luau value</th><td><code>number?</code></td></tr>
<tr><th>ASCII value</th><td><code>asset ID | /</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `color` | `Color3` | `r,g,b` | The color of the image. |
| `applyTransform` | `boolean` | `true \| false` | Indicates whether the effect should account for the content's current positional and rotational transforms. |
| `aspectRatio` | `number` | `number` | The width to height ratio of the image. |
| `rate` | `number` | `number` | The emit requests per second per character. |
| `chance` | `number` | `number` | The chance in percentage of spawning an image per request. |
| `lifetime` | `NumberRange` | `min,max` | A range indicating the lifetime of the image in seconds. |
| `velX` | `NumberRange` | `min,max` | A range indicating the horizontal velocity measured in a fraction of the character's width per second. |
| `velY` | `NumberRange` | `min,max` | A range indicating the vertical velocity measured in a fraction of the text's size per second. |
| `rotVel` | `NumberRange` | `min,max` | A range indicating the rotational velocity measured in degrees per second. |
| `accelX` | `NumberRange` | `min,max` | A range indicating the horizontal acceleration measured in a fraction of the character's width per second squared. |
| `accelY` | `NumberRange` | `min,max` | A range indicating the vertical acceleration measured in a fraction of the text's size per second squared. |
| `startTrans` | `NumberRange` | `min,max` | A range indicating the transparency of the image at the beginning of its lifetime. |
| `endTrans` | `NumberRange` | `min,max` | A range indicating the transparency of the image at the end of its lifetime. |
| `startSize` | `NumberRange` | `min,max` | A range (fractional of the text's size) indicating the height of the image at the beginning of its lifetime. |
| `endSize` | `NumberRange` | `min,max` | A range (fractional of the text's size) indicating the height of the image at the end of its lifetime. |
| `startPosX` | `NumberRange` | `min,max` | A range (fractional of the character's width) indicating the horizontal offset of the image at the beginning of its lifetime. |
| `startPosY` | `NumberRange` | `min,max` | A range (fractional of the text's size) indicating the vertical offset of the image at the beginning of its lifetime. |
| `startRot` | `NumberRange` | `min,max` | A range indicating the rotation of the image at the beginning of its lifetime. |
| `flipbookLayout` | `Vector2?` | `x,y \| /` | The number of frames arranged horizontally and vertically in the image. When deleted, the image is not animated. |
| `flipbookFreq` | `number` | `number` | The number of times the flipbook traverses from its first frame to its final frame per second. |
| `flipbookLoop` | `boolean` | `true \| false` | Whether the flipbook animation repeats after completing. |
| `flipbookReverse` | `boolean` | `true \| false` | Whether the flipbook reverses back to the first frame after reaching the final frame. |

</details>

<details>
<summary><code>stroke</code></summary>

Gives the rendered text a stroke.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `trans` | `number?` | `number \| /` | The transparency of the stroke. If this attribute is deleted it will inherit the text's transparency. |
| `thickness` | `number` | `number` | A fraction of the text's size which acts as the thickness of the stroke. |
| `color` | `Color3` | `r,g,b` | The color of the stroke. |

</details>

<details>
<summary><code>shadow</code></summary>

Adds a shadow behind the rendered text.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `color` | `Color3` | `r,g,b` | The color of the shadow. |
| `offset` | `Vector2` | `x,y` | The horizontal offset as a fraction of the character's width and vertical offset as a fraction of the text's size. |
| `trans` | `number?` | `number \| /` | The transparency of the shadow. If this attribute is deleted, the shadow inherits the rendered text and stroke transparencies. |

</details>

<details>
<summary><code>underline</code></summary>

Underlines the rendered text.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

</details>

<details>
<summary><code>strike</code></summary>

Applies a strikethrough (horizontal line through the text) to the rendered text.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

</details>

<details>
<summary><code>mark</code></summary>

Highlights the rendered text.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `color` | `Color3` | `r,g,b` | The color of the highlight. |
| `trans` | `number` | `number` | The transparency of the highlight. |

</details>

<details>
<summary><code>interval</code></summary>

The interval in seconds between each printed character of the rendered text.

<table>
<tr><th>Luau value</th><td><code>number</code></td></tr>
<tr><th>ASCII value</th><td><code>number</code></td></tr>
</table>

</details>

<details>
<summary><code>clearInterval</code></summary>

The interval in seconds between each cleared character when calling `:Clear()`. Set its value to `"inherit"` for it to inherit the interval's value.

<table>
<tr><th>Luau value</th><td><code>number | "inherit"</code></td></tr>
<tr><th>ASCII value</th><td><code>number | inherit</code></td></tr>
</table>

</details>

<details>
<summary><code>soundId</code></summary>

The asset ID for the typewriter sound that will be played when actively rendering text. This markup can be deleted.

<table>
<tr><th>Luau value</th><td><code>(number | string)?</code></td></tr>
<tr><th>ASCII value</th><td><code>asset ID | asset URI | /</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `volume` | `number` | `number` | The volume of the created `Sound` instance. |

</details>

<details>
<summary><code>shiny</code></summary>

Adds shiny sparks to the rendered content. This markup uses the same attributes as the `emitImg` markup.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

</details>

<details>
<summary><code>fog</code></summary>

Adds a fog effect to the rendered content. This markup uses the same attributes as the `emitImg` markup.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

</details>

<details>
<summary><code>gradient</code></summary>

Applies a color gradient to the rendered content.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `colors` | `{Color3}` | `r,g,b;r,g,b;...` | The colors of the gradient, supporting up to 18 colors in one gradient. |
| `rot` | `number` | `number` | The rotation of the gradient in degrees. |
| `individual` | `boolean` | `true \| false` | Whether each character gets its own gradient instead of sharing one across the marked text. |
| `moveDir` | `"left" \| "right"` | `left \| right` | The direction in which the gradient colors move. |
| `moveSpeed` | `number` | `number` | The amount of full color revolutions the gradient moves per second. |
| `spacing` | `number` | `number` | A fraction of the marked text's width which is added in between each color. This attribute is only applicable when the `individual` attribute is set to false and only accepts a number above or equal to 0. |

</details>

<details>
<summary><code>strokeGradient</code></summary>

Applies a color gradient to the rendered text's stroke. This markup uses the same attributes as the `gradient` markup and requires the `stroke` markup to be set to true.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

</details>

<details>
<summary><code>decode</code></summary>

Applies a decode effect to the rendered text. Each character switches between random printable ASCII characters after being printed, then restores its original character when the effect's duration ends.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `dur` | `number` | `number` | The duration of the decode effect per character in seconds, only accepts a number above or equal to 0. |
| `freq` | `number?` | `number \| /` | The target number of random character substitutions per second. When deleted, it defaults to every frame. |
| `loop` | `boolean` | `true \| false` | Whether the decode effect continues forever. |

</details>

### Self-closing markups

<details>
<summary><code>img</code></summary>

Adds an image with the given ID.

<table>
<tr><th>Luau value</th><td><code>number</code></td></tr>
<tr><th>ASCII value</th><td><code>asset ID</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `plain` | `boolean` | `true \| false` | Prevents any markups that apply to images from being applied to the image, excluding clearing markups. |
| `height` | `number` | `number` | A fraction of the text's size indicating the height of the image, only accepts a number above or equal to 0. |
| `aspectRatio` | `number` | `number` | The width to height ratio of the image, only accepts a number above or equal to 0. |
| `trans` | `number?` | `number \| /` | The transparency of the image, if this attribute is deleted it inherits the text's transparency. |
| `color` | `Color3` | `r,g,b` | The color of the image. |
| `flipbookLayout` | `Vector2?` | `x,y \| /` | The number of frames arranged horizontally and vertically in the image. When deleted, the image is not animated. |
| `flipbookFreq` | `number` | `number` | The number of times the flipbook traverses from its first frame to its final frame per second. |
| `flipbookLoop` | `boolean` | `true \| false` | Whether the flipbook animation repeats after completing. |
| `flipbookReverse` | `boolean` | `true \| false` | Whether the flipbook reverses back to the first frame after reaching the final frame. |

</details>

<details>
<summary><code>wait</code></summary>

Pauses rendering for the specified time in seconds. Call `:ResumeRender()` to stop this wait and resume rendering.

<table>
<tr><th>Luau value</th><td><code>number</code></td></tr>
<tr><th>ASCII value</th><td><code>number</code></td></tr>
</table>

</details>

<details>
<summary><code>renderEvent</code></summary>

Will fire `.renderEvent` with its value passed as a string argument.

<table>
<tr><th>Luau value</th><td><code>string</code></td></tr>
<tr><th>ASCII value</th><td><code>string</code></td></tr>
</table>

</details>

<details>
<summary><code>br</code></summary>

Adds a line break for the specified amount. Only accepts a number equal or above 1. Receives a height equal to the current text size on creation.

<table>
<tr><th>Luau value</th><td><code>number</code></td></tr>
<tr><th>ASCII value</th><td><code>number >= 1</code></td></tr>
</table>

</details>

### Markups without tags

These markups can only be applied by changing an object's default markups.

<details>
<summary><code>ZIndex</code></summary>

The Z index given to any rendered content.

<table>
<tr><th>Luau value</th><td><code>number</code></td></tr>
<tr><th>ASCII value</th><td>Not available because this markup doesn't use tags.</td></tr>
</table>

</details>

<details>
<summary><code>horizontalAlignment</code></summary>

The horizontal alignment of the rendered content.

<table>
<tr><th>Luau value</th><td><code>Enum.HorizontalAlignment</code></td></tr>
<tr><th>ASCII value</th><td>Not available because this markup doesn't use tags.</td></tr>
</table>

</details>

<details>
<summary><code>verticalAlignment</code></summary>

The vertical alignment of the rendered content.

<table>
<tr><th>Luau value</th><td><code>Enum.VerticalAlignment</code></td></tr>
<tr><th>ASCII value</th><td>Not available because this markup doesn't use tags.</td></tr>
</table>

</details>

<details>
<summary><code>scaleDimension</code></summary>

The container's dimension used as a reference to proportionally scale the rendered content.

<table>
<tr><th>Luau value</th><td><code>"X" | "Y"</code></td></tr>
<tr><th>ASCII value</th><td>Not available because this markup doesn't use tags.</td></tr>
</table>

</details>

<details>
<summary><code>sizeConstraint</code></summary>

The size constraint of the rendered content.

<table>
<tr><th>Luau value</th><td><code>Enum.SizeConstraint</code></td></tr>
<tr><th>ASCII value</th><td>Not available because this markup doesn't use tags.</td></tr>
</table>

</details>

## API

<details>
<summary><code>.new(container, markups) : hyperTextClassObject</code></summary>

Creates and returns a new HyperText object.

| Parameter | Type | Description |
| --- | --- | --- |
| `container` | `GuiObject` | The `GuiObject` that will contain any rendered content. When it gets destroyed, the object gets destroyed too. |
| `markups` | `markups?` | Calls `:UpdateDefaultMarkups()` with the given markups dict if provided. Obtained from calling `.newMarkups()`. |

</details>

<details>
<summary><code>.newMarkups() : markups</code></summary>

Returns a full markups shaped dict with values/attributes emptied to nil.

</details>

<details>
<summary><code>.insertStackEntry(markup : types.stack<T>, index : number) : T</code></summary>

Inserts and returns a new markup entry into a stackable markup at the given index which receives its default entry values

</details>

<details>
<summary><code>:UpdateDefaultMarkups(markups)</code></summary>

Merges the given markups dictionary into the object's default markups. To delete a default markup or attribute, set its value to `HyperText.DELETE`. For stackable markups, the following operations can be done (note that stack arrays are sparse, meaning a removed entry will leave a gap):

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

| Parameter | Type | Description |
| --- | --- | --- |
| `markups` | `markups` | The dict, obtained from calling `.newMarkups()`. |

</details>

<details>
<summary><code>:Render(text, yield, wrapped, constructOnly)</code></summary>

Renders the given text inside the object's container and applies the object's default markups & attributes to it. Stops any previous render and clears its text.

| Parameter | Type | Description |
| --- | --- | --- |
| `text` | `string` | The text (including its markups) that is going to be rendered. |
| `yield` | `boolean?` | Indicates whether the render should yield the calling thread. |
| `wrapped` | `boolean?` | Indicates whether the rendered content should wrap inside the object's container. Defaults to true. |
| `constructOnly` | `boolean?` | Indicates whether this render should only be constructed internally, not rendered. This parameter is meant to be used with `:GetConstructionSize()` to get the expected size of a render without actually rendering anything. |

</details>

<details>
<summary><code>:CompleteRender()</code></summary>

Skips all remaining render intervals immediately. If uncached text bounds are still being calculated asynchronously, this method may return before the render finishes.

</details>

<details>
<summary><code>:PauseRender()</code></summary>

Pauses a render.

</details>

<details>
<summary><code>:ResumeRender()</code></summary>

Resumes a paused render.

</details>

<details>
<summary><code>:Clear(instant)</code></summary>

Stops a render and clears any rendered content. Yields the calling thread until all clearing markups have completed.

| Parameter | Type | Description |
| --- | --- | --- |
| `instant` | `boolean?` | Ignores the clearing markups and clears the text instantly. |

</details>

<details>
<summary><code>:GetConstructionSize() : Vector2?</code></summary>

Returns the final width and height of the last render.

</details>

<details>
<summary><code>:GetPlainText() : string?</code></summary>

Returns the text used in the last render with all markup tags removed.

</details>

<details>
<summary><code>:Destroy()</code></summary>

Stops a render, clears any rendered content, and destroys owned instances.

</details>

<details>
<summary><code>.onRenderEnded</code></summary>

A Signal object that fires when a render has completed. Excluding construction only renders. When fired it receives one boolean argument which indicates whether it originated from `:CompleteRender()`. If you have a render that yields the calling thread, I recommend connecting to it before calling `:Render()`, since renders that yield the calling thread and do not yield internally complete synchronously.

</details>

<details>
<summary><code>.renderEvent</code></summary>

A Signal object that fires when any `<renderEvent=arg>` markup has been reached. When fired it receives one string argument which is the value of the markup.

</details>

<details>
<summary><code>.rendering</code></summary>

A boolean that indicates whether the object has any active render, despite it possibly being paused.

</details>

## Creating custom markups

A custom markup requires matching definitions in `Types`, `Config`, and a markup data module.

<details>
<summary><code>1. Define the schema</code></summary>

Add a key matching the markup name to the `markups` type in `Types.luau`.

Give it `value`, `attributes`, and `valueAttributes` fields. Optional value and attribute types must include `nil`. `valueAttributes` is keyed by each markup value that has its own attributes.

```luau
pulse : {
	value : boolean?,
	attributes : {
		speed : number,
		color : Color3?,
	},
	valueAttributes : {},
},
```

</details>

<details>
<summary><code>2. Add the defaults</code></summary>

Add the markup to `DEFAULT_MARKUPS` in `Config.luau`.

The `value`, `attributes`, and `valueAttributes` tables must match `Types`. Provide defaults for every required attribute and value-specific attribute. Optional values and attributes can be omitted or set to `nil`.

```luau
pulse = {
	value = nil,
	attributes = {
		speed = 1,
	},
	valueAttributes = {},
},
```

</details>

<details>
<summary><code>3. Create the data module</code></summary>

Add a `ModuleScript` below `Markups/Paired` or `Markups/SelfClosing`.

All descendant data modules are discovered automatically. Clone the closest existing markup when possible.

```luau
--!strict

local types = require("../../Types")
local util = require("../../Util")

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
		-- Apply the markup to printerData.character
	end,
}

return module
```

Every data module needs:

- A `name` field matching the key in `Types`.
- A `type` field of `"paired"` or `"selfClosing"`.
- A `convert` function that parses the tag's string value into the type from `Types`.
- `attributes` and `valueAttributes` converter dictionaries.
- `unrequired = true` when the markup value or attribute type is optional.
- The appropriate rendering or construction callbacks.

Value-specific converters use the same converter shape nested below each possible markup value. A converter must return the correctly typed value or throw for invalid input.

The generic arguments of `types.dataModule` are:

```luau
types.dataModule<
	markupName,
	markupType,
	applyToImages, -- applies only to paired markups
	applyOnClear, -- applies only to paired markups
	appendToCurrentWord -- applies only to self closing markups
>
```

### Paired markup behavior

- `onPrint` receives the HyperText object, the current printer row entry, the position and size of the character and markup span, and an updater dictionary for per-frame work.
- To apply the markup to inline images, set `applyToImages = true`, pass it as the third `dataModule` generic, and type the character as `TextLabel | ImageLabel`.
- To run while text is being cleared, set `applyOnClear = true` and pass it as the fourth generic.
- Clearing markups must implement `validate(markups) -> boolean`, `getClearingDuration(markups) -> number`, and `onPrint` with an additional `onClear` boolean.
- If application order matters, add the markup name to `PRINT_PRIORITY` in `Config.luau`. Unlisted markups run first; listed markups then run from top to bottom.

### Self-closing markup behavior

- Structural mode leaves `appendToCurrentWord` unset.
- Structural markups can implement `onConstruction(obj, markups, rowIndex)` to modify construction. See `br`.
- Inline mode sets `appendToCurrentWord = true` and passes it as the fifth `dataModule` generic.
- Inline markups must implement `getSize` for layout and `onPrint_` for delivery.
- Set `yieldFromIntervalOnPrint = true` when the normal typewriter interval should run before `onPrint_`.

Useful references:

- `color` for a basic paired markup.
- `anim` for attributes and image support.
- `clearAnim` for clearing hooks.
- `br` for structural self-closing construction.
- `wait` for a zero-size inline self-closing action.
- `img` for a rendered inline self-closing object.

Keep the schema in `Types`, defaults in `Config`, and converter dictionaries in the data module synchronized. Their names and value types are checked by the `dataModule` type, so mismatches should be fixed instead of cast away.

</details>
