--!strict

local HyperText = require("./HyperText/Main")

local markups = HyperText.newMarkups()

-- alter an entry by getting it from a stack at a specific index
local entry = markups.emitImg.stack[1]
if entry then
    entry.value = 123
end

-- add to a stack at a specific index
local entry = HyperText.insertStackEntry(markups.emitImg, 1)
entry.value = 1

-- remove from a stack
markups.emitImg.stack[1] = HyperText.DELETE

local renderer = HyperText.new(nil :: any, markups)
renderer:UpdateDefaultMarkups(markups)