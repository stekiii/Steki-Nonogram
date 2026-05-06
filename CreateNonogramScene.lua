local NonogramScene = require 'NonogramScene'
local defaultDimensions = 3

CreateNonogramScene = NonogramScene:new{
    nonogram = {},
    buttons = {}
}

local newImage = love.graphics.newImage

function CreateNonogramScene:new(o)
    o = o or {}

    o.nonogram = o.nonogram or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function CreateNonogramScene:initialize()
    self.nonogram = Nonogram:new{
        dimensions = { defaultDimensions, defaultDimensions }
    }

    self.buttons.plusButtonRows = Button:new{
        position = { 27, 36 },
        texture1 = TEXTURE_PATHS.plusButton,
        pressFunction = function ()
            self:changeSize(self.nonogram.dimensions[1] + 1, self.nonogram.dimensions[2])
        end
    }

    self.buttons.minusButtonRows = Button:new{
        position = { 27, 109 },
        texture1 = TEXTURE_PATHS.minusButton,
        pressFunction = function ()
            self:changeSize(self.nonogram.dimensions[1] == 1 and 1 or self.nonogram.dimensions[1] - 1, self.nonogram.dimensions[2])
        end
    }

    self.buttons.plusButtonColumns = Button:new{
        position = { 27, 210 },
        texture1 = TEXTURE_PATHS.plusButton,
        pressFunction = function ()
            self:changeSize(self.nonogram.dimensions[1], self.nonogram.dimensions[2] + 1)
        end
    }

    self.buttons.minusButtonColumns = Button:new{
        position = { 27, 282 },
        texture1 = TEXTURE_PATHS.minusButton,
        pressFunction = function ()
            self:changeSize(self.nonogram.dimensions[1], self.nonogram.dimensions[2] == 1 and 1 or self.nonogram.dimensions[2] - 1)
        end
    }

    self:loadGraphicElements()
end

function CreateNonogramScene:changeSize(rows, columns)
    local oldRows, oldColumns = self.nonogram.dimensions[1], self.nonogram.dimensions[2]
    self.nonogram.dimensions[1], self.nonogram.dimensions[2] = rows, columns

    if columns > oldColumns then
        for j = 1, columns - oldColumns, 1 do
            for i = 1, oldRows, 1 do
                table.insert(self.nonogram.matrixState, (i - 1) * columns + oldColumns + j, 0)
            end
            table.insert(self.nonogram.columnHints, {})
        end
        
    elseif columns < oldColumns then
        for j = oldColumns - columns, 1, -1 do
            for i = oldRows, 1, -1 do
                table.remove(self.nonogram.matrixState, (i - 1) * oldColumns + columns + j)
            end
            table.remove(self.nonogram.columnHints, columns + j)
        end

        for _, val in ipairs(self.nonogram.matrixState) do
            print(val)
        end
        print()
    end

    if rows > oldRows then
        for i = 1, rows - oldRows, 1 do
            for j = 1, columns, 1 do
                table.insert(self.nonogram.matrixState, (oldRows + i - 1) * columns + j, 0)
            end
            table.insert(self.nonogram.rowHints, {})
        end
    elseif rows < oldRows then
        for i = rows - oldRows, 1, -1 do
            for j = columns, 1, -1 do
                table.remove(self.nonogram.matrixState, (rows + i - 1) * columns + j)
            end
            table.remove(self.nonogram.rowHints, rows + i)
        end
    end

    self:loadGraphicElements()
end

function CreateNonogramScene:draw()
    NonogramScene.draw(self)

    -- for _, button in pairs(self.buttons) do
    --     button:draw()
    -- end
end



return CreateNonogramScene