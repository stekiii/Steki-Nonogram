Game = {
    currentScene = {},
    gameScale = 1,
    gameResolution = {DEFAULT_WIDTH, DEFAULT_HEIGHT},
    fullscreen = false
}

function Game:new(o)
    o = o or {}

    o.currentScene = o.currentScene or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function Game:initialize()
    
end

function Game:loadScene(scene)
    self.currentScene = scene
    scene:initialize()
end

function Game:returnScene(scene)
    self.currentScene = scene
end

function Game:draw()
    self.currentScene:draw()
end

function Game:adjustedMousePosition(x, y)
    return x / self.gameScale, y / self.gameScale
end

function Game:getMousePosition()
    return Game:adjustedMousePosition(love.mouse.getX(), love.mouse.getY())
end

function Game:resize(width, height, settings)
    love.window.setMode(width, height, settings)

    width, height = love.window.getMode()
    Game.gameScale = Game.gameScale * width / WINDOW_WIDTH
    WINDOW_WIDTH, WINDOW_HEIGHT = width, height
    
    self.fullscreen = love.window.getFullscreen()
end

function Game:setFullscreen(fullscreen)
    love.window.setFullscreen(fullscreen)

    local width, height = love.window.getMode()
    Game.gameScale = Game.gameScale * width / WINDOW_WIDTH
    WINDOW_WIDTH, WINDOW_HEIGHT = width, height

    self.fullscreen = love.window.getFullscreen()
end

function Game:toggleFullscreen()
    Game:setFullscreen(not self.fullscreen)
end


return Game