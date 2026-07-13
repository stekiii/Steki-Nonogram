local GraphicElement = require 'gui.GraphicElement'

local hintConsts = NONOGRAM_HINT_FIELD_CONSTANTS

NonogramFillField = GraphicElement:new{
    matrixPosition = {}
}

function NonogramFillField:new(o)
    o = o or {}

    o.matrixPosition = o.matrixPosition or { 0, 0 }

    setmetatable(o, self)
    self.__index = self

    return o
end

function NonogramFillField:isClicked(position, scale, translationPosition)
    return
end

function NonogramFillField:draw()
    local i, j = self.matrixPosition[1], self.matrixPosition[2]
    local currentScene = Game.currentScene
    local texturePathTable = TEXTURE_PATHS
    local texture

    if i == 1 and j == 1 then
        texture = currentScene:getTexture(texturePathTable.fillField1)
    elseif i == 1 then
        texture = currentScene:getTexture(texturePathTable.fillField2)
    elseif j == 1 then
        texture = currentScene:getTexture(texturePathTable.fillField3)
    else
        texture = currentScene:getTexture(texturePathTable.fillField4)
    end

    texture:setFilter("nearest")
    love.graphics.draw(texture, unpack(self.position))

end

return NonogramFillField