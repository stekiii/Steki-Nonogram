local GraphicElement = require 'GraphicElement'

local hintConsts = NONOGRAM_HINT_FIELD_CONSTANTS

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

    -- if self.hintValue ~= 0 then
    --     table.insert(currentScene.hintValueQueue, {
    --         { { 0, 0, 0 }, self.hintValue },
    --         currentScene.nonogramHintFont,
    --         self.position[1] + self.textAlignment[1] + (self.state == NonogramHintFieldState.Row and hintConsts.NONOGRAM_HINT_FIELD_BORDER or hintConsts.NONOGRAM_HINT_FIELD_OFFSET),
    --         self.position[2] + self.textAlignment[2] + (self.state == NonogramHintFieldState.Column and hintConsts.NONOGRAM_HINT_FIELD_BORDER or hintConsts.NONOGRAM_HINT_FIELD_OFFSET),
    --         -- self.dimensions[1] - hintConsts.NONOGRAM_HINT_FIELD_OFFSET + hintConsts.NONOGRAM_HINT_FIELD_X_OFFSET,
    --         -- "center",
    --         0,
    --         self.scale
    --     }
    --     )
    -- end
    -- love.graphics.rectangle("line",
    --     self.position[1] + hintConsts.NONOGRAM_HINT_FIELD_BORDER,
    --     self.position[2] + hintConsts.NONOGRAM_HINT_FIELD_OFFSET,
    --     (self.dimensions[1] - hintConsts.NONOGRAM_HINT_FIELD_OFFSET - hintConsts.NONOGRAM_HINT_FIELD_BORDER),
    --     (self.dimensions[2] - hintConsts.NONOGRAM_HINT_FIELD_OFFSET - hintConsts.NONOGRAM_HINT_FIELD_BORDER))

    -- love.graphics.rectangle("line", self.position[1] + 1, self.position[2] - 1 + hintConsts.NONOGRAM_HINT_FIELD_OFFSET, self.dimensions[1] - hintConsts.NONOGRAM_HINT_FIELD_OFFSET, self.dimensions[2] - hintConsts.NONOGRAM_HINT_FIELD_OFFSET)
end

function NonogramHintField:drawValues()
    
end

return NonogramHintField