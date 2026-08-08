local Scene = require 'scenes.Scene'
local Nonogram = require 'Nonogram'
local NonogramField = require 'gui.NonogramField'
local NonogramHintField = require 'gui.NonogramHintField'
local NonogramFillField = require 'gui.NonogramFillField'
local NonogramHintValue = require 'gui.NonogramHintValue'
local Button = require 'gui.Button'
local Image = require 'gui.Image'
local Text = require 'gui.Text'
local Animation = require 'gui.Animation'
local Timer = require 'Timer'
local Solver = require 'solvers.Solver'

local scrollSpeedIncrease = 10
local scrollSpeedDeceleration = 11
local maxScrollSpeed = 30
local minScrollSpeed = 0.1
local hintConsts = NONOGRAM_HINT_FIELD_CONSTANTS
local timerBasePeriod = 2/11

local finalSolvedFieldPosition = {}

local texturePaths = TEXTURE_PATHS
local backgroundImage, quad

local xOffset, yOffset = 0, 0
local scrollSpeedX = -25
local scrollSpeedY = - (scrollSpeedX * 9 / 16) / 2
local width, height = love.graphics.getDimensions()
local imageWidth, imageHeight

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
    buttons = {},

    solved = false
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
        emptying = false,
        state = nil
    }

    o.nonogramFields = o.nonogramFields or {}
    o.nonogramHintFields = o.nonogramHintFields or {}
    o.nonogramFillFields = o.nonogramFillFields or {}
    o.hintValues = o.hintValues or {}
    o.buttons = o.buttons or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function NonogramScene:loadGraphicElements()
    self.nonogramFields = {}
    self.nonogramHintFields = {}
    self.nonogramFillFields = {}
    self.hintValues = {}

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

    local exTexture = self:getTexture(TEXTURE_PATHS.hintFieldRow)
    local textureWidth, textureHeight = exTexture:getPixelWidth(), exTexture:getPixelHeight()
    local width, height = textureWidth, textureHeight

    self.nonogramHintFont = love.graphics.newFont(NONOGRAM_HINT_FIELD_CONSTANTS.NONOGRAM_HINT_FIELD_FONT, NONOGRAM_HINT_FIELD_CONSTANTS.NONOGRAM_HINT_FONT_SIZE, "mono")
    self.nonogramHintFont:setFilter("nearest", "nearest")
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
            self.solver:quit()

            if self.filePath == "" then
                Game:loadScene(TitleScene:new{})
                return
            end

            local i = string.find(self.filePath, "/[%w_.%-%(%) ]*$") - 1
            local str = i and string.sub(self.filePath, 1, i) or ""
            Game:loadScene(SelectMenu:new{ currentFolder = str })
        end
    }

    self.solvedImageAnimation = Animation:new{
        graphicElement = Image:new{
            position = { 269, 360 },
            texture = TEXTURE_PATHS.solved
        },

        animationTime = 1.2,
        goalPosition = { 269, 281 },
        movementFunctionY = function (x, c1, c3)
            -- return x < 0.5 and (4 * x * x * x) or (1 - math.pow(-2 * x + 2, 3) / 2) -- ease in out cubic
            -- return 1 - math.pow(1 - x, 3) -- ease out cubic

            -- ease out back
            -- local c1 = 1.70158;
            -- local c3 = c1 + 1;

            return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2);
        end,
        movementFunctionParametersY = {
            1.70158,
            2.70158
        }
    }

    local numOfTimerRepetitions = self.nonogram.dimensions[1] + self.nonogram.dimensions[2] - 1

    self.clearNonogramTimer = Timer:new{
        goalTime = timerBasePeriod,
        repetitions = numOfTimerRepetitions
    }

    backgroundImage = love.graphics.newImage(texturePaths.nonogramSceneBackgroundSmall)
    backgroundImage:setFilter("nearest", "nearest")
    backgroundImage:setWrap("repeat", "repeat")
    imageWidth, imageHeight = backgroundImage:getDimensions()

    quad = love.graphics.newQuad(0, 0, width, height, backgroundImage:getDimensions())

    self.solver = Solver:new()

    self.solverMenuFont = love.graphics.newFont(NONOGRAM_SELECT_MENU_FONT, 12, "mono")
    self.solverMenuFont:setFilter("nearest", "nearest")

    self.solverMenu = Image:new({
        texture = texturePaths.solverMenu,
        position = { 20, 20 }
    })

    self.solverName = Text:new({
        text = self.solver:getCurrentSolver().name,
        position = { self.solverMenu.position[1], 17 },
        dimensions = { self:getTexture(self.solverMenu.texture):getWidth(), 36 },
        font = self.solverMenuFont
    })

    self.previousSolverButton = Button:new({
        position = { 36, 49 },
        pressFunction = function ()
            self.solver:previousSolver()
            self.solverName.text = self.solver:getCurrentSolver().name
        end,
        texture1 = texturePaths.previousButtonSmall
    })

    self.nextSolverButton = Button:new({
        position = { 112, 49 },
        pressFunction = function ()
            self.solver:nextSolver()
            self.solverName.text = self.solver:getCurrentSolver().name
        end,
        texture1 = texturePaths.nextButtonSmall
    })

    self.startSolverButton = Button:new({
        position = { 74, 48 },
        pressFunction = function ()
            if not self.solver:isRunning() and not self.simulation.simulating then
                self:clearBoard()
                self.solvedImageAnimation:reset()
                self.iterationValueText.text = ""
                self.solver:start(self.nonogram, tostring(self))
                self.solved = false
            end
        end,
        texture1 = texturePaths.startButtonSmall,
        isDisabled = function ()
            return self.solver:isRunning() or self.simulation.simulating
        end
    })

    self.iterationText = Text:new({
        text = "Current\niteration:",
        position = { 25, 79 },
        dimensions = { self:getTexture(self.solverMenu.texture):getWidth() / 2, 0 },
        font = self.solverMenuFont
    })

    self.iterationValueText = Text:new({
        text = "",
        position = { 84, 79 },
        dimensions = { self:getTexture(self.solverMenu.texture):getWidth() / 2, 12 },
        font = self.solverMenuFont
    })

    self.currentSpeedText = Text:new({
        text = "1x",
        position = { 20, 113 },
        dimensions = { self:getTexture(self.solverMenu.texture):getWidth(), 0 },
        font = self.solverMenuFont
    })

    self.decreaseSpeedButton = Button:new({
        position = { 40, 105 },
        texture1 = texturePaths.minusButtonMini,
        pressFunction = function ()
            if self.simulation.timeModifier <= self.simulation.minTimeModifier then
                return
            end

            self.simulation.timeModifier = self.simulation.timeModifier / 2
            self.currentSpeedText.text = self.simulation.timeModifier .. "x"
            self.simulation.timerBetweenSteps:changeGoalTime(self.simulation.timerBetweenSteps.goalTime * 2)
            self.simulation.timerBetweenChanges:changeGoalTime(self.simulation.timerBetweenChanges.goalTime * 2)
        end
    })

    self.increaseSpeedButton = Button:new({
        position = { 107, 105 },
        texture1 = texturePaths.plusButtonMini,
        pressFunction = function ()
            if self.simulation.timeModifier >= self.simulation.maxTimeModifier then
                return
            end

            self.simulation.timeModifier = self.simulation.timeModifier * 2
            self.currentSpeedText.text = self.simulation.timeModifier .. "x"
            self.simulation.timerBetweenSteps:changeGoalTime(self.simulation.timerBetweenSteps.goalTime / 2)
            self.simulation.timerBetweenChanges:changeGoalTime(self.simulation.timerBetweenChanges.goalTime / 2)
        end
    })

    self.resetSimulationButton = Button:new({
        position = { 55, 131 },
        texture1 = texturePaths.resetButton,
        pressFunction = function ()
            self.simulation.initializeSimulation()
            self:clearBoard()
        end,
        isDisabled = function ()
            return not self.solver:isSolved()
        end
    })

    self.pauseSimulationButton = Button:new({
        position = { 90, 131 },
        texture1 = texturePaths.pauseButton,
        pressFunction = function ()
            self.simulation.paused = true
        end,
        isDisabled = function ()
            return not self.solver:isSolved() or self.simulation.paused
        end
    })

    self.resumeSimulationButton = Button:new({
        position = { 90, 131 },
        texture1 = texturePaths.resumeButton,
        pressFunction = function ()
            self.simulation.paused = false
        end,
        isDisabled = function ()
            return not self.solver:isSolved() or not self.simulation.paused
        end
    })

    self.executionTimeText = Text:new({
        text = "Execution time",
        position = { 20, 164 },
        dimensions = { self:getTexture(self.solverMenu.texture):getWidth(), 0 },
        font = self.solverMenuFont
    })

    self.executionTimeValue = Text:new({
        text = "",
        position = { 20, 184 },
        dimensions = { self:getTexture(self.solverMenu.texture):getWidth(), 0 },
        font = self.solverMenuFont
    })

    if getmetatable(self) == NonogramScene then
        table.insert(self.buttons, self.previousSolverButton)
        table.insert(self.buttons, self.nextSolverButton)
        table.insert(self.buttons, self.startSolverButton)
        table.insert(self.buttons, self.decreaseSpeedButton)
        table.insert(self.buttons, self.increaseSpeedButton)
        table.insert(self.buttons, self.resetSimulationButton)
        table.insert(self.buttons, self.pauseSimulationButton)
        table.insert(self.buttons, self.resumeSimulationButton)
    end

    local defaultTimeStep, defaultTimeChanges = 1.25, 0.25

    self.simulation = {
        simulating = false,
        paused = false,
        currentStep = 0,
        simulatingStep = false,
        timerBetweenSteps = Timer:new{
            goalTime = defaultTimeStep,
        },
        currentChange = 0,
        timerBetweenChanges = Timer:new{
            goalTime = defaultTimeChanges
        },
        timeModifier = 1,
        minTimeModifier = 2^-2,
        maxTimeModifier = 2^16,
        initializeSimulation = function ()
            self.solvedImageAnimation:reset()
            self.solved = false

            self.simulation.timerBetweenSteps.repetitions = #self.solver.steps

            self.simulation.simulating = true
            self.simulation.simulatingStep = false
            self.simulation.currentStep = 0
            self.simulation.timerBetweenSteps:reset()
            self.simulation.timerBetweenChanges:reset()
            self.clearNonogramTimer:reset()
            self.simulation.timerBetweenSteps:start()
            self.simulation.timerBetweenChanges:start()

            self.iterationValueText.text = ""
        end
    }
end

function NonogramScene:quit()
    self.solver:quit()
end

function NonogramScene:handleMousePress(x, y, button)
    if button == 1 then
        for _, b in pairs(self.buttons) do
            if b:isClicked({ x, y }) then
                b:handleMousePress(x, y, button)
            end
        end
    end

    if button == 3 or love.keyboard.isDown('lctrl') and button == 1 then
        self.initialPosition[1], self.initialPosition[2] = x, y
        self.actions.moving = true

        return
    end

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

function NonogramScene:enterSolvedState(position)
    self.solved = true
    self.solvedImageAnimation:start()
    self.clearNonogramTimer:start()
    finalSolvedFieldPosition = position
end

function NonogramScene:changeField(position, state)
    self.nonogram:changeField(position, state)
    if not self.simulation.simulating and not self.solved and self.nonogram:isSolved() then
        self:enterSolvedState(position)
    end

    local acitons = self.actions

    if acitons.emptying or acitons.marking or acitons.crossing then
        return
    end

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

function NonogramScene:update(dt)
    xOffset, yOffset = xOffset + (scrollSpeedX * dt), yOffset + (scrollSpeedY * dt)

    if xOffset >= imageWidth then
        xOffset = xOffset - imageWidth
    end
    if yOffset >= imageHeight then
        yOffset = yOffset - imageHeight
    end

    quad:setViewport(xOffset, yOffset, width, height)

    self.solvedImageAnimation:update(dt)

    if self.clearNonogramTimer:update(dt) then
        local currIter = self.clearNonogramTimer.timesFinished - 1
        local rows, cols
        local nonogramField
        for i = 0, currIter do
            rows = { finalSolvedFieldPosition[1] - i, finalSolvedFieldPosition[1] + i }
            cols = { finalSolvedFieldPosition[2] - (currIter - i), finalSolvedFieldPosition[2] + (currIter - i) }

            for _, row in ipairs(rows) do
                if row >= 1 and row <= self.nonogram.dimensions[1] then
                    for _, col in ipairs(cols) do
                        if col >= 1 and col <= self.nonogram.dimensions[2] then
                            nonogramField = self.nonogramFields[(row - 1) * self.nonogram.dimensions[2] + col]
                    
                            if nonogramField.state == NonogramFieldState.Crossed then
                                nonogramField:changeState(NonogramFieldState.Empty)
                            end
                        end
                    end
                end
            end
        end
    end

    if not self.solved and self.solver:checkFinished() and not self.simulation.simulating then
        print("NUM OF STEPS: ", #self.solver.steps, "\n")
        if self.solver.solved == 1 then
            self.executionTimeValue.text =  self.solver.executionTime < 1 and string.format("%.5f ms", self.solver.executionTime * 1000) or string.format("%.5f s", self.solver.executionTime)
            self.simulation.initializeSimulation()
        else
            print("Failed to solve")
            self.solver:reset()
        end
    end

    local function simulationChanges(dt)
        while true do
            local ticked, timeUsed = self.simulation.timerBetweenChanges:updateNoOverflow(dt)

            if ticked then
                self.simulation.currentChange = self.simulation.currentChange + 1

                local change = self.solver.steps[self.simulation.currentStep][self.simulation.currentChange] -- should never be nil since timer will stop before that
                local nonogramField = self.nonogramFields[(change.row - 1) * self.nonogram.dimensions[2] + change.col]
                nonogramField:changeState(change.action)

                if not self.simulation.timerBetweenChanges:isRunning() then
                    self.simulation.simulatingStep = false

                    if not self.simulation.timerBetweenSteps:isRunning() then
                        self.simulation.simulating = false

                        if self.nonogram:isSolved() then
                            self:enterSolvedState({ change.row, change.col })
                        end
                    end
                end
                
                dt = dt - timeUsed
            else
                dt = dt - timeUsed
                break
            end
        end

        return dt
    end

    local function simulationSteps(dt)
        while self.simulation.simulating and dt > 0 do
            if not self.simulation.simulatingStep then
                while true do

                    local ticked, timeUsed = self.simulation.timerBetweenSteps:updateNoOverflow(dt)

                    if ticked then
                        self.simulation.currentChange = 0
                        self.simulation.simulatingStep = true
                        self.simulation.currentStep = self.simulation.currentStep + 1
                        self.iterationValueText.text = tostring(self.simulation.currentStep)

                        self.simulation.timerBetweenChanges:changeRepetitions(#self.solver.steps[self.simulation.currentStep])
                        self.simulation.timerBetweenChanges:start()

                        dt = dt - timeUsed

                        dt = simulationChanges(dt)
                    else
                        dt = dt - timeUsed
                        break
                    end
                end
            else
                dt = simulationChanges(dt)
            end
        end
    end

    if not self.simulation.paused then
        simulationSteps(dt)
    end

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
end

function NonogramScene:loadNonogramFromFile()
    local lineIter = love.filesystem.lines(self.filePath)

    local dimensions, rowHints, columnHints, matrixState, solution = {}, {}, {}, {}, {}

    local line = lineIter()

    local pattern = "(%d+)[,\n]?"
    local iterFunc = string.gmatch(line, pattern)
    dimensions[1], dimensions[2] = tonumber(iterFunc()), tonumber(iterFunc())


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
                rowHints[i][hintIndex] = lineStarted and rowHints[i][hintIndex] + 1 or 1
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
                columnHints[j][hintIndex] = lineStarted and columnHints[j][hintIndex] + 1 or 1
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
    love.graphics.draw(backgroundImage, quad)

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

    self:additionalDrawingBeforeButtons()

    for _, button in pairs(self.buttons) do
        button:draw()
    end

    self.solvedImageAnimation:draw()
end

function NonogramScene:additionalDrawingBeforeButtons()
    self.solverMenu:draw()
    self.solverName:draw()
    self.iterationText:draw()
    self.iterationValueText:draw()
    self.currentSpeedText:draw()
    self.executionTimeText:draw()
    self.executionTimeValue:draw()
end

function NonogramScene:ignoreInput()
    return self.solved or self.solver:isRunning() or self.simulation.simulating
end

function NonogramScene:clearBoard()
    for _, nonogramField in ipairs(self.nonogramFields) do
        if nonogramField.state ~= NonogramFieldState.Empty then
            nonogramField:changeState(NonogramFieldState.Empty)
        end
    end
end

return NonogramScene