local Scene = require 'scenes.Scene'

OverlayScene = Scene:new{
    overlaidScene = {}
}

local newImage = love.graphics.newImage

function OverlayScene:new(o)
    o = o or {}

    o.overlaidScene = o.overlaidScene or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function OverlayScene:draw()
    self.overlaidScene:draw()
    self:drawOnTop()
end

function OverlayScene:getTexture(path)
    return self.overlaidScene:getTexture(path)
end

function OverlayScene:drawOnTop()
    
end

function OverlayScene:update(dt)
    self.overlaidScene:update(dt)
end

return OverlayScene