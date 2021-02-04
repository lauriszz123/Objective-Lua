--[[
	File: main.lua
	Made by: Laurynas.
	Date: 2021/02/04
]]

io.stdout:setvbuf("no")
local main = require "api.olua"

function love.update( dt )
	main:update( dt )
end

function love.draw()
	main:draw()
end