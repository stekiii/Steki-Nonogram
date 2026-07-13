Scene = {
    graphicElements = {},
    textures = {},
}

local newImage = love.graphics.newImage

function Scene:new(o)
    o = o or {}

    o.graphicElements = o.graphicElements or {}
    o.textures = o. textures or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function Scene:loadGraphicElements()

end

--[[
function Scene:handleMousePress(x, y, button, scale, translationPosition)
    scale = scale or 0
    translationPosition = translationPosition or { 0, 0 }
    for _, graphicElement in ipairs(self.graphicElements) do
        if graphicElement:isClicked({ x, y }, scale, translationPosition) then
            graphicElement:handleMousePress(x, y, button)
            return
        end
    end
end

function Scene:handleMouseRelease(x, y, button, scale, translationPosition)
    scale = scale or 0
    translationPosition = translationPosition or { 0, 0 }
    for _, graphicElement in ipairs(self.graphicElements) do
        if graphicElement:isClicked({ x, y }, scale, translationPosition) then
            graphicElement:handleMouseRelease(x, y, button)
            return
        end
    end
end

function Scene:handleMouseMove(x, y, scale, translationPosition)
    scale = scale or 0
    translationPosition = translationPosition or { 0, 0 }
    for _, graphicElement in ipairs(self.graphicElements) do
        if graphicElement:isClicked({ x, y }, scale, translationPosition) then
            graphicElement:handleMouseMove(x, y)
            return
        end
    end
end

function Scene:handleMouseWheel(x, y, scale, translationPosition)
    scale = scale or 0
    translationPosition = translationPosition or { 0, 0 }
    for _, graphicElement in ipairs(self.graphicElements) do
        if graphicElement:isClicked({ x, y }, scale, translationPosition) then
            graphicElement:handleMouseWheel(x, y)
            return
        end
    end
end

function Scene:draw()
    for _, graphicElement in ipairs(self.graphicElements) do
        graphicElement:draw()
    end
end
--]]

---[[
function Scene:handleMousePress(x, y, button, scale, translationPosition)
    
end

function Scene:handleMouseRelease(x, y, button, scale, translationPosition)
    
end

function Scene:handleMouseMove(x, y, scale, translationPosition)
    
end

function Scene:handleMouseWheel(x, y, scale, translationPosition)
    
end

function Scene:handleKeyRelease(key, scancode)
    
end

function Scene:draw()
    
end
--]]

function Scene:getTexture(path)
    local textures = self.textures

    if not textures[path] then
        textures[path] = newImage(path)
        textures[path]:setFilter("nearest")
    end

    return textures[path]
end

function Scene:initialize()
    self:loadGraphicElements()
end

function Scene:update(dt)
    
end

return Scene