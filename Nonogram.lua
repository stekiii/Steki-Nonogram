Nonogram = {
    dimensions = {},
    rowHints = {},
    columnHints = {},
    matrixState = {},
    solution = {}
}

function Nonogram:new(o)
    o = o or {}

    o.dimensions = o.dimensions or {}

    if not o.rowHints then
        o.rowHints = {}
        for i = 1, o.dimensions[1], 1 do
            table.insert(o.rowHints, {})
        end
    end

    if not o.columnHints then
        o.columnHints = {}
        for i = 1, o.dimensions[2], 1 do
            table.insert(o.columnHints, {})
        end
    end

    if not o.matrixState then
        o.matrixState = {}
        for i = 1, o.dimensions[1] * o.dimensions[2], 1 do
            o.matrixState[i] = 0
        end
    end

    o.solution = o.solution or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function Nonogram:changeField(position, state)
    self.matrixState[(position[1] - 1) * self.dimensions[2] + position[2]] = state
end

function Nonogram:getState(position)
    return self.matrixState[(position[1] - 1) * self.dimensions[2] + position[2]]
end

function Nonogram:isSolved()
    local solution, attempt
    for i = 1, self.dimensions[1], 1 do
        for j = 1, self.dimensions[2], 1 do
            attempt = self.matrixState[(i - 1) * self.dimensions[2] + j]
            attempt = attempt == NonogramFieldState.Crossed and NonogramFieldState.Empty or attempt
            solution = self.solution[(i - 1) * self.dimensions[2] + j]
            if attempt ~= solution then
                return false
            end
        end
    end

    return true
end

function Nonogram:mostHintsInLine(string)
    local n = 0
    if string == "row" then
        for _, rowHint in ipairs(self.rowHints) do
            local newN = #rowHint
            n = n >= newN and n or newN
        end
    elseif string == "column" then
        for _, columnHint in ipairs(self.columnHints) do
            local newN = #columnHint
            n = n >= newN and n or newN
        end
    else
        error()
    end

    return n
end

return Nonogram