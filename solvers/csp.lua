local Nonogram = require 'Nonogram'
local NonogramField = require 'gui.NonogramField'

require "love.timer"

local initialInputChannel = love.thread.getChannel("in")

local sceneHash = initialInputChannel:demand()

local inputChannel, outputChannel, quitChannel = love.thread.getChannel("in_" .. sceneHash), love.thread.getChannel("out_" .. sceneHash), love.thread.getChannel("quit_" .. sceneHash)

local nonogram = Nonogram:new(inputChannel:demand())

-- SOLVER START
local startTime = love.timer.getTime()

local stepsFullPath = {}

local stepsSolutionPath

local numOfMarked = 0
local totalNumOfMarked = 0

local numOfSolved = 0

for _, rowHint in ipairs(nonogram.rowHints) do
    local markedFields = 0
    for _, val in ipairs(rowHint) do
        markedFields = markedFields + val
    end

    totalNumOfMarked =  totalNumOfMarked + markedFields
end

local maxMemoryMB = 4096

local function generateNonogramCombinations()

    local function checkMemory()
        local memoryKB = collectgarbage("count")

        if memoryKB / 1024 >= maxMemoryMB then
            error("Combinations take up too much memory.")
        end
    end

    local function generateLineCombinations(lineHints, lineLen)

        local function calculateCombinations(n, k)
            local result = {}
            local combination = {}
            local id = 1

            local function calculateCombinationRecursive(start, depth)

                if (id % 1000 == 0) then
                    checkMemory()
                end

                if depth > k then
                    local copy = {}

                    for i = 1, k do
                        copy[i] = combination[i]
                    end

                    table.insert(result,
                        {
                            id = id,
                            combination = copy
                        }
                    )
                    id = id + 1

                    return
                end

                for i = start, n do
                    if n - i < k - depth then
                        return
                    end

                    combination[depth] = i
                    calculateCombinationRecursive(i + 1, depth + 1)
                end
            end

            calculateCombinationRecursive(1, 1)

            return result, id - 1
        end

        local numOfGroups = #lineHints
        local sum = 0

        for _, hint in ipairs(lineHints) do
            sum = sum + hint
        end

        local numOfEmptyFields = lineLen - (sum + (numOfGroups > 0 and numOfGroups - 1 or 0)) -- not counting the fields required to be there between groups

        local combinations, numOfCombinations = calculateCombinations(numOfGroups + numOfEmptyFields, numOfGroups)

        return {
            numOfCombinations = numOfCombinations,
            combinations = combinations,
            numOfGroups = numOfGroups,
            numOfEmptyFields = numOfEmptyFields
        }
    end

    local rowCombinations, colCombinations = {}, {}

    local testStartTime = love.timer.getTime()

    for _, rowHint in ipairs(nonogram.rowHints) do
        table.insert(rowCombinations, generateLineCombinations(rowHint, nonogram.dimensions[2]))
        checkMemory()
    end
    for _, colHint in ipairs(nonogram.columnHints) do
        table.insert(colCombinations, generateLineCombinations(colHint, nonogram.dimensions[1]))
        checkMemory()
    end

    print("Time to generate all combinations: ", love.timer.getTime() - testStartTime)

    return rowCombinations, colCombinations
end

local success, rowCombinations, colCombinations = pcall(function () return generateNonogramCombinations() end)
local changedRows, changedCols = {}, {}
local generatedCombinations = {
    {}, -- rows
    {}  -- cols
}

local lineOrder = {}

for i = 1, nonogram.dimensions[1] do
    table.insert(generatedCombinations[1], {})
    changedRows[i] = true
    table.insert(lineOrder,{
        line = 1, -- row
        index = i
    })
end
for i = 1, nonogram.dimensions[2] do
    table.insert(generatedCombinations[2], {})
    changedCols[i] = true
    table.insert(lineOrder,{
        line = 2, -- col
        index = i
    })
end

local function findSolution()
    local function getLineFromCombination(line, index, combination, lineHints, lineCombinations)
        if generatedCombinations[line][index][combination.id] ~= nil then
            return generatedCombinations[line][index][combination.id]
        end

        local currentLineCombination = {}
        local i = 1

        for hintNumber, choice in ipairs(combination.combination) do
            while (i < choice) do
                table.insert(currentLineCombination, NonogramFieldState.Crossed)
                i = i + 1
            end

            for _ = 1, lineHints[hintNumber] do
                table.insert(currentLineCombination, NonogramFieldState.Marked)
            end

            if hintNumber < #combination.combination then
                table.insert(currentLineCombination, NonogramFieldState.Crossed)
            end

            i = i + 1
        end

        while (i <= lineCombinations.numOfGroups + lineCombinations.numOfEmptyFields) do
            table.insert(currentLineCombination, NonogramFieldState.Crossed)
            i = i + 1
        end

        generatedCombinations[line][index][combination.id] = currentLineCombination

        return currentLineCombination
    end

    -- Empty fields mean that the value is not known
    local function determineConfirmedFieldsInLine(line, index, lineCombinations, lineHints)
        local confirmedFields = {}

        for i, value in ipairs(getLineFromCombination(line, index, lineCombinations.combinations[1], lineHints, lineCombinations)) do
            confirmedFields[i] = value
        end

        local numOfCombinations = lineCombinations.numOfCombinations
        local numOfUnknown = 0

        if numOfCombinations > 1 then
            for i, currentField in ipairs(getLineFromCombination(line, index, lineCombinations.combinations[numOfCombinations], lineHints, lineCombinations)) do
                if confirmedFields[i] ~= NonogramFieldState.Empty and currentField ~= confirmedFields[i] then
                    confirmedFields[i] = NonogramFieldState.Empty
                    numOfUnknown = numOfUnknown + 1
                end
            end

            if numOfUnknown == nonogram.dimensions[3 - line] then
                return confirmedFields, false
            end

            for i = 2, numOfCombinations - 1 do
                for j, currentField in ipairs(getLineFromCombination(line, index, lineCombinations.combinations[i], lineHints, lineCombinations)) do
                    if confirmedFields[j] ~= NonogramFieldState.Empty and currentField ~= confirmedFields[j] then
                        confirmedFields[j] = NonogramFieldState.Empty
                        numOfUnknown = numOfUnknown + 1
                    end
                end

                if numOfUnknown == nonogram.dimensions[3 - line] then
                    return confirmedFields, false
                end
            end
        else
            table.remove(lineCombinations.combinations)
            lineCombinations.numOfCombinations = 0
            numOfSolved = numOfSolved + 1
        end

        if line == 1 then
            for i = 1, nonogram.dimensions[2] do
                if nonogram.matrixState[(index - 1) * nonogram.dimensions[2] + i] ~= NonogramFieldState.Empty then
                    confirmedFields[i] = NonogramFieldState.Empty
                end
            end
        else
            for i = 1, nonogram.dimensions[1] do
                if nonogram.matrixState[(i - 1) * nonogram.dimensions[2] + index] ~= NonogramFieldState.Empty then
                    confirmedFields[i] = NonogramFieldState.Empty
                end
            end
        end

        return confirmedFields, true
    end

    local function determineConfirmedMarkedFieldsInLine(combinations, lineHints)
        local rightmostMarkedFieldsFromLeftmostCombination, leftmostMarkedFieldsFromRightmostCombination = {}, {}

        local currIndex = 1
        local i = 1

        for hintNumber, choice in ipairs(combinations.combinations[1].combination) do
            if i < choice then
                currIndex = currIndex + choice - i
                i = choice
            end

            currIndex = currIndex + lineHints[hintNumber]

            rightmostMarkedFieldsFromLeftmostCombination[hintNumber] = currIndex - 1
        end

        currIndex = 1
        i = 1

        for hintNumber, choice in ipairs(combinations.combinations[combinations.numOfCombinations].combination) do
            if i < choice then
                currIndex = currIndex + choice - i
                i = choice
            end

            leftmostMarkedFieldsFromRightmostCombination[hintNumber] = currIndex

            currIndex = currIndex + lineHints[hintNumber]
        end

        return leftmostMarkedFieldsFromRightmostCombination, rightmostMarkedFieldsFromLeftmostCombination
    end

    -- returns whether the line changed
    local function applyConfirmedFieldsToLine(line, fields, index)
        local changed = false
        local step = {}

        if line == 1 then
            for i, value in ipairs(fields) do
                if value ~= NonogramFieldState.Empty and nonogram.matrixState[(index - 1) * nonogram.dimensions[2] + i] ~= value then
                    nonogram.matrixState[(index - 1) * nonogram.dimensions[2] + i] = value
                    changed = true

                    table.insert(step, {
                        row = index,
                        col = i,
                        action = value,
                    })

                    changedCols[i] = true

                    numOfMarked = numOfMarked + (value == NonogramFieldState.Marked and 1 or 0)
                end
            end
        else
            for i, value in ipairs(fields) do
                if value ~= NonogramFieldState.Empty and nonogram.matrixState[(i - 1) * nonogram.dimensions[2] + index] ~= value then
                    nonogram.matrixState[(i - 1) * nonogram.dimensions[2] + index] = value
                    changed = true

                    table.insert(step, {
                        row = i,
                        col = index,
                        action = value,
                    })

                    changedRows[i] = true

                    numOfMarked = numOfMarked + (value == NonogramFieldState.Marked and 1 or 0)
                end
            end
        end

        if #step > 0 then
            table.insert(stepsFullPath, step)
        end

        return changed
    end

    local function applyConfirmedMarkedFieldsToLine(line, leftmostFields, rightmostFields, index)
        local changed = false
        local step = {}

        if line == 1 then
            for i = 1, #leftmostFields do
                for j = leftmostFields[i], rightmostFields[i] do
                    if nonogram.matrixState[(index - 1) * nonogram.dimensions[2] + j] ~= NonogramFieldState.Marked then
                        nonogram.matrixState[(index - 1) * nonogram.dimensions[2] + j] = NonogramFieldState.Marked
                        changed = true

                        table.insert(step, {
                            row = index,
                            col = j,
                            action = NonogramFieldState.Marked,
                        })

                        changedCols[j] = true

                        numOfMarked = numOfMarked + 1
                    end
                end
            end
        else
            for i = 1, #leftmostFields do
                for j = leftmostFields[i], rightmostFields[i] do
                    if nonogram.matrixState[(j - 1) * nonogram.dimensions[2] + index] ~= NonogramFieldState.Marked then
                        nonogram.matrixState[(j - 1) * nonogram.dimensions[2] + index] = NonogramFieldState.Marked
                        changed = true

                        table.insert(step, {
                            row = j,
                            col = index,
                            action = NonogramFieldState.Marked,
                        })

                        changedRows[j] = true

                        numOfMarked = numOfMarked + 1
                    end
                end
            end
        end

        if #step > 0 then
            table.insert(stepsFullPath, step)
        end

        return changed
    end

    local function getFieldInCombination(index, combination, lineHints)
        local currIndex = 1
        local i = 1

        for hintNumber, choice in ipairs(combination) do
            if i < choice then
                currIndex = currIndex + choice - i
                if index < currIndex then
                    return NonogramFieldState.Crossed
                end
                i = choice
            end

            currIndex = currIndex + lineHints[hintNumber]
            if index < currIndex then
                return NonogramFieldState.Marked
            end
        end

        return NonogramFieldState.Crossed
    end

    --[[
    for example:
    combinations => a table of combinations for each column
    changedLine  => the table containing all fields that were changed. NonogramFieldState.Empty represents a field that remains unknown
    index        => index of the row that was just changed so that we can check those fields in all of the column combinations
    ]]
    local function removeImpossibleOptionsFromCombinations(combinations, changedLine, index, allLineHints)
        for i, changedLineField in ipairs(changedLine) do
            if changedLineField ~= NonogramFieldState.Empty then
                for j = combinations[i].numOfCombinations, 1, -1 do
                    if getFieldInCombination(index, combinations[i].combinations[j].combination, allLineHints[i]) ~= changedLineField then
                        table.remove(combinations[i].combinations, j)
                        combinations[i].numOfCombinations = combinations[i].numOfCombinations - 1
                    end
                end
            end
        end
    end

    local function removeImpossibleOptionsFromCombinationsCheapVariant(combinations, leftmostFields, rightmostFields, index, allLineHints)
        for i = 1, #leftmostFields do
            for j = leftmostFields[i], rightmostFields[i] do
                for k = combinations[j].numOfCombinations, 1, -1 do
                    if getFieldInCombination(index, combinations[j].combinations[k].combination, allLineHints[j]) ~= NonogramFieldState.Marked then
                        table.remove(combinations[j].combinations, k)
                        combinations[j].numOfCombinations = combinations[j].numOfCombinations - 1
                    end
                end
            end
        end
    end

    local function evaluateRow(row)
        if rowCombinations[row].numOfCombinations > 0 and changedRows[row] then

            local lineChanged = false
            local confirmedFields, thereAreConfirmedFields = determineConfirmedFieldsInLine(1, row, rowCombinations[row], nonogram.rowHints[row])

            if thereAreConfirmedFields then
                lineChanged = applyConfirmedFieldsToLine(1, confirmedFields, row)

                if lineChanged then
                    if numOfMarked == totalNumOfMarked then
                        return nonogram:isSolved(), lineChanged
                    end

                    removeImpossibleOptionsFromCombinations(colCombinations, confirmedFields, row, nonogram.columnHints)
                end
            end

            changedRows[row] = false

            return false, lineChanged
        end

        return false, false
    end

    local function evaluateCol(col)
        if colCombinations[col].numOfCombinations > 0 and changedCols[col] then

            local lineChanged = false
            local confirmedFields, thereAreConfirmedFields = determineConfirmedFieldsInLine(2, col, colCombinations[col], nonogram.columnHints[col])

            if thereAreConfirmedFields then
                lineChanged = applyConfirmedFieldsToLine(2, confirmedFields, col)

                if lineChanged then
                    if numOfMarked == totalNumOfMarked then
                        return nonogram:isSolved(), lineChanged
                    end

                    removeImpossibleOptionsFromCombinations(rowCombinations, confirmedFields, col, nonogram.rowHints)
                end
            end

            changedCols[col] = false

            return false, lineChanged
        end

        return false, false
    end

    local function cheapOverlapOperation()
        local function cheapEvaluateRow(row)
            if rowCombinations[row].numOfCombinations > 0 and changedRows[row] then
                if rowCombinations[row].numOfCombinations == 1 then
                    return evaluateRow(row)
                end

                local leftmostFields, rightmostFields = determineConfirmedMarkedFieldsInLine(rowCombinations[row], nonogram.rowHints[row])

                local lineChanged = applyConfirmedMarkedFieldsToLine(1, leftmostFields, rightmostFields, row)

                if lineChanged then
                    if numOfMarked == totalNumOfMarked then
                        return nonogram:isSolved(), lineChanged
                    end

                    removeImpossibleOptionsFromCombinationsCheapVariant(colCombinations, leftmostFields, rightmostFields, row, nonogram.columnHints)
                end

                changedRows[row] = false

                return false, lineChanged
            end

            return false, false
        end

        local function cheapEvaluateCol(col)
            if colCombinations[col].numOfCombinations > 0 and changedCols[col] then
                if colCombinations[col].numOfCombinations == 1 then
                    return evaluateCol(col)
                end

                local leftmostFields, rightmostFields = determineConfirmedMarkedFieldsInLine(colCombinations[col], nonogram.columnHints[col])

                local lineChanged = applyConfirmedMarkedFieldsToLine(2, leftmostFields, rightmostFields, col)

                if lineChanged then
                    if numOfMarked == totalNumOfMarked then
                        return nonogram:isSolved(), lineChanged
                    end

                    removeImpossibleOptionsFromCombinationsCheapVariant(rowCombinations, leftmostFields, rightmostFields, col, nonogram.rowHints)
                end

                changedCols[col] = false

                return false, lineChanged
            end

            return false, false
        end

        local changed = true
        local solved, lineChanged
        table.sort(lineOrder, function (a, b)
            local allCombinationA = a.line == 1 and rowCombinations or colCombinations
            local allCombinationB = b.line == 1 and rowCombinations or colCombinations

            return allCombinationA[a.index].numOfCombinations < allCombinationB[b.index].numOfCombinations or
                allCombinationA[a.index].numOfCombinations == allCombinationB[b.index].numOfCombinations and a.index < b.index
        end)

        while changed do
            if quitChannel:peek() then
                error("ABORT")
            end

            changed = false

            for _, line in ipairs(lineOrder) do
                if line.line == 1 then
                    solved, lineChanged = cheapEvaluateRow(line.index)
                else
                    solved, lineChanged = cheapEvaluateCol(line.index)
                end

                if solved then
                    return true
                end

                changed = changed or lineChanged
            end
        end

        return false
    end

    local function expensiveOverlapOperation()
        if cheapOverlapOperation() then
            return true
        end

        for i = 1, nonogram.dimensions[1] do
            changedRows[i] = rowCombinations[i].numOfCombinations > 0
        end
        for i = 1, nonogram.dimensions[2] do
            changedCols[i] = colCombinations[i].numOfCombinations > 0
        end

        local changed = true
        local lineChanged, solved
        table.sort(lineOrder, function (a, b)
            local allCombinationA = a.line == 1 and rowCombinations or colCombinations
            local allCombinationB = b.line == 1 and rowCombinations or colCombinations

            return allCombinationA[a.index].numOfCombinations < allCombinationB[b.index].numOfCombinations or
                allCombinationA[a.index].numOfCombinations == allCombinationB[b.index].numOfCombinations and a.index < b.index
        end)

        while changed do
            if quitChannel:peek() then
                error("ABORT")
            end

            changed = false

            for _, line in ipairs(lineOrder) do
                if line.line == 1 then
                    solved, lineChanged = evaluateRow(line.index)
                else
                    solved, lineChanged = evaluateCol(line.index)
                end

                if solved then
                    return true
                end

                changed = changed or lineChanged
            end
        end

        return false
    end

    local testStartTime = love.timer.getTime()

    -- REDUCE PROBLEM
    local solved = expensiveOverlapOperation()
    print("Reduce time: ", love.timer.getTime() - testStartTime)

    if solved then
        return true
    end


    -- CSP - Backtracking and Forward checking

    testStartTime = love.timer.getTime()

    local maxSteps, currentSteps = 35000, 0

    stepsSolutionPath = {}
    for _, step in ipairs(stepsFullPath) do
        table.insert(stepsSolutionPath, step)
    end

    local undoHistoryNonogram = {}
    local undoHistoryCombinations = {}
    local undoHistoryCombinationsForwardCheck = {}
    local sortedCombinations = {}
    local allCombinationsRows, allCombinationsCols = {}, {}

    local numOfUnsolvedRows, numOfUnsolvedCols = 0, 0

    for i, rowCombs in ipairs(rowCombinations) do
        local allCombinationsRow = {}
        for combinationIndex, rowComb in ipairs(rowCombs.combinations) do
            table.insert(allCombinationsRow, {
                index = combinationIndex,
                combination = rowComb
            })
        end

        table.insert(allCombinationsRows, {
            index = i,
            combinations = allCombinationsRow
        })

        numOfUnsolvedRows = numOfUnsolvedRows + (rowCombs.numOfCombinations == 0 and 0 or 1)
    end
    for i, colCombs in ipairs(colCombinations) do
        local allCombinationsCol = {}
        for combinationIndex, colComb in ipairs(colCombs.combinations) do
            table.insert(allCombinationsCol, {
                index = combinationIndex,
                combination = colComb
            })
        end

        table.insert(allCombinationsCols, {
            index = i,
            combinations = allCombinationsCol
        })

        numOfUnsolvedCols = numOfUnsolvedCols + (colCombs.numOfCombinations == 0 and 0 or 1)
    end

    -- Most Constraining Variable
    -- solve for the 'group' with less elements, and for the other group just check if their domains are empty
    sortedCombinations = numOfUnsolvedRows <= numOfUnsolvedCols and {
        line = "row",
        allCombinations = allCombinationsRows
    }
    or {
        line = "col",
        allCombinations = allCombinationsCols
    }

    local line = sortedCombinations.line == "row" and 1 or 2
    local lineHints = line == 1 and nonogram.rowHints or nonogram.columnHints
    local allLineCombinations = line == 1 and rowCombinations or colCombinations
    local perpendicularLineHints = line == 1 and nonogram.columnHints or nonogram.rowHints
    local allPerpendicularLineCombinations = line == 1 and colCombinations or rowCombinations
    local allPerpendicularWorkingLineCombinations = line == 1 and allCombinationsCols or allCombinationsRows

    local function backtracking()
        local function backtrackingApplyConfirmedFieldsToLine(fields, index)
            local step = {}
            local undo = {}

            if line == 1 then
                for i, value in ipairs(fields) do
                    if nonogram.matrixState[(index - 1) * nonogram.dimensions[2] + i] ~= value then
                        table.insert(undo, i)

                        nonogram.matrixState[(index - 1) * nonogram.dimensions[2] + i] = value

                        table.insert(step, {
                            row = index,
                            col = i,
                            action = value,
                        })

                        numOfMarked = numOfMarked + (value == NonogramFieldState.Marked and 1 or 0)
                    end
                end
            else
                for i, value in ipairs(fields) do
                    if nonogram.matrixState[(i - 1) * nonogram.dimensions[2] + index] ~= value then
                        table.insert(undo, i)

                        nonogram.matrixState[(i - 1) * nonogram.dimensions[2] + index] = value

                        table.insert(step, {
                            row = i,
                            col = index,
                            action = value,
                        })

                        numOfMarked = numOfMarked + (value == NonogramFieldState.Marked and 1 or 0)
                    end
                end
            end

            if #step > 0 then
                if stepsFullPath then
                    table.insert(stepsFullPath, step)

                    currentSteps = currentSteps + 1
                    if currentSteps > maxSteps then
                        stepsFullPath = nil
                    end
                end
                table.insert(stepsSolutionPath, step)
            end
            table.insert(undoHistoryNonogram, undo)
        end

        local function clearTheCombinationsForLine(currentLine)
            local undo = {}

            for j = #currentLine.combinations, 1, -1 do
                table.insert(undo, currentLine.combinations[j].index)

                table.remove(currentLine.combinations, j)
            end

            table.insert(undoHistoryCombinations, undo)
        end

        local function backtrackingRemoveImpossibleOptionsFromCombinations(changedLine, index, allLineHints)
            local undo = {}
            local solutionPossible = true

            for i, changedLineField in ipairs(changedLine) do
                if #allPerpendicularWorkingLineCombinations[i].combinations == 0 then
                    goto continue
                end

                local combinationsToRemove = {
                    index = i,
                    combinationIds = {}
                }
                for j = #allPerpendicularWorkingLineCombinations[i].combinations, 1, -1 do
                    if getFieldInCombination(index, allPerpendicularWorkingLineCombinations[i].combinations[j].combination.combination, allLineHints[i]) ~= changedLineField then
                        table.insert(combinationsToRemove.combinationIds, {
                                index = j,
                                id = allPerpendicularWorkingLineCombinations[i].combinations[j].index
                            }
                        )

                        table.remove(allPerpendicularWorkingLineCombinations[i].combinations, j)
                    end
                end

                if #combinationsToRemove.combinationIds > 0 then
                    table.insert(undo, combinationsToRemove)
                end

                if #allPerpendicularWorkingLineCombinations[i].combinations == 0 then
                    solutionPossible = false
                    break
                end
                ::continue::
            end

            table.insert(undoHistoryCombinationsForwardCheck, undo)

            return solutionPossible
        end

        local function restoreNonogramState(currentLine)
            local step = {}

            local nonogramChange = table.remove(undoHistoryNonogram)

            local index = currentLine.index

            for _, changedField in ipairs(nonogramChange) do
                if line == 1 then
                    if nonogram.matrixState[(index - 1) * nonogram.dimensions[2] + changedField] == NonogramFieldState.Marked then
                        numOfMarked = numOfMarked - 1
                    end

                    table.insert(step, 1, {
                        row = index,
                        col = changedField,
                        action = NonogramFieldState.Empty,
                    })

                    nonogram.matrixState[(index - 1) * nonogram.dimensions[2] + changedField] = NonogramFieldState.Empty
                else
                    if nonogram.matrixState[(changedField - 1) * nonogram.dimensions[2] + index] == NonogramFieldState.Marked then
                        numOfMarked = numOfMarked - 1
                    end

                    table.insert(step, 1, {
                        row = changedField,
                        col = index,
                        action = NonogramFieldState.Empty,
                    })

                    nonogram.matrixState[(changedField - 1) * nonogram.dimensions[2] + index] = NonogramFieldState.Empty
                end
            end

            if stepsFullPath and #step > 0 then
                table.insert(stepsFullPath, step)

                currentSteps = currentSteps + 1
                if currentSteps > maxSteps then
                    stepsFullPath = nil
                end
            end
        end

        local function restoreRemovedLineCombinations(currentLine)
            local lineCombinationsChange = table.remove(undoHistoryCombinations)

            local index = currentLine.index

            for _, removedCombinationId in ipairs(lineCombinationsChange) do
                table.insert(currentLine.combinations, 1, {
                    index = removedCombinationId,
                    combination = allLineCombinations[index].combinations[removedCombinationId]
                })
            end
        end

        local function restoreRemovedForwardCheckCombinations()
            local forwardCheckCombinationChange = table.remove(undoHistoryCombinationsForwardCheck)

            for _, removedCombination in ipairs(forwardCheckCombinationChange) do
                local index = removedCombination.index
                for i = #removedCombination.combinationIds, 1, -1 do
                    table.insert(allPerpendicularWorkingLineCombinations[index].combinations, removedCombination.combinationIds[i].index, {
                        index = removedCombination.combinationIds[i].id,
                        combination = allPerpendicularLineCombinations[index].combinations[removedCombination.combinationIds[i].id]
                    })
                end
            end
        end

        -- Minimum Remaining Values
        local function findNextLineToChange()
            local currentLine = nil

            table.sort(sortedCombinations.allCombinations,
                function (a, b)
                    return #a.combinations < #b.combinations or #a.combinations == #b.combinations and a.index < b.index
                end
            )

            for _, lineCombinations in ipairs(sortedCombinations.allCombinations) do
                if #lineCombinations.combinations > 0 then
                    currentLine = lineCombinations
                    break
                end
            end

            return currentLine
        end

        local currentLine = findNextLineToChange()

        if not currentLine then
            return nonogram:isSolved()
        end

        for _, lineComb in ipairs(currentLine.combinations) do
            if quitChannel:peek() then
                error("ABORT")
            end

            local currentCombination = getLineFromCombination(line, currentLine.index, lineComb.combination, lineHints[currentLine.index], allLineCombinations[currentLine.index])

            backtrackingApplyConfirmedFieldsToLine(currentCombination, currentLine.index) -- nonogram changed, and previous state recorded

            if numOfMarked == totalNumOfMarked and nonogram:isSolved() then
                return true
            end
            clearTheCombinationsForLine(currentLine) -- since this current combination is chosen, others are removed from the domain, and the removed combinations are recorded

            if backtrackingRemoveImpossibleOptionsFromCombinations(currentCombination, currentLine.index, perpendicularLineHints) and numOfMarked < totalNumOfMarked and backtracking() then -- impossible combinations are removed from perpendicular lines. if a line is left with no options - backtrack
                return true
            end

            -- undo all changes
            restoreRemovedForwardCheckCombinations()
            restoreRemovedLineCombinations(currentLine)
            restoreNonogramState(currentLine)

            table.remove(stepsSolutionPath)
        end

        return false
    end

    solved = backtracking()
    print("Backtracking time: ", love.timer.getTime() - testStartTime)

    return solved
end

if success then
    local solved
    success, solved = pcall(function () return findSolution() end)

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
else
    print(rowCombinations)
    outputChannel:push(false)
end

stepsFullPath = nil
stepsSolutionPath = nil
collectgarbage()