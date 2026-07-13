GraphicElement = {
    position = {},
    dimensions = {},
}

function GraphicElement:new(o)
    o = o or {}

    o.position = o.position or {}
    o.dimensions = o.dimensions or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function GraphicElement:isClicked(position, scale, translationPosition)
    scale = scale or 1
    translationPosition = translationPosition or { 0, 0 }

    local x, y = self.position[1], self.position[2]
    local a, b = self.dimensions[1], self.dimensions[2]

    x, y =
        scale * x + translationPosition[1],
        scale * y + translationPosition[2]
    a, b =
        scale * a,
        scale * b

    return position[1] >= x and
        position[1] <= x + a and
        position[2] >= y and
        position[2] <= y + b
end

function GraphicElement:handleMousePress(x, y, button)
end

function GraphicElement:handleMouseRelease(x, y, button)
    
end

function GraphicElement:handleMouseMove(x, y)
    
end

function GraphicElement:draw()
    
end


return GraphicElement