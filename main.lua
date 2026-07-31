local Game = require 'Game'
local TitleScene = require 'scenes.TitleScene'

local displayResolution = { 960, 540 } -- { 1920, 1080 }
local fullscreen = FULLSCREEN

function love.load()
    love.window.setMode(0, 0)
    MAX_WINDOW_WIDTH, MAX_WINDOW_HEIGHT = love.window.getMode()

    SCREEN_WIDTH, SCREEN_HEIGHT = unpack(Game.gameResolution)
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, {resizable = false, borderless = false, fullscreen = FULLSCREEN})
    WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getMode()

    Game:resize(displayResolution[1], displayResolution[2], {fullscreen = fullscreen})

    Game:loadScene(TitleScene:new{})
end

function love.keypressed(key)
    if key == 'f11' then
        Game:toggleFullscreen()
    end
end

function love.keyreleased(key, scancode)
    Game.currentScene:handleKeyRelease(key, scancode)
end

function love.mousemoved(x, y, button)
    x, y = Game:adjustedMousePosition(x, y)
    Game.currentScene:handleMouseMove(x, y, button)
end

function love.mousepressed(x, y, button)
    x, y = Game:adjustedMousePosition(x, y)
    Game.currentScene:handleMousePress(x, y, button)
end

function love.mousereleased(x, y, button)
    x, y = Game:adjustedMousePosition(x, y)
    Game.currentScene:handleMouseRelease(x, y, button)
end

function love.wheelmoved(x, y)
    Game.currentScene:handleMouseWheel(x, y)
end

function love.quit()
    Game.currentScene:quit()
end

function love.update(dt)
    Game.currentScene:update(dt)
end

function love.draw()
    love.graphics.scale(Game.gameScale)

    Game:draw()
end
