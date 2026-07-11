local Scene = require 'Scene'
local NonogramScene = require 'NonogramScene'

SelectMenu = Scene:new{
    currentFolder = NONOGRAM_FOLDER_PATH,
    initialPosition = { 134, 30 },
    spacing = { 135, 75 },
    buttonsInRow = 3,
    currentButtonIndex = 0,
    buttons = {},
    font = {}
}

local newImage = love.graphics.newImage

function SelectMenu:new(o)
    o = o or {}

    o.buttons = o.buttons or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function SelectMenu:handleMousePress(x, y, button)
    if button == 1 then
        for _, b in pairs(self.buttons) do
            if b:isClicked({ x, y }) then
                b:handleMousePress(x, y, button)
                return
            end
        end
    end
end

function SelectMenu:handleMouseRelease(x, y, button)
    if button == 1 then
        for _, b in pairs(self.buttons) do
            if b:isClicked({ x, y }) then
                b:handleMouseRelease(x, y, button)
            end
            b.marked = false
        end
    end
end

function SelectMenu:handleMouseMove(x, y)
    -- self.mousePosition[1], self.mousePosition[2] = x, y
    for _, button in pairs(self.buttons) do
        button.hovered = button:isClicked({ x, y })
    end
end

function SelectMenu:draw()
    for _, button in pairs(self.buttons) do
        button:draw()
    end
end

function SelectMenu:makeButton(path, type, text)
    table.insert(self.buttons, Button:new{
        position = {
            self.initialPosition[1] + self.spacing[1] * math.fmod(self.currentButtonIndex, self.buttonsInRow),
            self.initialPosition[2] + self.spacing[2] * math.floor(self.currentButtonIndex / self.buttonsInRow)
        },
        texture1 = type == "directory" and TEXTURE_PATHS.selectButtonFolder or TEXTURE_PATHS.selectButtonFile,
        text = text,
        font = self.font,
        fontColor1 = { 0, 0, 0 },
        fontColor2 = type == "directory" and { 204/255, 151/255, 57/255 } or { 230/255, 198/255, 140/255 },
        pressFunction = type == "directory" and
            function ()
                self.currentFolder = path
                self:loadGraphicElements()
            end or type == "file" and
            function ()
                if not pcall(function() Game:loadScene(NonogramScene:new{ filePath = path }) end) then
                    Game:returnScene(self)
                end
            end or function() error() end,
    })

    self.currentButtonIndex = self.currentButtonIndex + 1
end

function SelectMenu:loadGraphicElements()
    love.graphics.setBackgroundColor(239/255, 220/255, 186/255)

    local directoryItems = love.filesystem.getDirectoryItems(self.currentFolder)

    local folderList = {}
    local fileList = {}
    local info, path

    self.currentButtonIndex = 0
    self.buttons = {}
    self.font = love.graphics.newFont(NONOGRAM_SELECT_MENU_FONT, NONOGRAM_SELECT_MENU_FONT_SIZE, "mono")
    self.font:setFilter("nearest", "nearest")

    for _, name in ipairs(directoryItems) do
        path = self.currentFolder .. "/" .. name
        info = love.filesystem.getInfo(path)

        if info.type == "directory" then
            table.insert(folderList, { path, name })
        elseif info.type == "file" then
            table.insert(fileList, { path, name })
        end
    end

    if self.currentFolder ~= NONOGRAM_FOLDER_PATH then
        local i = string.find(self.currentFolder, "/[%w \\-.]*$") - 1
        local str = i and string.sub(self.currentFolder, 1, i) or ""
        -- print(self.currentFolder)
        -- print(i)
        -- print(str)
        self:makeButton(str, "directory", "..")
    end

    for _, folder in ipairs(folderList) do
        self:makeButton(folder[1], "directory", folder[2])
    end
    for _, file in ipairs(fileList) do
        self:makeButton(file[1], "file", string.sub(file[2], 1, string.len(file[2]) - 4))
    end

    self.buttons.backButton = Button:new{
        position = { 587, 10 },
        texture1 = TEXTURE_PATHS.backButton,
        pressFunction = function ()
            Game:loadScene(TitleScene:new{})
        end
    }
end

return SelectMenu