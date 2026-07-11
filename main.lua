local Game = require 'Game'
local TitleScene = require 'TitleScene'

local displayResolution = { 960, 540 } -- { 1920, 1080 }
local fullscreen = FULLSCREEN

function love.load()
    love.window.setMode(0, 0)
    MAX_WINDOW_WIDTH, MAX_WINDOW_HEIGHT = love.window.getMode()

    SCREEN_WIDTH, SCREEN_HEIGHT = unpack(Game.gameResolution)
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, {resizable = false, borderless = false, fullscreen = FULLSCREEN})
    WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getMode()

    Game:resize(displayResolution[1], displayResolution[2], {fullscreen = fullscreen})
    
    -- Game:loadScene(NonogramScene:new{ filePath = NONOGRAM_FOLDER_PATH .. "test2.txt"})
    Game:loadScene(TitleScene:new{})
end

---[[
function love.keypressed(key)
    if key == 'f11' then
        Game:toggleFullscreen()
    end
end
--]]

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

function love.update(dt)
    Game.currentScene:update(dt)
end

-- local font = love.graphics.newFont("fonts/Karma Future.otf", 36, "mono")
-- local font = love.graphics.newFont("fonts/ka1.ttf", 60, "mono")
-- font:setFilter("nearest")
-- love.graphics.setFont(font)

function love.draw()
    love.graphics.scale(Game.gameScale)

    Game:draw()
    --local texture = Game.currentScene:getTexture("textures/optionsMenu.png")
    --love.graphics.draw(texture, (SCREEN_WIDTH - texture:getPixelWidth()) / 2, (SCREEN_HEIGHT - texture:getPixelHeight()) / 2)
    
    --[[
    love.graphics.scale(3)
    love.graphics.translate(60, 60)

    love.graphics.setBackgroundColor(1,0.8,0.8)

    love.graphics.setColor(1,1,1)
    love.graphics.draw(image1, 50, 50)
    love.graphics.draw(image2, 50+59, 50)
    love.graphics.draw(image3, 50, 50+59)
    love.graphics.draw(image4, 50+59, 50+59)

    local imgToDraw

    for i = 0, 4, 1 do
        for j = 0, 4, 1 do
            if i == 0 and j == 0 then
                imgToDraw = image1
            elseif i == 0 then
                imgToDraw = image2
            elseif j == 0 then
                imgToDraw = image3
            else
                imgToDraw = image4
            end
            love.graphics.draw(imgToDraw, j * 59, i * 59)
        end
    end

    love.graphics.setColor(0.75, 0.75, 0.75, 0.6)
    -- love.graphics.rectangle("fill", 50, 120, 360, 250)

    --]]
end
