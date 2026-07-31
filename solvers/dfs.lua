local Nonogram = require 'Nonogram'
local NonogramField = require 'gui.NonogramField'

require "love.timer"
require "math"

local maxSteps = 1000000
local currentSteps = 0

local initialInputChannel = love.thread.getChannel("in")

local sceneHash = initialInputChannel:demand()

local inputChannel, outputChannel, quitChannel = love.thread.getChannel("in_" .. sceneHash), love.thread.getChannel("out_" .. sceneHash), love.thread.getChannel("quit_" .. sceneHash)

local nonogram = Nonogram:new(inputChannel:demand())

-- SOLVER START
local startTime = love.timer.getTime()

local stepsFullPath = {}
local stepsSolutionPath = {}


local nonogramState
nonogramState = {
    addField = function (row, col, fieldValue)
        if fieldValue ~= NonogramFieldState.Marked then
            return
        end

        local rowState, colState = nonogramState.rows[row], nonogramState.cols[col]

        local previousFieldValue = nil

        if col > 1 then
            previousFieldValue = nonogram.matrixState[(row - 1) * nonogram.dimensions[2] + col - 1]
        end

        if previousFieldValue ~= NonogramFieldState.Marked then
            rowState.hintIndex = rowState.hintIndex + 1
        end
        rowState.currentStateAsHints[rowState.hintIndex] = previousFieldValue == NonogramFieldState.Marked and rowState.currentStateAsHints[rowState.hintIndex] + 1 or 1

        if rowState.solved then
            rowState.solved = false
            nonogramState.rowsSolved = nonogramState.rowsSolved - 1
        end


        previousFieldValue = nil

        if row > 1 then
            previousFieldValue = nonogram.matrixState[(row - 1 - 1) * nonogram.dimensions[2] + col]
        end

        if previousFieldValue ~= NonogramFieldState.Marked then
            colState.hintIndex = colState.hintIndex + 1
        end
        colState.currentStateAsHints[colState.hintIndex] = previousFieldValue == NonogramFieldState.Marked and colState.currentStateAsHints[colState.hintIndex] + 1 or 1

        if colState.solved then
            colState.solved = false
            nonogramState.colsSolved = nonogramState.colsSolved - 1
        end
    end,
    removeField = function (row, col, fieldValue)
        if fieldValue ~= NonogramFieldState.Marked then
            return
        end

        local rowState, colState = nonogramState.rows[row], nonogramState.cols[col]

        local previousFieldValue = nil

        if rowState.solved then
            rowState.solved = false
            nonogramState.rowsSolved = nonogramState.rowsSolved - 1
        end

        if col > 1 then
            previousFieldValue = nonogram.matrixState[(row - 1) * nonogram.dimensions[2] + col - 1]
        end

        if previousFieldValue ~= NonogramFieldState.Marked then
            if rowState.currentStateAsHints[rowState.hintIndex] == 1 then
                table.remove(rowState.currentStateAsHints, rowState.hintIndex)
                rowState.hintIndex = rowState.hintIndex - 1
            else
                rowState.currentStateAsHints[rowState.hintIndex] = rowState.currentStateAsHints[rowState.hintIndex] - 1
            end
        else
            rowState.currentStateAsHints[rowState.hintIndex] = rowState.currentStateAsHints[rowState.hintIndex] - 1
        end




        previousFieldValue = nil

        if colState.solved then
            colState.solved = false
            nonogramState.colsSolved = nonogramState.colsSolved - 1
        end

        if row > 1 then
            previousFieldValue = nonogram.matrixState[(row - 1 - 1) * nonogram.dimensions[2] + col]
        end

        if previousFieldValue ~= NonogramFieldState.Marked then
            if colState.currentStateAsHints[colState.hintIndex] == 1 then
                table.remove(colState.currentStateAsHints, colState.hintIndex)
                colState.hintIndex = colState.hintIndex - 1
            else
                colState.currentStateAsHints[colState.hintIndex] = colState.currentStateAsHints[colState.hintIndex] - 1
            end
        else
            colState.currentStateAsHints[colState.hintIndex] = colState.currentStateAsHints[colState.hintIndex] - 1
        end
    end,
    rows = {},
    cols = {},
    rowsSolved = 0,
    colsSolved = 0
}

for _, rowHint in ipairs(nonogram.rowHints) do
    local rowData = {
            solved = #rowHint == 0,
            currentStateAsHints = {},
            lineStarted = false,
            hintIndex = 0
        }

    if rowData.solved then
        nonogramState.rowsSolved = nonogramState.rowsSolved + 1
    end

    local minimumFieldsNeededToFitLine = {}
    for i, val in ipairs(rowHint) do
        for j = 1, i do
            if minimumFieldsNeededToFitLine[j] == nil then
                minimumFieldsNeededToFitLine[j] = val
            else
                minimumFieldsNeededToFitLine[j] = minimumFieldsNeededToFitLine[j] + val + 1
            end
        end
    end

    rowData.minimumFieldsNeededToFitLine = minimumFieldsNeededToFitLine

    table.insert(
        nonogramState.rows,
        rowData
    )
end

for _, colHint in ipairs(nonogram.columnHints) do
    local colData = {
            solved = #colHint == 0,
            currentStateAsHints = {},
            lineStarted = false,
            hintIndex = 0
        }

    if colData.solved then
        nonogramState.colsSolved = nonogramState.colsSolved + 1
    end

    local minimumFieldsNeededToFitLine = {}
    for i, val in ipairs(colHint) do
        for j = 1, i do
            if minimumFieldsNeededToFitLine[j] == nil then
                minimumFieldsNeededToFitLine[j] = val
            else
                minimumFieldsNeededToFitLine[j] = minimumFieldsNeededToFitLine[j] + val + 1
            end
        end
    end

    colData.minimumFieldsNeededToFitLine = minimumFieldsNeededToFitLine

    table.insert(
        nonogramState.cols,
        colData
    )
end

local function verifyEnoughFieldsToCompleteRow(rowState, row, col, fieldValue)
    local currentStateAsHints, hintIndex = rowState.currentStateAsHints, rowState.hintIndex
    local hintIndexForRemainingFieldsNeededCalc = hintIndex + (fieldValue == NonogramFieldState.Marked and 0 or 1)
    if hintIndexForRemainingFieldsNeededCalc ~= 0 and (
        #nonogram.rowHints[row] >= hintIndexForRemainingFieldsNeededCalc and rowState.minimumFieldsNeededToFitLine[hintIndexForRemainingFieldsNeededCalc] - (fieldValue == NonogramFieldState.Marked and currentStateAsHints[hintIndexForRemainingFieldsNeededCalc] or 0) > nonogram.dimensions[2] - col
        or
        #nonogram.rowHints[row] < hintIndexForRemainingFieldsNeededCalc and not rowState.solved
        ) then
        return false
    end
    return true
end

local function verifyEnoughFieldsToCompleteCol(colState, row, col, fieldValue)
    local currentStateAsHints, hintIndex = colState.currentStateAsHints, colState.hintIndex
    local hintIndexForRemainingFieldsNeededCalc = hintIndex + (fieldValue == NonogramFieldState.Marked and 0 or 1)
    if hintIndexForRemainingFieldsNeededCalc ~= 0 and (
        #nonogram.columnHints[col] >= hintIndexForRemainingFieldsNeededCalc and colState.minimumFieldsNeededToFitLine[hintIndexForRemainingFieldsNeededCalc] - (fieldValue == NonogramFieldState.Marked and currentStateAsHints[hintIndexForRemainingFieldsNeededCalc] or 0) > nonogram.dimensions[1] - row
        or
        #nonogram.columnHints[col] < hintIndexForRemainingFieldsNeededCalc and not colState.solved
        ) then
        return false
    end
    return true
end

local function verifyRow(rowState, row, col, fieldValue)
    
    local currentStateAsHints, hintIndex = rowState.currentStateAsHints, rowState.hintIndex

    if not verifyEnoughFieldsToCompleteRow(rowState, row, col, fieldValue) then
        return false
    end

    if hintIndex < 1 then
        if not rowState.solved and #nonogram.rowHints[row] == 0 then
            rowState.solved = true
            nonogramState.rowsSolved = nonogramState.rowsSolved + 1
        end
        return true
    end

    if
        nonogram.rowHints[row][hintIndex] == nil or
        nonogram.rowHints[row][hintIndex] ~= nil and nonogram.rowHints[row][hintIndex] < currentStateAsHints[hintIndex] then
        return false
    end

    if fieldValue ~= NonogramFieldState.Marked and nonogram.rowHints[row][hintIndex] ~= currentStateAsHints[hintIndex] then
        return false
    end

    if not rowState.solved and nonogram.rowHints[row][hintIndex] == currentStateAsHints[hintIndex] and #currentStateAsHints == #nonogram.rowHints[row] then
        rowState.solved = true
        nonogramState.rowsSolved = nonogramState.rowsSolved + 1
    end

    return true
end

local function verifyCol(colState, row, col, fieldValue)

    local currentStateAsHints, hintIndex = colState.currentStateAsHints, colState.hintIndex

    if not verifyEnoughFieldsToCompleteCol(colState, row, col, fieldValue) then
        return false
    end

    if hintIndex < 1 then
        if not colState.solved and #nonogram.columnHints[col] == 0 then
            colState.solved = true
            nonogramState.colsSolved = nonogramState.colsSolved + 1
        end
        return true
    end

    if
        nonogram.columnHints[col][hintIndex] == nil or
        nonogram.columnHints[col][hintIndex] ~= nil and nonogram.columnHints[col][hintIndex] < currentStateAsHints[hintIndex] then
        return false
    end

    if fieldValue ~= NonogramFieldState.Marked and nonogram.columnHints[col][hintIndex] ~= currentStateAsHints[hintIndex] then
        return false
    end

    if not colState.solved and nonogram.columnHints[col][hintIndex] == colState.currentStateAsHints[hintIndex] and #currentStateAsHints == #nonogram.columnHints[col] then
        colState.solved = true
        nonogramState.colsSolved = nonogramState.colsSolved + 1
    end

    return true
end

local function verify(row, col)
    local fieldValue
    local rowState, colState = nonogramState.rows[row], nonogramState.cols[col]

    fieldValue = nonogram.matrixState[(row - 1) * nonogram.dimensions[2] + col]

    if not verifyRow(rowState, row, col, fieldValue) then
        return false
    end
    if not verifyCol(colState, row, col, fieldValue) then
        return false
    end

    return true
end

local function findNextIJ(i, j)
    local initialI, initialJ = i, j

    while i <= nonogram.dimensions[1] and nonogramState.rows[i].solved do
        i = i + 1
        j = 1
    end

    if i <= nonogram.dimensions[1] then
        if i > initialI then
            for col = (i - 1 == initialI and initialJ or j), nonogram.dimensions[2] do
                if not verifyCol(nonogramState.cols[col], i - 1, col, NonogramFieldState.Empty) then
                    return initialI, initialJ, false
                end
            end
        end

        while j <= nonogram.dimensions[2] and nonogramState.cols[j].solved do
            j = j + 1
        end

        if j > nonogram.dimensions[2] then
            return initialI, initialJ, false
        end

        if i == initialI and j > initialJ or i > initialI and j > 1 then
            if not verifyRow(nonogramState.rows[i], i, j - 1, NonogramFieldState.Empty) then
                return initialI, initialJ, false
            end
        end
    end

    return i, j, true
end

local function findSolution(i, j)

    if quitChannel:peek() then
        error("ABORT")
    end

    if nonogramState.rowsSolved == nonogram.dimensions[1] and nonogramState.colsSolved == nonogram.dimensions[2] then
        return nonogram:isSolved()
    elseif i == nonogram.dimensions[1] + 1 then
        return false
    end

    local nextI, nextJ, index = j == nonogram.dimensions[2] and i + 1 or i, (j % nonogram.dimensions[2]) + 1, (i - 1) * nonogram.dimensions[2] + j

    nonogram.matrixState[index] = NonogramFieldState.Marked
    nonogramState.addField(i, j, NonogramFieldState.Marked)

    local triedAnyOption = false

    if verify(i, j) then

        local skippedI, skippedJ, solutionPossible = findNextIJ(nextI, nextJ)

        if solutionPossible then

            triedAnyOption = true

            if stepsFullPath then
                table.insert(
                    stepsFullPath,
                    {
                        {
                            row = i,
                            col = j,
                            action = NonogramFieldState.Marked
                        }
                    }
                )

                currentSteps = currentSteps + 1
                if (currentSteps > maxSteps) then
                    stepsFullPath = nil
                end
            end
            table.insert(
                stepsSolutionPath,
                {
                    {
                        row = i,
                        col = j,
                        action = NonogramFieldState.Marked
                    }
                }
            )

            if findSolution(skippedI, skippedJ) then
                return true
            end

            table.remove(stepsSolutionPath)
        end
    end

    nonogram.matrixState[index] = NonogramFieldState.Crossed
    nonogramState.removeField(i, j, NonogramFieldState.Marked)
    nonogramState.addField(i, j, NonogramFieldState.Crossed)

    if verify(i, j) then

        local skippedI, skippedJ, solutionPossible = findNextIJ(nextI, nextJ)

        if solutionPossible then

            triedAnyOption = true

            if stepsFullPath then
                table.insert(
                    stepsFullPath,
                    {
                        {
                            row = i,
                            col = j,
                            action = NonogramFieldState.Crossed
                        }
                    }
                )

                currentSteps = currentSteps + 1
                if (currentSteps > maxSteps) then
                    stepsFullPath = nil
                end
            end
            table.insert(
                stepsSolutionPath,
                {
                    {
                        row = i,
                        col = j,
                        action = NonogramFieldState.Crossed
                    }
                }
            )

            if findSolution(skippedI, skippedJ) then
                return true
            end

            table.remove(stepsSolutionPath)
        end
    end

    nonogram.matrixState[index] = NonogramFieldState.Empty
    nonogramState.removeField(i, j, NonogramFieldState.Crossed)

    if triedAnyOption and stepsFullPath then
        table.insert(
            stepsFullPath,
            {
                {
                    row = i,
                    col = j,
                    action = NonogramFieldState.Empty
                }
            }
        )

        currentSteps = currentSteps + 1
        if (currentSteps > maxSteps) then
            stepsFullPath = nil
        end
    end

    return false
end

local success, solved = pcall(function () return findSolution(findNextIJ(1, 1)) end)

if success then
    outputChannel:performAtomic(
        function ()
            outputChannel:push(solved)
            outputChannel:push(stepsFullPath or stepsSolutionPath)
            outputChannel:push(love.timer.getTime() - startTime)
        end
    )
else
    print(solved)
end

stepsFullPath = nil
stepsSolutionPath = nil
collectgarbage()