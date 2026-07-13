local GraphicElement = require 'gui.GraphicElement'

local hintConsts = NONOGRAM_HINT_FIELD_CONSTANTS

NonogramHintValue = GraphicElement:new{
    hintValue = 0,
    textAlignment = {},
    scale = 1,
    state = 0
}

function NonogramHintValue:new(o)
    o = o or {}

    o.textAlignment = o.textAlignment or { 0, 0 }

    setmetatable(o, self)
    self.__index = self

    return o
end

function NonogramHintValue:isClicked(position, scale, translationPosition)
    return
end

function NonogramHintValue:draw()
    if self.hintValue ~= 0 then
        love.graphics.print(
            { { 0, 0, 0 }, self.hintValue },
            Game.currentScene.nonogramHintFont,
            self.position[1] + self.textAlignment[1] + (self.state == NonogramHintFieldState.Row and hintConsts.NONOGRAM_HINT_FIELD_BORDER or hintConsts.NONOGRAM_HINT_FIELD_OFFSET),
            self.position[2] + self.textAlignment[2] + (self.state == NonogramHintFieldState.Column and hintConsts.NONOGRAM_HINT_FIELD_BORDER or hintConsts.NONOGRAM_HINT_FIELD_OFFSET),
            0,
            self.scale
        )
    end
end

return NonogramHintValue