local NonogramScene = require 'scenes.NonogramScene'
local Image = require 'gui.Image'
local defaultDimensions = 3

local texturePaths = TEXTURE_PATHS

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

    self.font = love.graphics.newFont(NONOGRAM_SELECT_MENU_FONT, NONOGRAM_SAVE_BUTTON_FONT_SIZE, "mono")
    self.font:setFilter("nearest", "nearest")

    self.buttons.plusButtonRows = Button:new{
        position = { 93, 86 },
        texture1 = texturePaths.plusButtonSmall,
        pressFunction = function ()
            self:changeSize(self.nonogram.dimensions[1] + 1, self.nonogram.dimensions[2])
        end
    }

    self.buttons.minusButtonRows = Button:new{
        position = { 33, 86 },
        texture1 = texturePaths.minusButtonSmall,
        pressFunction = function ()
            self:changeSize(self.nonogram.dimensions[1] == 1 and 1 or self.nonogram.dimensions[1] - 1, self.nonogram.dimensions[2])
        end
    }

    self.buttons.plusButtonColumns = Button:new{
        position = { 93, 272 },
        texture1 = texturePaths.plusButtonSmall,
        pressFunction = function ()
            self:changeSize(self.nonogram.dimensions[1], self.nonogram.dimensions[2] + 1)
        end
    }

    self.buttons.minusButtonColumns = Button:new{
        position = { 33, 272 },
        texture1 = texturePaths.minusButtonSmall,
        pressFunction = function ()
            self:changeSize(self.nonogram.dimensions[1], self.nonogram.dimensions[2] == 1 and 1 or self.nonogram.dimensions[2] - 1)
        end
    }

    self.menuImage = Image:new{
        position = { 20, 20 },
        texture = texturePaths.createrScreenMenu
    }


    self.buttons.saveButton =
        Button:new{
            position = { 508, 272 },
            text = "Save",
            font = self.font,
            fontColor1 = { 0, 0, 0 },
            texture1 = texturePaths.saveButton0,
            texture2 = texturePaths.saveButton1,
            pressFunction = function ()
                self:saveNonogram()
                Game:loadScene(TitleScene:new{})
            end,
            border = NONOGRAM_BUTTON_BORDER
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
    end

    if rows > oldRows then
        for i = 1, rows - oldRows, 1 do
            for j = 1, columns, 1 do
                table.insert(self.nonogram.matrixState, (oldRows + i - 1) * columns + j, 0)
            end
            table.insert(self.nonogram.rowHints, {})
        end
    elseif rows < oldRows then
        for i = oldRows - rows, 1, -1 do
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
end

function CreateNonogramScene:additionalDrawingBeforeButtons()

    self.menuImage:draw()

    local texture = Game.currentScene:getTexture(self.menuImage.texture)

    local text = "Rows"
    love.graphics.print(
        { { 0, 0, 0 }, text },
        self.font,
        self.menuImage.position[1] + (texture:getPixelWidth() - self.font:getWidth(text) - NONOGRAM_BUTTON_BORDER) / 2,
        54
    )

    text = "Columns"
    love.graphics.print(
        { { 0, 0, 0 }, text },
        self.font,
        self.menuImage.position[2] + (texture:getPixelWidth() - self.font:getWidth(text) - NONOGRAM_BUTTON_BORDER) / 2,
        240
    )
end

function CreateNonogramScene:saveNonogram()
    local customNonogramDir = CUSTOM_NONOGRAM_FOLDER_PATH
    local info = love.filesystem.getInfo(customNonogramDir)

    if not info or info.type ~= "directory" then
        love.filesystem.createDirectory(customNonogramDir)
    end

    local fileName = string.format("%dx%d-", self.nonogram.dimensions[1], self.nonogram.dimensions[2]) .. os.date("%m.%y")
    local items = love.filesystem.getDirectoryItems(customNonogramDir)
    local numOfSameNameFiles = 0
    for _, item in ipairs(items) do
        if love.filesystem.getInfo(customNonogramDir .. "/" .. item).type == "file" and string.find(item, fileName, 1, true) then
            numOfSameNameFiles = numOfSameNameFiles + 1
        end
    end

    if numOfSameNameFiles > 0 then
        local newFileName = fileName .. string.format(" (%d)", numOfSameNameFiles)
        while love.filesystem.getInfo(customNonogramDir .. "/" .. newFileName .. ".txt") ~= nil do
            numOfSameNameFiles = numOfSameNameFiles + 1
            newFileName = fileName .. string.format(" (%d)", numOfSameNameFiles)
        end
        fileName = newFileName
    end

    fileName = fileName .. ".txt"

    for i = 1, #self.nonogram.matrixState do
        if self.nonogram.matrixState[i] == 2 then
            self.nonogram.matrixState[i] = 0
        end
    end

    local success, message = love.filesystem.write(
        customNonogramDir .. "/" .. fileName,
        string.format(
            "%d,%d\n",
            self.nonogram.dimensions[1],
            self.nonogram.dimensions[2]
        ) ..
        table.concat(self.nonogram.matrixState)
    )
    
    if not success then
        print(message)
    end

end

return CreateNonogramScene