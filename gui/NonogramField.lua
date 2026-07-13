local GraphicElement = require 'gui.GraphicElement'

NonogramFieldState = {
    Empty = 0,
    Marked = 1,
    Crossed = 2
}

NonogramField = GraphicElement:new{
    matrixPosition = {},
    state = {},
    highlight = false
}

function NonogramField:new(o)
    o = o or {}

    o.matrixPosition = o.matrixPosition or {}
    o.state = o.state or NonogramFieldState.Empty

    setmetatable(o, self)
    self.__index = self

    return o
end

function NonogramField:isClicked(position, scale, translationPosition)
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

    local offset = NONOGRAM_FIELD_OFFSET * scale
    local borderWidth = NONOGRAM_FIELD_BORDER * scale

    return position[1] >= x + offset + borderWidth and
        position[1] <= x + a - offset - borderWidth and
        position[2] >= y + offset + borderWidth and
        position[2] <= y + b - offset - borderWidth
end

function NonogramField:changeState(state)
    Game.currentScene:changeField(self.matrixPosition, state)
    self.state = state
end

function NonogramField:handleMousePress(x, y, button)
    if Game.currentScene.solved then
        return
    end

    local actions = Game.currentScene.actions
    local anyAction = actions.crossing or actions.emptying or actions.marking

    if button == 1 and not anyAction then
        if self.state == NonogramFieldState.Marked then
            self:changeState(NonogramFieldState.Empty)
        else
            self:changeState(NonogramFieldState.Marked)
        end
    elseif button == 2 and not anyAction then
        if self.state == NonogramFieldState.Crossed then
            self:changeState(NonogramFieldState.Empty)
        else
            self:changeState(NonogramFieldState.Crossed)
        end
    end
end

function NonogramField:handleMouseMove(x, y)
    if Game.currentScene.solved then
        return
    end

    local scene = Game.currentScene
    local actions = scene.actions

    -- if self.matrixPosition[1] == actions.positionOfPressedField[1] or self.matrixPosition[2] == actions.positionOfPressedField[2] then
    --     self:changeState(scene.nonogram:getState(actions.positionOfPressedField))
    -- end
    -- local newState = scene.nonogram:getState(actions.positionOfPressedField)
    -- local newState =
    --     actions.marking and NonogramFieldState.Marked or
    --     (actions.crossing and NonogramFieldState.Crossed or NonogramFieldState.Empty)
    
    if actions.state ~= self.state then
        -- self:changeState(scene.nonogram:getState(actions.positionOfPressedField))
        self:changeState(actions.state)
    end
end

-- function NonogramField:onHighlight()
    
-- end

function NonogramField:draw()
    local i, j = self.matrixPosition[1], self.matrixPosition[2]
    local currentScene = Game.currentScene
    local texturePathTable = TEXTURE_PATHS
    local texture

    if i == 1 and j == 1 then
        texture = self.highlight and currentScene:getTexture(texturePathTable.hoverfield1) or currentScene:getTexture(texturePathTable.field1)
    elseif i == 1 then
        texture = self.highlight and currentScene:getTexture(texturePathTable.hoverfield2) or currentScene:getTexture(texturePathTable.field2)
    elseif j == 1 then
        texture = self.highlight and currentScene:getTexture(texturePathTable.hoverfield3) or currentScene:getTexture(texturePathTable.field3)
    else
        texture = self.highlight and currentScene:getTexture(texturePathTable.hoverfield4) or currentScene:getTexture(texturePathTable.field4)
    end

    -- local x, y = (texture:getPixelWidth() - NONOGRAM_FIELD_OFFSET) * (j - 1),
    --     (texture:getPixelHeight() - NONOGRAM_FIELD_OFFSET) * (i - 1)

    texture:setFilter("nearest")
    love.graphics.draw(texture, unpack(self.position))

    if self.state ~= NonogramFieldState.Empty then
        texture = self.state == NonogramFieldState.Marked and
            currentScene:getTexture(texturePathTable.mark) or
            currentScene:getTexture(texturePathTable.cross)

        texture:setFilter("nearest")
        love.graphics.draw(texture, unpack(self.position))
    end
end


return NonogramField