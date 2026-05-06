local Scene = require 'Scene'
local Nonogram = require 'Nonogram'
local NonogramField = require 'NonogramField'
local NonogramHintField = require 'NonogramHintField'
local NonogramFillField = require 'NonogramFillField'
local NonogramHintValue = require 'NonogramHintValue'
local Button = require 'Button'

local scrollSpeedIncrease = 10
local scrollSpeedDeceleration = 11
local maxScrollSpeed = 30
local minScrollSpeed = 0.1
local hintConsts = NONOGRAM_HINT_FIELD_CONSTANTS

NonogramScene = Scene:new{
    nonogram = {},
    filePath = "",
    scale = 1,
    translationPosition = {},
    initialPosition = {},
    scrollSpeed = 0,
    mousePositionAtScroll = {},
    actions = {},
    nonogramFields = {},
    nonogramHintFields = {},
    nonogramFillFields = {},
    hintValues = {},
    minScale = 0,
    maxScale = 0,
    buttons = {}
}

function NonogramScene:new(o)
    o = o or {}

    o.nonogram = o.nonogram or {}
    o.translationPosition = o.translationPosition or { 0, 0 }
    o.initialPosition = o.initialPosition or { 0, 0 }
    o.mousePositionAtScroll = o.mousePositionAtScroll or { 0, 0 }
    o.actions = o.actions or {
        moving = false,
        positionOfPressedField = { 0, 0 },
        marking = false,
        crossing = false,
        unmarking = false, -- not needed?
        uncrossing = false, -- not needed?
        emptying = false,
        state = nil
    }

    o.nonogramFields = o.nonogramFields or {}
    o.nonogramHintFields = o.nonogramHintFields or {}
    o.nonogramFillFields = o.nonogramFillFields or {}
    o.hintValues = o.hintValues or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

-- function NonogramScene:transformedMouseInput(x, y)
--     return x + self.translationPosition[1], y + self.translationPosition[2]
-- end

function NonogramScene:loadGraphicElements()
---[[
    self.nonogramFields = {}
    self.nonogramHintFields = {}
    self.nonogramFillFields = {}
    self.hintValues = {}
--]]
    
    local rows, columns = unpack(self.nonogram.dimensions)
    local mostHintsInRow, mostHintsInColumn = self.nonogram:mostHintsInLine("row"), self.nonogram:mostHintsInLine("column")

    local exFieldTexture, exHintTexture = self:getTexture(TEXTURE_PATHS.field1), self:getTexture(TEXTURE_PATHS.hintFieldRow)
    local fieldMatrixWidth, fieldMatrixHeight, rowHintFieldsWidth, columnHintFieldsHeight =
        (columns * exFieldTexture:getPixelWidth() - (columns - 1) * NONOGRAM_FIELD_OFFSET),
        (rows * exFieldTexture:getPixelHeight() - (rows - 1) * NONOGRAM_FIELD_OFFSET),
        (mostHintsInRow * exHintTexture:getPixelWidth() - NONOGRAM_HINT_FIELD_CONSTANTS.NONOGRAM_FIELD_AND_HINT_ALIGNMENT - (mostHintsInRow - 1) * NONOGRAM_HINT_FIELD_CONSTANTS.NONOGRAM_HINT_FIELD_OFFSET),
        (mostHintsInColumn * exHintTexture:getPixelHeight() - NONOGRAM_HINT_FIELD_CONSTANTS.NONOGRAM_FIELD_AND_HINT_ALIGNMENT - (mostHintsInColumn - 1) * NONOGRAM_HINT_FIELD_CONSTANTS.NONOGRAM_HINT_FIELD_OFFSET)

    local startX, startY =
        (SCREEN_WIDTH - fieldMatrixWidth + rowHintFieldsWidth) / 2,
        (SCREEN_HEIGHT - fieldMatrixHeight + columnHintFieldsHeight) / 2

    local fullTableDimensions = { fieldMatrixWidth + rowHintFieldsWidth, fieldMatrixHeight + columnHintFieldsHeight }

    local scaleOffsetPercent = 1.1
    local xScaling, yScaling = SCREEN_WIDTH / (fullTableDimensions[1] * scaleOffsetPercent), SCREEN_HEIGHT / (fullTableDimensions[2] * scaleOffsetPercent)
    self.scale = xScaling < yScaling and xScaling or yScaling
    self.translationPosition[1], self.translationPosition[2] =
        SCREEN_WIDTH / 2 * (1 - self.scale),
        SCREEN_HEIGHT / 2 * (1 - self.scale)

    self.maxScale = SCREEN_HEIGHT / exFieldTexture:getPixelHeight()
    self.minScale = self.scale / 2

    --[[
    local oldScale = self.scale
    self.scale = xScaling < yScaling and xScaling or yScaling

    local tx, ty = unpack(self.translationPosition)
    local x, y = SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2
    local scalingFactor = self.scale / oldScale
    self.translationPosition[1], self.translationPosition[2] =
        tx + (x - tx) * (1 - scalingFactor),
        ty + (y - ty) * (1 - scalingFactor)
    --]]

    local exTexture = self:getTexture(TEXTURE_PATHS.hintFieldRow)
    local textureWidth, textureHeight = exTexture:getPixelWidth(), exTexture:getPixelHeight()
    local width, height = textureWidth, textureHeight

    self.nonogramHintFont = love.graphics.newFont(NONOGRAM_HINT_FIELD_CONSTANTS.NONOGRAM_HINT_FIELD_FONT, NONOGRAM_HINT_FIELD_CONSTANTS.NONOGRAM_HINT_FONT_SIZE, "mono")
    self.nonogramHintFont:setFilter("nearest")
    local fontHeight = self.nonogramHintFont:getHeight()

    width, height =
        width - hintConsts.NONOGRAM_HINT_FIELD_OFFSET - hintConsts.NONOGRAM_HINT_FIELD_BORDER,
        height - hintConsts.NONOGRAM_HINT_FIELD_OFFSET - hintConsts.NONOGRAM_HINT_FIELD_BORDER

    local hintsInLine, hintValue, scale, fontWidth, hintField

    for i = 1, rows, 1 do
        hintsInLine = #self.nonogram.rowHints[i]
        for j = 1, mostHintsInRow, 1 do
            hintValue = self.nonogram.rowHints[i][hintsInLine - j + 1]

            fontWidth = hintValue and self.nonogramHintFont:getWidth(hintValue) or 1
            scale = width / fontWidth
            scale = scale > 1 and 1 or scale

            hintField = NonogramHintField:new{
                state = NonogramHintFieldState.Row,
                dimensions = { width, height },
                position = {
                    startX + hintConsts.NONOGRAM_FIELD_AND_HINT_ALIGNMENT - textureWidth - (textureWidth - hintConsts.NONOGRAM_HINT_FIELD_OFFSET) * (j - 1),
                    startY - hintConsts.NONOGRAM_HINT_ALIGNMENT + (textureHeight - hintConsts.NONOGRAM_HINT_FIELD_OFFSET) * (i - 1)
                }
            }

            table.insert(self.nonogramHintFields, hintField)

            if hintValue ~= 0 then
                table.insert(
                    self.hintValues,
                    NonogramHintValue:new{
                        hintValue = hintValue,
                        position = { unpack(hintField.position) },
                        scale = scale,
                        textAlignment = {
                            (width - fontWidth * scale) / 2,
                            (height - fontHeight * scale) / 2
                        },
                        state = hintField.state
                    }
                )
            end
        end
    end

    for i = 1, columns, 1 do
        hintsInLine = #self.nonogram.columnHints[i]
        for j = 1, mostHintsInColumn, 1 do
            hintValue = self.nonogram.columnHints[i][hintsInLine - j + 1]

            fontWidth = hintValue and self.nonogramHintFont:getWidth(hintValue) or 1
            scale = width / fontWidth
            scale = scale > 1 and 1 or scale

            hintField = NonogramHintField:new{
                    state = NonogramHintFieldState.Column,
                    dimensions = { width, height },
                    position = {
                        startX - hintConsts.NONOGRAM_HINT_ALIGNMENT + (textureHeight - hintConsts.NONOGRAM_HINT_FIELD_OFFSET) * (i - 1),
                        startY + hintConsts.NONOGRAM_FIELD_AND_HINT_ALIGNMENT - textureWidth - (textureWidth - hintConsts.NONOGRAM_HINT_FIELD_OFFSET) * (j - 1)
                    }
            }

            table.insert(self.nonogramHintFields, hintField)

            if hintValue ~= 0 then
                table.insert(self.hintValues,
                    NonogramHintValue:new{
                        hintValue = hintValue,
                        position = { unpack(hintField.position) },
                        scale = scale,
                        textAlignment = {
                            (width - fontWidth * scale) / 2,
                            (height - fontHeight * scale) / 2
                        },
                        state = hintField.state
                    }
                )
            end
        end
    end

    exTexture = self:getTexture(TEXTURE_PATHS.fillField1)
    width, height = exTexture:getPixelWidth(), exTexture:getPixelHeight()

    for i = 1, mostHintsInColumn, 1 do
        for j = 1, mostHintsInRow, 1 do
            table.insert(self.nonogramFillFields, NonogramFillField:new{
                matrixPosition = { i, j },
                dimensions = { width, height },
                position = {
                    startX - width + NONOGRAM_FILL_ALIGNMENT - (width - NONOGRAM_FILL_FIELD_OFFSET) * (mostHintsInRow - j) ,
                    startY - height + NONOGRAM_FILL_ALIGNMENT - (height - NONOGRAM_FILL_FIELD_OFFSET) * (mostHintsInColumn - i)
                }
            })
        end
    end

    exTexture = self:getTexture(TEXTURE_PATHS.field1)
    width, height = exTexture:getPixelWidth(), exTexture:getPixelHeight()

    for i = 1, rows, 1 do
        for j = 1, columns, 1 do
            table.insert(
                self.nonogramFields,
                NonogramField:new{
                    -- state = NonogramFieldState.Empty
                    state = self.nonogram.matrixState[ (i - 1) * columns + j ],
                    matrixPosition = { i, j },
                    dimensions = { width, height },
                    position = {
                        startX + (j - 1) * (width - NONOGRAM_FIELD_OFFSET),
                        startY + (i - 1) * (height - NONOGRAM_FIELD_OFFSET)
                    }
            })
        end
    end

    self.buttons.backButton = Button:new{
        position = { 587, 10 },
        texture1 = TEXTURE_PATHS.backButton,
        pressFunction = function ()
            if self.filePath == "" then
                Game:loadScene(TitleScene:new{})
                return
            end

            local i = string.find(self.filePath, "/[%w.]*$") - 1
            local str = i and string.sub(self.filePath, 1, i) or ""
            Game:loadScene(SelectMenu:new{ currentFolder = str })
        end
    }

    love.graphics.setBackgroundColor(1,0.8,0.8)
end

function NonogramScene:handleMousePress(x, y, button)
    if button == 1 then
        for _, b in pairs(self.buttons) do
            if b:isClicked({ x, y }) then
                b:handleMousePress(x, y, button)
                return
            end
        end
    end

    if button == 3 or love.keyboard.isDown('lctrl') and button == 1 then
        self.initialPosition[1], self.initialPosition[2] = x, y
        self.actions.moving = true

        return
    end

    -- Scene.handleMousePress(self, x, y, button, self.scale, self.translationPosition)
    for _, field in ipairs(self.nonogramFields) do
        if field:isClicked({ x, y }, self.scale, self.translationPosition) then
            field:handleMousePress(x, y, button)
            return
        end
    end
end

function NonogramScene:handleMouseRelease(x, y, button)
    if button == 1 then
        for _, b in pairs(self.buttons) do
            if b:isClicked({ x, y }) then
                b:handleMouseRelease(x, y, button)
            end
            b.marked = false
        end
    end

    local actions = self.actions

    if button == 1 then
        actions.marking, actions.emptying = false, false
    end
    if button == 2 then
        actions.crossing, actions.emptying = false, false
    end
    if button == 3 or actions.moving and button == 1 then
        actions.moving = false
    end
end

function NonogramScene:handleMouseMove(x, y)
    for _, button in pairs(self.buttons) do
        button.hovered = button:isClicked({ x, y })
    end

    local actions = self.actions

    if actions.moving then
        local tp, ip = self.translationPosition, self.initialPosition
        tp[1], tp[2] =
            tp[1] + (x - ip[1]),
            tp[2] + (y - ip[2])
        ip[1], ip[2] = x, y

        return
    end

    if actions.emptying or actions.marking or actions.crossing then
        -- Scene.handleMouseMove(self, x, y, self.scale, self.translationPosition)
        for _, field in ipairs(self.nonogramFields) do
            if field:isClicked({ x, y }, self.scale, self.translationPosition) then
                field:handleMouseMove(x, y)
                return
            end
        end
    end
end

function NonogramScene:handleKeyRelease(key, scancode)
    local actions = Game.currentScene.actions
    if actions.moving and key == 'lctrl' and not love.mouse.isDown(3) then
        actions.moving = false
    end
end

function NonogramScene:changeField(position, state)
    self.nonogram:changeField(position, state)
    local acitons = self.actions

    if acitons.emptying or acitons.marking or acitons.crossing then
        return
    end

    -- acitons.positionOfPressedField[1], acitons.positionOfPressedField[2] =
    --     position[1], position[2]
    acitons.state = state

    if state == NonogramFieldState.Empty then
        acitons.emptying = true
    elseif state == NonogramFieldState.Marked then
        acitons.marking = true
    else
        acitons.crossing = true
    end


end

function NonogramScene:handleMouseWheel(x, y)
    --[[
    -- local sgn = y / math.abs(y)
    -- local scrollSpeed = self.scrollSpeed

    -- if scrollSpeed <= 0 and sgn > 0 or scrollSpeed >= 0 and sgn < 0 then
    --     scrollSpeed = 0
    -- end

    -- scrollSpeed = scrollSpeed + sgn * scrollSpeedIncrease
    
    -- self.scrollSpeed = sgn < 0 and 
    --     math.max(-maxScrollSpeed, scrollSpeed) or
    --     math.min(maxScrollSpeed, scrollSpeed)

    -- self.mousePositionAtScroll[1], self.mousePositionAtScroll[2] =
    --     self.latestMousePosition[1], self.latestMousePosition[2]
    --]]

    local scrollSpeed = self.scrollSpeed

    if scrollSpeed <= 0 and y > 0 or scrollSpeed >= 0 and y < 0 then
        scrollSpeed = 0
    end

    scrollSpeed = scrollSpeed + y * scrollSpeedIncrease
    
    self.scrollSpeed = y < 0 and
        math.max(-maxScrollSpeed, scrollSpeed) or
        math.min(maxScrollSpeed, scrollSpeed)

    self.mousePositionAtScroll[1], self.mousePositionAtScroll[2] =
        Game:getMousePosition()
end

---[[
function NonogramScene:update(dt)
    if self.scrollSpeed ~= 0 then
        local scrollSpeed = self.scrollSpeed
        local oldScale = self.scale

        scrollSpeed = scrollSpeed * (1 - scrollSpeedDeceleration * dt)
        
        self.scale = oldScale * (1 + NONOGRAM_SCALE_INCREMENT * dt * (scrollSpeed + self.scrollSpeed) / 2)
        self.scale = (self.scale < self.minScale) and self.minScale or (self.scale > self.maxScale and self.maxScale or self.scale)
        
        self.scrollSpeed = math.abs(scrollSpeed) > minScrollSpeed and scrollSpeed or 0

        local scalingFactor = self.scale / oldScale
        if scalingFactor ~= 1 then
            local tx, ty = unpack(self.translationPosition)
            local x, y = unpack(self.mousePositionAtScroll)

            self.translationPosition[1], self.translationPosition[2] =
                tx + (x - tx) * (1 - scalingFactor),
                ty + (y - ty) * (1 - scalingFactor)
        end
    end

    local x, y = Game:getMousePosition()
    local hoveredField = nil
    for _, field in ipairs(self.nonogramFields) do
        field.highlight = false
        if hoveredField == nil and GraphicElement.isClicked(field, { x, y }, self.scale, self.translationPosition) then
            hoveredField = field.matrixPosition
        end
    end

    if hoveredField then
        for _, field in ipairs(self.nonogramFields) do
            if field.matrixPosition[1] == hoveredField[1] or field.matrixPosition[2] == hoveredField[2] then
                field.highlight = true
            end
        end
    end

    -- if self.scrollSpeed ~= 0 then
    --     local scrollSpeed = self.scrollSpeed
    --     local oldScale = self.scale

    --     scrollSpeed = scrollSpeed * (1 - scrollSpeedDeceleration * dt)
    --     scrollSpeed = math.abs(scrollSpeed) > minScrollSpeed and scrollSpeed or 0

    --     self.scale = oldScale + (self.scrollSpeed + scrollSpeed) * dt / 2
    --     self.scale = (self.scale < self.minScale) and self.minScale or (self.scale > self.maxScale and self.maxScale or self.scale)
        
    --     self.scrollSpeed = scrollSpeed

    --     local scalingFactor = self.scale / oldScale
    --     if scalingFactor ~= 1 then
    --         local tx, ty = unpack(self.translationPosition)
    --         local x, y = unpack(self.mousePositionAtScroll)

    --         self.translationPosition[1], self.translationPosition[2] =
    --             tx + (x - tx) * (1 - scalingFactor),
    --             ty + (y - ty) * (1 - scalingFactor)
    --     end
    -- end
end
--]]

--[[
function NonogramScene:update(dt)
    if self.scrollSpeed ~= 0 then
        local scrollSpeed = self.scrollSpeed
        local oldScale = self.scale
        
        self.scale = oldScale + NONOGRAM_SCALE_INCREMENT * dt * scrollSpeed * oldScale
        self.scale = (self.scale < self.minScale) and self.minScale or (self.scale > self.maxScale and self.maxScale or self.scale)

        local scalingFactor = self.scale / oldScale
        if scalingFactor ~= 1 then
            local tx, ty = unpack(self.translationPosition)
            local x, y = unpack(self.mousePositionAtScroll)

            self.translationPosition[1], self.translationPosition[2] =
                tx + (x - tx) * (1 - scalingFactor),
                ty + (y - ty) * (1 - scalingFactor)

            scrollSpeed = scrollSpeed * (1 - scrollSpeedDeceleration * dt)
            self.scrollSpeed = math.abs(scrollSpeed) > minScrollSpeed and scrollSpeed or 0
        else
            self.scrollSpeed = 0
        end
    end

    -- local sgn = scrollSpeed == 0 and 0 or scrollSpeed / math.abs(scrollSpeed)
    -- local sgn = scrollSpeed / math.abs(scrollSpeed)

    -- scrollSpeedDeceleration = 110
    -- local newSpeed = self.scrollSpeed - sgn * scrollSpeedDeceleration * dt
    -- self.scrollSpeed =
    --     (newSpeed <= 0 and scrollSpeed < 0 or newSpeed >= 0 and scrollSpeed > 0) and
    --         newSpeed or 0
    
end
--]]

function NonogramScene:loadNonogramFromFile()
    local lineIter = io.lines(self.filePath)
    
    local dimensions, rowHints, columnHints, matrixState, solution = {}, {}, {}, {}, {}

    local line = lineIter()
    
    local pattern = "(%d+)[,\n]?"
    local iterFunc = string.gmatch(line, pattern)
    dimensions[1], dimensions[2] = tonumber(iterFunc()), tonumber(iterFunc())
    
    -- for i = 1, dimensions[1], 1 do
    --     local rowHint = {}
    --     line = lineIter()

    --     for number in string.gmatch(line, pattern) do
    --         table.insert(rowHint, tonumber(number))
    --     end

    --     table.insert(rowHints, rowHint)
    -- end

    -- for i = 1, dimensions[2], 1 do
    --     local columnHint = {}
    --     line = lineIter()

    --     for number in string.gmatch(line, pattern) do
    --         table.insert(columnHint, tonumber(number))
    --     end

    --     table.insert(columnHints, columnHint)
    -- end

    line = lineIter()
    if not line or #line ~= dimensions[1] * dimensions[2] then
        error()
    end

    for i = 1, #line, 1 do
        table.insert(solution, tonumber(string.sub(line, i, i)))
        table.insert(matrixState, 0)
    end

    local hintIndex
    local fieldValue
    local lineStarted
    for i = 1, dimensions[1], 1 do
        lineStarted = false
        hintIndex = 1
        table.insert(rowHints, {})

        for j = 1, dimensions[2], 1 do
            fieldValue = solution[(i - 1) * dimensions[2] + j]
            
            if fieldValue == NonogramFieldState.Marked then
                rowHints[i][hintIndex] =  lineStarted and rowHints[i][hintIndex] + 1 or 1
                lineStarted = true
            elseif lineStarted then
                hintIndex = hintIndex + 1
                lineStarted = false
            end
        end
    end

    for j = 1, dimensions[2], 1 do
        lineStarted = false
        hintIndex = 1
        table.insert(columnHints, {})

        for i = 1, dimensions[1], 1 do
            fieldValue = solution[(i - 1) * dimensions[2] + j]
            
            if fieldValue == NonogramFieldState.Marked then
                columnHints[j][hintIndex] =  lineStarted and columnHints[j][hintIndex] + 1 or 1
                lineStarted = true
            elseif lineStarted then
                hintIndex = hintIndex + 1
                lineStarted = false
            end
        end
    end

    if lineIter() then --closes file
        error()
    end

    local nonogram = Nonogram:new{
        dimensions = dimensions,
        rowHints = rowHints,
        columnHints = columnHints,
        matrixState = matrixState,
        solution = solution
    }

    self.nonogram = nonogram
end

function NonogramScene:initialize()
    self:loadNonogramFromFile()
    
    Scene.initialize(self)
end

function NonogramScene:draw()
    local scale = self.scale
    local x, y = unpack(self.translationPosition)

    love.graphics.push()

    love.graphics.translate(x, y)
    love.graphics.scale(scale)

    for _, hintField in ipairs(self.nonogramHintFields) do
        hintField:draw()
    end

    for _, fillField in ipairs(self.nonogramFillFields) do
        fillField:draw()
    end

    for _, value in ipairs(self.hintValues) do
        value:draw()
    end
    
    for _, field in ipairs(self.nonogramFields) do
        field:draw()
    end

    love.graphics.pop()

    for _, button in pairs(self.buttons) do
        button:draw()
    end
end

return NonogramScene