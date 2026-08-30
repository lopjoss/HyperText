# HyperText

HyperText is an advanced rich-text renderer for Roblox. It uses markup tags to style, animate, pace, and manipulate text, including gradients, images, typewriter effects, particles, clearing animations, and custom markups.

## General rules and behavior

Paired tags apply a markup to enclosed content:

```text
<color=red>Hello</color>
<anim=wiggle dur=1 loop=true>Animated text</anim>
```

Stackable paired tags keep every nested instance active:

```text
<emitImg=123><emitImg=456>Both emitters apply here</emitImg></emitImg>
```

Self-closing tags do not use closing tags:

```text
<img=123456789>
<br=1>
<wait=.5>
<renderEvent=finished>
```

Programmatic markups do not have tags. Change them through an object's default markups instead:

```luau
local markups = HyperText.newMarkups()
markups.horizontalAlignment.value = Enum.HorizontalAlignment.Center
markups.verticalAlignment.value = Enum.VerticalAlignment.Center

hyperText:UpdateDefaultMarkups(markups)
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
- Optional non-stackable paired markup values and optional attributes can be removed with `/`.
- Stackable paired markup values cannot be removed with `/`; use the closing tag to end an active stack entry.
- Self-closing markup values do not support `/` because each tag represents a single occurrence rather than persistent markup state.
- When updating default markups, use `HyperText.DELETE` instead of `/`. To remove a stackable default entry, assign it to the corresponding stack index.
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
<tr><th>ASCII value</th><td><code>font family path | asset URI | asset ID</code></td></tr>
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

Emits an image with the given ID or URI as a particle effect from the rendered content. This markup is stackable and inherits the flipbook attributes from the `img` markup.

<table>
<tr><th>Luau value</th><td><code>number | string</code></td></tr>
<tr><th>ASCII value</th><td><code>asset ID | asset URI</code></td></tr>
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
<summary><code>bgImg</code></summary>

Displays an image behind the complete span of marked text. The image’s ZIndex is one less than the ZIndex markup value, so the ZIndex markup value must therefore be at least 2 greater than the container’s ZIndex for the image to be visible. This markup is stackable and inherits the same flipbook attributes as the img markup.

<table>
<tr><th>Luau value</th><td><code>number | string</code></td></tr>
<tr><th>ASCII value</th><td><code>asset ID | asset URI</code></td></tr>
</table>

#### Attributes

| Attribute | Luau value | ASCII value | Description |
| --- | --- | --- | --- |
| `widthMul` | `number?` | `number \| /` | Multiplies the background image's width relative to the marked text's width. Only accepts a number above or equal to 0. |
| `heightMul` | `number?` | `number \| /` | Multiplies the background image's height relative to the marked text's height. Only accepts a number above or equal to 0. |
| `trans` | `number` | `number` | The transparency of the background image. |
| `color` | `Color3` | `r,g,b` | The color of the background image. |

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

The asset ID or URI for the typewriter sound that will be played when actively rendering text. This markup can be deleted.

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

Adds shiny sparks to the rendered content. This markup is stackable and uses the same attributes as the `emitImg` markup.

<table>
<tr><th>Luau value</th><td><code>boolean</code></td></tr>
<tr><th>ASCII value</th><td><code>true | false</code></td></tr>
</table>

</details>

<details>
<summary><code>fog</code></summary>

Adds a fog effect to the rendered content. This markup is stackable and uses the same attributes as the `emitImg` markup.

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
| `colors` | `{Color3}` | `r,g,b;r,g,b;...` | The colors of the gradient. Each gradient requires between 1 and 18 colors. |
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

Adds an image with the given ID or URI.

<table>
<tr><th>Luau value</th><td><code>number | string</code></td></tr>
<tr><th>ASCII value</th><td><code>asset ID | asset URI</code></td></tr>
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

### Programmatic markups

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

</details>

<details>
<summary><code>.insertStackEntry&lt;T&gt;(markup : types.stack&lt;T&gt;, index : number) : T</code></summary>

Returns a new markup stack entry with values/attributes emptied to nil, which is inserted into a stackable markup at the given index. Negative or extremely large indices will cause unintended behaviour.

</details>

<details>
<summary><code>:UpdateDefaultMarkups(markups)</code></summary>

Merges the given markups dictionary into the object's default markups. This method may yield.

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

Skips all remaining render intervals immediately. It does not skip or wait for yielding parsing or construction work, including resource fetching and custom callbacks, so it may return before the render finishes.

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

<details>
<summary><code>1. Define the schema</code></summary>

This schema is the source of truth for the value and attribute types that the data module that you'll create later must produce.

Add a key matching the markup name to the `markups` type in `Types.luau`. A regular markup entry contains:

- `value`: the converted value written after `=` in the tag.
- `attributes`: attributes available for every value of the markup.
- `valueAttributes`: attributes that only belong to particular markup values, keyed by those values.

Include `nil` in a value's or attribute's type if their value is unrequired, meaning the user can remove them (this is not allowed for a markup's value if the markup is stackable or a self-closing markup). For example:

```luau
pulse : {
	value : ("glow" | "blink")?,
	attributes : {
		speed : number,
		color : Color3?,
	},
	valueAttributes : {
		glow : {
			intensity : number,
		},
		blink : {
			minimumTransparency : number?,
		},
	},
},
```

For a stackable paired markup, wrap the entry shape in `stack<...>`:

```luau
pulse : stack<{
	value : "glow" | "blink",
	attributes : {
		speed : number,
		color : Color3?,
	},
	valueAttributes : {
		glow : {
			intensity : number,
		},
		blink : {
			minimumTransparency : number?,
		},
	},
}>,
```

</details>

<details>
<summary><code>2. Add the defaults</code></summary>

Add the markup to `DEFAULT_MARKUPS` in `Config.luau`. Its shape must match the entry in `Types.luau`.

Provide defaults for every required value, attribute, and value-specific attribute. Optional fields may be omitted or set to `nil`.

```luau
pulse = {
	value = nil,
	attributes = {
		speed = 1,
		color = nil,
	},
	valueAttributes = {
		glow = {
			intensity = 1,
		},
		blink = {
			minimumTransparency = .5,
		},
	},
},
```

A stackable markup instead stores its entry defaults in `_entryDefaultValues`:

```luau
pulse = {
	stack = {},
	_entryDefaultValues = {
		value = "glow",
		attributes = {
			speed = 1,
			color = nil,
		},
		valueAttributes = {
			glow = {
				intensity = 1,
			},
			blink = {
				minimumTransparency = .5,
			},
		},
	},
},
```

`stack` contains entries that are active by default. It is normally empty.

</details>

<details>
<summary><code>3. Create the data module</code></summary>

Use these examples as a reference to create your data module:

<details>
<summary><code>Listed here is an example of a stackable paired markup data module corresponding to the stackable pulse schema and defaults above.</code></summary>

```luau
--!strict

local types = require("../../Types") -- HyperText types and data-module contracts.
local util = require("../../Util") -- Reusable converters for markup values.

local name : "pulse" = "pulse" -- Selects the pulse schema from types.markups.
local type_ : "paired" = "paired" -- Declares this as a paired markup.
local applyToImages : true = true -- Also applies the markup to inline images.
local applyOnClear : true = true -- Also applies the markup while clearing.

local module : types.dataModule<
	typeof(name), -- Selects the exact markup schema.
	typeof(type_), -- Selects the paired-markup contract.
	typeof(applyToImages), -- Enables inline-image support.
	typeof(applyOnClear), -- Enables clearing support.
	nil -- Unused self-closing behavior.
> = {
	name = name, -- Must match the key in types.markups.
	type = type_, -- Must match the paired markup type.
	stackable = true, -- Required when the markup schema uses stack<...>.
	applyToImages = applyToImages, -- Allows onPrint to receive inline images.
	applyOnClear = applyOnClear, -- Allows onPrint to run during clearing.

	convert = function(value : string) : "glow" | "blink" -- Converts the raw tag value to its schema type.
		
	end,
	validateDefaultValue = function(value : "glow" | "blink") -- Validates or caches an already-converted default value.

	end,
	unrequired = false, -- If set to true it allows the markup's optional value to be removed with "/" (this is only applicable to non-stackable markups).

	attributes = { -- Converters for attributes available to every pulse value.
		speed = {
			validateDefaultValue = function(value : number) -- Applies the same restrictions to a default speed.
				if value < 0 then
					error("Value must be more than or equal to 0", 0)
				end
			end,
			convert = function(value : string) : number
				return util.stringToNumber(value, 0)
			end,
		},
		color = {
			convert = util.stringToColor3,
			unrequired = true, -- Allows this optional attribute to be removed with "/".
		},
	},

	valueAttributes = { -- Converters for attributes available only to their corresponding pulse value.
		glow = {
			intensity = {
				validateDefaultValue = function(value : number) -- Applies the same restrictions to a default intensity.
					if value < 0 then
						error("Value must be more than or equal to 0", 0)
					end
				end,
				convert = function(value : string) : number
					return util.stringToNumber(value, 0)
				end,
			},
		},
		blink = {
			minimumTransparency = {
				convert = function(value : string) : number
					return util.stringToNumber(value, 0, 1)
				end,
				unrequired = true,
			},
		},
	},

	onDefaultMarkupsChanged = function(markups : types.markups) -- Runs after global default validation and every default-markup update.

	end,

	onConstruction = function( -- Runs after parsing the tag but before printing starts.
		obj : types.hyperTextClassObject, -- HyperText object constructing the render.
		markups : types.markups -- Deep-copied markup state at the tag's position.
	)
		
	end,

	validate = function(markups : types.markups) : boolean -- Determines whether the clearing effect should run.
		
	end,

	getClearingDuration = function(markups : types.markups) : number -- Returns how long the clearing effect requires.
		
	end,

	onPrint = function( -- Runs for every relevant printed entry.
		obj : types.hyperTextClassObject, -- HyperText object printing the render.
		printerData : types.printerDataRowEntry, -- Current character or image and its markup state.
		spanData : types.onPrintMarkupSpanData, -- Geometry of the character and markup span.
		updater : {[string] : (dt : number) -> ()}, -- Shared per-frame callback dictionary.
		onClear : boolean -- Whether the markup is running during clearing.
	)
		for _, pulse in pairs(printerData.markups.pulse.stack) do
			if pulse then
				
			end
		end
	end,
}

return module
```

</details>

<details>
<summary><code>Listed here is an example of a self-closing markup data module.</code></summary>

```luau
--!strict

local types = require("../../Types") -- HyperText types and data-module contracts.
local util = require("../../Util") -- Reusable converters for markup values.

local name : "badge" = "badge" -- Selects the badge schema from types.markups.
local type_ : "selfClosing" = "selfClosing" -- Declares this as a self-closing markup.
local appendToCurrentWord : true = true -- Adds each markup instance to the current word, meaning it'll be included in layout and printing.

local module : types.dataModule<
	typeof(name), -- Selects the exact markup schema.
	typeof(type_), -- Selects the self-closing markup contract.
	nil, -- Unused paired-markup image behavior.
	nil, -- Unused paired-markup clearing behavior.
	typeof(appendToCurrentWord) -- Enables inline self-closing behavior.
> = {
	name = name, -- Must match the key in types.markups.
	type = type_, -- Must match the self-closing markup type.
	appendToCurrentWord = appendToCurrentWord, -- Includes the markup instance in layout and printing.
	yieldFromIntervalOnPrint = true, -- Runs the normal typewriter interval before onPrint_.

	convert = function(value : string) : "info" | "warning" -- Converts the raw tag value to its schema type.
		
	end,
	validateDefaultValue = function(value : "info" | "warning") -- Validates or caches an already-converted default value.

	end,

	attributes = { -- Converters for attributes available to every badge value.
		size = {
			validateDefaultValue = function(value : number) -- Applies the same restrictions to a default size.
				if value < 0 then
					error("Value must be more than or equal to 0", 0)
				end
			end,
			convert = function(value : string) : number
				return util.stringToNumber(value, 0)
			end,
		},
		color = {
			convert = util.stringToColor3,
			unrequired = true, -- Allows this optional attribute to be removed with "/".
		},
	},

	valueAttributes = { -- Converters for attributes available only to their corresponding badge value.
		info = {
			iconId = {
				convert = function(value : string) : number
					return util.stringToNumber(value, 0)
				end,
			},
		},
		warning = {
			flash = {
				convert = util.stringToBoolean,
				unrequired = true,
			},
		},
	},

	onDefaultMarkupsChanged = function(markups : types.markups) -- Runs after global default validation and every default-markup update.

	end,

	onConstruction = function( -- Runs after parsing the markup instance but before printing starts.
		obj : types.hyperTextClassObject, -- HyperText object constructing the render.
		markups : types.markups -- Deep-copied markup state for this markup instance.
	)
		
	end,

	getSize = function( -- Returns how much layout space the markup instance occupies.
		obj : types.hyperTextClassObject, -- HyperText object constructing the render.
		markups : types.markups -- Markup state used to calculate the size.
	) : Vector2
		
	end,

	onPrint_ = function( -- Runs once when the printer reaches this markup instance.
		obj : types.hyperTextClassObject, -- HyperText object printing the render.
		markups : types.markups, -- Markup state belonging to this markup instance.
		index : number, -- Index of the markup instance in the constructed row entries.
		row : Frame, -- Rendered row containing the markup instance.
		updater : {[string] : (dt : number) -> ()} -- Shared per-frame callback dictionary.
	)
		
	end,
}

return module
```

</details>

<details>
<summary><code>Listed here is an example of a programmatic markup data module.</code></summary>

```luau
--!strict

local types = require("../../Types") -- HyperText types and data-module contracts.

local name : "lineSpacing" = "lineSpacing" -- Selects the lineSpacing schema from types.markups.
local type_ : "programmatic" = "programmatic" -- Declares this as a tagless programmatic markup.

local module : types.dataModule<
	typeof(name), -- Selects the exact markup schema.
	typeof(type_) -- Selects the programmatic-markup contract.
> = {
	name = name, -- Must match the key in types.markups.
	type = type_,

	validateDefaultValue = function(value : number) -- Validates the initial value and later default-markup updates.
		if value < 0 then
			error("Value must be more than or equal to 0", 0)
		end
	end,

	onDefaultMarkupsChanged = function(markups : types.markups) -- Runs after initial validation and every default-markup update.
		-- Perform any shared preparation needed after lineSpacing changes.
	end,

	attributes = {},
	valueAttributes = {},
}

return module
```
> Important note: The data module registers and validates the setting, but does not automatically give it rendering behavior. The code implementing the setting must read `markups.lineSpacing.value` where it affects construction or rendering.
</details>

Place your data module directly inside `Markups/Paired`, `Markups/SelfClosing`, or `Markups/Programmatic`, according to its type. Only direct children of these folders are discovered.

</details>

### Data module behavior

<details>
<summary><code>Data module callbacks</code></summary>

| Callback | Purpose |
| --- | --- |
| `convert` | Converts a raw ASCII tag value to the type declared by the markup schema. |
| `validateDefaultValue` | Validates or caches a non-`nil`, already-converted default value. It returns nothing and must error to reject the value; it is not automatically called for values returned by `convert`. |
| `onDefaultMarkupsChanged` | Receives the complete defaults after global default validation and after every default-markup update. The table is not copied and should be treated as read-only. |
| `onConstruction` | Prepares the complete state of one parsed tag before printing. |
| `onPrint` | Applies a paired markup to each relevant printed entry. |
| `validate` | Determines whether a paired markup configured with `applyOnClear` should run while clearing. |
| `getClearingDuration` | Returns how long a paired clearing effect needs. |
| `getSize` | Returns the layout size of an inline self-closing markup. |
| `onPrint_` | Prints or performs one inline self-closing markup occurrence. |

</details>

<details>
<summary><code>Choosing the correct callback</code></summary>

| Required work | Callback |
| --- | --- |
| Convert a raw ASCII value or attribute | `convert` |
| Validate or cache one programmatic default field | `validateDefaultValue` |
| Prepare defaults using several fields or active stack entries | `onDefaultMarkupsChanged` |
| Prepare the complete state of one parsed tag occurrence | `onConstruction` |
| Apply already-prepared state during printing | `onPrint` or `onPrint_` |

</details>

<details>
<summary><code>onConstruction</code></summary>

`onConstruction` is optional for paired markups, structural self-closing markups, and inline self-closing markups.

It receives a deep-copied markup snapshot with the current tag's converted value and attributes already applied. Mutating it never changes the object's default or surrounding paired-markup state. For inline self-closing markups, however, the same snapshot is stored with the markup occurrence, so mutations affect the state later received by `getSize` and `onPrint_` for that occurrence.

The callback may yield. HyperText waits for it as part of construction, making it useful for preloading resources, fetching data, or preparing cached values before printing starts.

For paired markups, it runs for valid opening tags after their state has been applied, but not for closing tags. For self-closing markups, the snapshot includes that markup instance without permanently changing the surrounding paired-markup state.

</details>

<details>
<summary><code>Paired onPrint behavior</code></summary>

A paired markup's `onPrint` callback runs for every relevant non-whitespace row entry, even when an optional markup currently has no value or a stackable markup has no active entries. Check the markup value or stack before applying the effect.

Several paired markups can run on the same character or image, so their callbacks may affect one another. When their order matters, configure it with `PRINT_PRIORITY` in `Config.luau`. Markups not included in the list run first; listed markups then run from top to bottom. If your markup depends on changes made by another, add both to the list and place yours below its dependency.

</details>

<details>
<summary><code>Structural and inline self-closing markups</code></summary>

A structural self-closing markup leaves `appendToCurrentWord` unset. HyperText constructs any accumulated word before calling `onConstruction`, allowing the callback to create or modify construction structure. Structural markups do not receive `getSize` or `onPrint_`; any corresponding print work must be scheduled during construction. The built-in `br` markup uses this mode.

An inline self-closing markup sets `appendToCurrentWord = true` and passes its type as the fifth `types.dataModule` generic. The markup instance is included in word layout and printed later, so the module must implement `getSize` and `onPrint_`. The built-in `img`, `wait`, and `renderEvent` markups use this mode.

Both modes can use `onConstruction`.

</details>

<details>
<summary><code>Programmatic markups</code></summary>

A programmatic markup represents a setting that is configured through `HyperText.newMarkups()`, `.new(container, markups)`, or `:UpdateDefaultMarkups(markups)`. It cannot be opened through an ASCII tag and does not participate in construction or printing callbacks.

Its data module may use `validateDefaultValue` on the main value, attributes, and value-specific attributes, and may use `onDefaultMarkupsChanged` to react after the complete defaults have been validated or updated. It does not implement `convert`, `onConstruction`, `onPrint`, clearing callbacks, or self-closing layout and printing callbacks.

The setting's actual behavior must be implemented by code that reads it from the relevant markup state. The built-in alignment, size-constraint, scale-dimension, and Z-index settings use programmatic modules.

</details>

### Useful references

- `color` for a minimal paired markup.
- `size` for a simple main-value `validateDefaultValue` callback.
- `GradientAttrsConverters` for attribute-level default validation.
- `anim` for attributes, value-specific attributes, updater work, and image support.
- `clearAnim` for clearing hooks.
- `soundId` for sharing resource-loading logic between `convert` and `validateDefaultValue`.
- `emitImg` for a stackable paired markup using `onDefaultMarkupsChanged` and per-tag `onConstruction` caching.
- `br` for structural self-closing construction.
- `wait` for a zero-size inline self-closing action.
- `img` for a rendered inline self-closing object with `onConstruction`, layout, and printing hooks.
- `horizontalAlignment` for a minimal programmatic markup.
- `scaleDimension` for a programmatic setting consumed by HyperText's sizing logic.
