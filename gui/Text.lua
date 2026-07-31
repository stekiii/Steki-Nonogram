local GraphicElement = require 'gui.GraphicElement'

Text = GraphicElement:new{
    position = { 0, 0 },
    text = "",
    font = nil,
    fontColor = { 0, 0, 0 }
}

function Text:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function Text:draw()
    love.graphics.print(
            { self.fontColor, self.text },
            self.font,
            self.position[1] + (self.dimensions[1] - self.font:getWidth(self.text)) / 2,
            self.position[2] + (self.dimensions[2] - self.font:getHeight()) / 2
        )
end

return Text