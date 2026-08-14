--!strict
local Players = game:GetService("Players")

local HyperText = require(game.ReplicatedStorage.HyperText.Main)

local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.fromScale(1, 1)

local renderer = HyperText.new(frame)

renderer:Render("<emitimg=1><emitimg=2><emitimg=3>a</emitimg></emitimg></emitimg>")