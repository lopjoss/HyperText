--!strict

local HyperText = require(game.ReplicatedStorage.HyperText.Main)

local markups = HyperText.newMarkups()

local entry = HyperText.insertStackEntry(markups.emitImg, 1)
entry.value = 1

local entry = HyperText.insertStackEntry(markups.emitImg, 2)
entry.value = 2

local renderer = HyperText.new(Instance.new("Frame"), markups)

markups.emitImg.stack[2] = HyperText.DELETE
local entry = markups.emitImg.stack[1]
if entry then
	entry.value = 3
end

local entry = HyperText.insertStackEntry(markups.emitImg, 4)
entry.value = 4

renderer:UpdateDefaultMarkups(markups)

print(renderer._markups)