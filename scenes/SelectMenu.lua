local Scene = require 'scenes.Scene'
local NonogramScene = require 'scenes.NonogramScene'
local Image = require 'gui.Image'
local math = math

local texturePaths = TEXTURE_PATHS

local selectMenuImage
local backgroundImage, quad, imageWidth, imageHeight
local scrollSpeedX = -10
local scrollSpeedY = -20
local width, height = love.graphics.getDimensions()
local xOffset, yOffset = 0, 0

local scrollOffset, maxScrollOffset, minScrollOffset = { 0, 0 }, 0, 0
local scrollSpeed, maxScrollSpeed, minScrollSpeed, scrollSpeedIncrease, scrollSpeedDeceleration = 0, 1400, 0.1, 500, 15

SelectMenu = Scene:new{
    currentFolder = NONOGRAM_FOLDER_PATH,
    initialPosition = { 68, 30 },
    spacing = { 175, 75 },
    buttonsInRow = 3,
    currentButtonIndex = 0,
    buttons = {},
    font = {}
}

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
            if b:isClicked({ x, y }, 1, b ~= self.buttons.backButton and scrollOffset or nil) then
                b:handleMousePress(x, y, button)
                return
            end
        end
    end
end

function SelectMenu:handleMouseRelease(x, y, button)
    if button == 1 then
        for _, b in pairs(self.buttons) do
            if b:isClicked({ x, y }, 1, b ~= self.buttons.backButton and scrollOffset or nil) then
                b:handleMouseRelease(x, y, button)
            end
            b.marked = false
        end
    end
end

function SelectMenu:handleMouseMove(x, y)
    for _, button in pairs(self.buttons) do
        button.hovered = button:isClicked({ x, y }, 1, button ~= self.buttons.backButton and scrollOffset or nil)
    end
end

function SelectMenu:handleMouseWheel(x, y)
    if scrollSpeed <= 0 and y > 0 or scrollSpeed >= 0 and y < 0 then
        scrollSpeed = 0
    end

    scrollSpeed = scrollSpeed + y * scrollSpeedIncrease

    scrollSpeed = y < 0 and
        math.max(-maxScrollSpeed, scrollSpeed) or
        math.min(maxScrollSpeed, scrollSpeed)
end

function SelectMenu:draw()
    love.graphics.draw(backgroundImage, quad)

    selectMenuImage:draw()

    love.graphics.push()

    love.graphics.translate(0, scrollOffset[2])

    for _, button in pairs(self.buttons) do
        if button ~= self.buttons.backButton then
            button:draw()
        end
    end

    love.graphics.pop()

    self.buttons.backButton:draw()
end

function SelectMenu:makeButton(path, type, text)
    table.insert(self.buttons, Button:new{
        position = {
            self.initialPosition[1] + self.spacing[1] * math.fmod(self.currentButtonIndex, self.buttonsInRow),
            self.initialPosition[2] + self.spacing[2] * math.floor(self.currentButtonIndex / self.buttonsInRow)
        },
        texture1 = type == "directory" and texturePaths.selectButtonFolderBig or texturePaths.selectButtonFileBig,
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
        self:makeButton(str, "directory", "..")
    end

    for _, folder in ipairs(folderList) do
        self:makeButton(folder[1], "directory", folder[2])
    end
    for _, file in ipairs(fileList) do
        self:makeButton(file[1], "file", string.sub(file[2], 1, string.len(file[2]) - 4))
    end

    scrollOffset[2] = 0
    maxScrollOffset = 360 - (self.initialPosition[2] * 2 + self.spacing[2] * math.floor((self.currentButtonIndex - 1) / self.buttonsInRow) + Scene:getTexture(texturePaths.selectButtonFileBig):getPixelHeight())
    maxScrollOffset = math.min(maxScrollOffset, 0)

    self.buttons.backButton = Button:new{
        position = { 587, 10 },
        texture1 = texturePaths.backButton,
        pressFunction = function ()
            Game:loadScene(TitleScene:new{})
        end
    }

    selectMenuImage = Image:new({
        position = { 0, 0 },
        texture = texturePaths.selectMenu
    })

    backgroundImage = love.graphics.newImage(texturePaths.selectMenuBackgroundSmall)
    backgroundImage:setFilter("nearest", "nearest")
    backgroundImage:setWrap("repeat", "repeat")
    imageWidth, imageHeight = backgroundImage:getDimensions()

    quad = love.graphics.newQuad(0, 0, width, height, backgroundImage:getDimensions())
end

function SelectMenu:update(dt)
    if scrollSpeed ~= 0 then
        local nextScrollSpeed = scrollSpeed * (1 - scrollSpeedDeceleration * dt)

        scrollOffset[2] = scrollOffset[2] + (scrollSpeed + nextScrollSpeed) * dt / 2
        scrollOffset[2] = math.max(maxScrollOffset, scrollOffset[2])
        scrollOffset[2] = math.min(minScrollOffset, scrollOffset[2])

        scrollSpeed = math.abs(nextScrollSpeed) > minScrollSpeed and nextScrollSpeed or 0
    end

    xOffset, yOffset = xOffset + (scrollSpeedX * dt), yOffset + (scrollSpeedY * dt)

    if xOffset >= imageWidth then
        xOffset = xOffset - imageWidth
    end
    if yOffset >= imageHeight then
        yOffset = yOffset - imageHeight
    end

    quad:setViewport(xOffset, yOffset, width, height)
end


return SelectMenu