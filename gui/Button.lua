local GraphicElement = require 'gui.GraphicElement'

Button = GraphicElement:new{
    text = nil,
    font = {},
    fontColor1 = {},
    fontColor2 = {},
    texture1 = nil,
    texture2 = nil,
    pressFunction = function ()

    end,
    hovered = false,
    marked = false,
    border = 0
}

function Button:new(o)
    o = o or {}

    o.text = o.text or nil
    o.font = o.font or {}
    o.fontColor1 = o.fontColor1 or { 0, 0, 0 }
    o.fontColor2 = o.fontColor2 or { 1, 1, 1 }
    o.texture2 = o.texture2 or o.texture1

    local texture = Game.currentScene:getTexture(o.texture1)
    o.dimensions = { texture:getPixelWidth(), texture:getPixelHeight() }

    setmetatable(o, self)
    self.__index = self

    return o
end

function Button:handleMousePress(x, y, button)
    if button == 1 then
        self.marked = true
    end
end

function Button:handleMouseRelease(x, y, button)
    if button == 1 and self.marked then
        self.hovered = false
        self.pressFunction()
    end
end

-- function Button:handleMouseMove(x, y)
--     self.hovered = true
-- end

function Button:draw()
    local currentScene = Game.currentScene
    local texture = self.hovered and
        currentScene:getTexture(self.texture2) or
        currentScene:getTexture(self.texture1)
    texture:setFilter("nearest")
    love.graphics.draw(texture, unpack(self.position))
    
    if self.text then
        local color = self.hovered and self.fontColor2 or self.fontColor1
        love.graphics.print(
                { color, self.text },
                self.font,
                self.position[1] + (texture:getPixelWidth() - self.font:getWidth(self.text) - NONOGRAM_BUTTON_BORDER) / 2,
                self.position[2] + (texture:getPixelHeight() - self.font:getHeight() - NONOGRAM_BUTTON_BORDER) / 2
            )
    end
end

function Button:isClicked(position, scale, translationPosition)
    scale = scale or 1
    translationPosition = translationPosition or { 0, 0 }

    local x, y = self.position[1], self.position[2]
    local a, b = self.dimensions[1], self.dimensions[2]
    local border = self.border

    x, y =
        scale * x + translationPosition[1],
        scale * y + translationPosition[2]
    a, b =
        scale * a,
        scale * b

    return position[1] >= x + border and
        position[1] <= x + a - border and
        position[2] >= y + border and
        position[2] <= y + b - border
end

return Button