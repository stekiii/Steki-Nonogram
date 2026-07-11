local GraphicElement = require 'GraphicElement'

Image = GraphicElement:new{
    position = { 0, 0 },
    texture = nil
}

function Image:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function Image:draw()
    local currentScene = Game.currentScene
    local texture = currentScene:getTexture(self.texture)
    texture:setFilter("nearest")

    love.graphics.draw(texture, unpack(self.position))
end

return Image