local GraphicElement = require 'gui.GraphicElement'

NonogramHintFieldState = {
    Row = 0,
    Column = 1
}

NonogramHintField = GraphicElement:new{
    state = 0,
}

function NonogramHintField:new(o)
    o = o or {}

    o.textAlignment = o.textAlignment or { 0, 0 }

    setmetatable(o, self)
    self.__index = self

    return o
end

function NonogramHintField:isClicked(position, scale, translationPosition)
    return
end

function NonogramHintField:draw()
    local currentScene = Game.currentScene
    local texturePathTable = TEXTURE_PATHS
    local texture = self.state == NonogramHintFieldState.Row and
        currentScene:getTexture(texturePathTable.hintFieldRow) or
        currentScene:getTexture(texturePathTable.hintFieldColumn)

    texture:setFilter("nearest")
    love.graphics.draw(texture, unpack(self.position))
end

return NonogramHintField