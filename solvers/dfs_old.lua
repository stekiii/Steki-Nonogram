local Nonogram = require 'Nonogram'
local NonogramField = require 'gui.NonogramField'

require "love.timer"

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


local fieldsMarked = 0
local numOfTotalMarkedFields = 0

local nonogramState = {
    rows = {},
    cols = {}
}

for _, rowHint in ipairs(nonogram.rowHints) do
    local rowData = {}

    local minimumFieldsNeededToFitLine = {}
    local markedFields = 0
    for i, val in ipairs(rowHint) do
        for j = 1, i do
            if minimumFieldsNeededToFitLine[j] == nil then
                minimumFieldsNeededToFitLine[j] = val
            else
                minimumFieldsNeededToFitLine[j] = minimumFieldsNeededToFitLine[j] + val + 1
            end
        end
        markedFields = markedFields + val
    end


    numOfTotalMarkedFields =  numOfTotalMarkedFields + markedFields

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

local function verify(row, col)
    local hintIndex, fieldValue, lineStarted

    local currentRowStateAsHints = {}
    local currentColStateAsHints = {}

    lineStarted = false
    hintIndex = 1

    local function verifyEnoughFieldsToCompleteRow()
        if fieldValue == nil then
            return true
        end

        if
            #nonogram.rowHints[row] >= hintIndex and nonogramState.rows[row].minimumFieldsNeededToFitLine[hintIndex] - (fieldValue == NonogramFieldState.Marked and currentRowStateAsHints[hintIndex] or 0) > nonogram.dimensions[2] - col
            or
            #nonogram.rowHints[row] < hintIndex and currentRowStateAsHints[hintIndex] ~= nonogram.rowHints[row][hintIndex]
            then
            return false
        end
        return true
    end

    local function verifyEnoughFieldsToCompleteCol()
        if fieldValue == nil then
            return true
        end

        if
            #nonogram.columnHints[col] >= hintIndex and nonogramState.cols[col].minimumFieldsNeededToFitLine[hintIndex] - (fieldValue == NonogramFieldState.Marked and currentColStateAsHints[hintIndex] or 0) > nonogram.dimensions[1] - row
            or
            #nonogram.columnHints[col] < hintIndex and currentColStateAsHints[hintIndex] ~= nonogram.columnHints[col][hintIndex]
            then
            return false
        end
        return true
    end

    local function badRow()
        if
            nonogram.rowHints[row][hintIndex] == nil and currentRowStateAsHints[hintIndex] ~= nil or
            nonogram.rowHints[row][hintIndex] ~= nil and currentRowStateAsHints[hintIndex] ~= nil and nonogram.rowHints[row][hintIndex] < currentRowStateAsHints[hintIndex] then
            return true
        end

        if fieldValue == NonogramFieldState.Crossed and nonogram.rowHints[row][hintIndex] ~= nil and currentRowStateAsHints[hintIndex] ~= nil and nonogram.rowHints[row][hintIndex] ~= currentRowStateAsHints[hintIndex] then
            return true
        end
    end

    local function badCol()
        if
            nonogram.columnHints[col][hintIndex] == nil and currentColStateAsHints[hintIndex] ~= nil or
            nonogram.columnHints[col][hintIndex] ~= nil and currentColStateAsHints[hintIndex] ~= nil and nonogram.columnHints[col][hintIndex] < currentColStateAsHints[hintIndex] then
            return true
        end

        if fieldValue == NonogramFieldState.Crossed and nonogram.columnHints[col][hintIndex] ~= nil and currentColStateAsHints[hintIndex] ~= nil and nonogram.columnHints[col][hintIndex] ~= currentColStateAsHints[hintIndex] then
            return true
        end
    end

    for i = 1, nonogram.dimensions[2], 1 do
        fieldValue = nonogram.matrixState[(row - 1) * nonogram.dimensions[2] + i]

        if fieldValue == NonogramFieldState.Empty then
            fieldValue = nonogram.matrixState[(row - 1) * nonogram.dimensions[2] + i - 1]
            break
        end
        
        if fieldValue == NonogramFieldState.Marked then
            currentRowStateAsHints[hintIndex] = lineStarted and currentRowStateAsHints[hintIndex] + 1 or 1
            lineStarted = true
        elseif lineStarted then
            if badRow() then
                return false
            end

            hintIndex = hintIndex + 1
            lineStarted = false
        end
    end

    if not verifyEnoughFieldsToCompleteRow() then
        return false
    end

    if badRow() then
        return false
    end



    lineStarted = false
    hintIndex = 1

    for i = 1, nonogram.dimensions[1], 1 do
        fieldValue = nonogram.matrixState[(i - 1) * nonogram.dimensions[2] + col]

        if fieldValue == NonogramFieldState.Empty then
            fieldValue = nonogram.matrixState[(i - 1 - 1) * nonogram.dimensions[2] + col]
            break
        end
        
        if fieldValue == NonogramFieldState.Marked then
            currentColStateAsHints[hintIndex] = lineStarted and currentColStateAsHints[hintIndex] + 1 or 1
            lineStarted = true
        elseif lineStarted then
            if badCol() then
                return false
            end

            hintIndex = hintIndex + 1
            lineStarted = false
        end
    end

    if not verifyEnoughFieldsToCompleteCol() then
        return false
    end

    if badCol() then
        return false
    end

    return true
end

local function findSolution(i, j)

    if quitChannel:peek() then
        error("ABORT")
    end

    if fieldsMarked == numOfTotalMarkedFields or i == nonogram.dimensions[1] + 1 then
        return nonogram:isSolved()
    end

    local nextI, nextJ, index = j == nonogram.dimensions[2] and i + 1 or i, (j % nonogram.dimensions[2]) + 1, (i - 1) * nonogram.dimensions[2] + j

    nonogram.matrixState[index] = NonogramFieldState.Marked
    fieldsMarked = fieldsMarked + 1

    local triedAnyOption = false

    if verify(i, j) then

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

        if findSolution(nextI, nextJ) then
            return true
        end

        table.remove(stepsSolutionPath)
    end

    nonogram.matrixState[index] = NonogramFieldState.Crossed
    fieldsMarked = fieldsMarked - 1
    
    if verify(i, j) then

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

        if findSolution(nextI, nextJ) then
            return true
        end

        table.remove(stepsSolutionPath)
    end

    nonogram.matrixState[index] = NonogramFieldState.Empty
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

local success, solved = pcall(function () return findSolution(1, 1) end)

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
    outputChannel:push(false)
end

stepsFullPath = nil
stepsSolutionPath = nil
collectgarbage()