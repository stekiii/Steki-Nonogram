local Scene = require 'scenes.Scene'
local Button = require 'gui.Button'
local CreateNonogramScene = require 'scenes.CreateNonogramScene'
local OptionsMenu = require 'scenes.OptionsMenu'
local SelectMenu = require 'scenes.SelectMenu'

local texturePaths = TEXTURE_PATHS
local backgroundImage, quad

local time = 0
local xOffset, yOffset = 0, 0
local scrollSpeedX = 20
local scrollSpeedY = scrollSpeedX * 9 / 16
local width, height = love.graphics.getDimensions()
local imageWidth, imageHeight

TitleScene = Scene:new{
    titleText = {},
    buttons = {},
    titleFont = nil,
    buttonFont = nil,
    mousePosition = {}
}

function TitleScene:new(o)
    o = o or {}

    o.titleText = o.titleText or {}
    o.buttons = o.buttons or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function TitleScene:loadGraphicElements()
    love.graphics.setBackgroundColor(239/255, 220/255, 186/255)

    self.titleFont = love.graphics.newFont(NONOGRAM_TITLE_FONT, NONOGRAM_TITLE_FONT_SIZE, "mono")
    self.titleFont:setFilter("nearest", "nearest")

    self.titleText = {
        {{ 0, 0, 0 }, "NONOGRAM\nSTEKI"},
        self.titleFont,
        0,
        35,
        SCREEN_WIDTH,
        "center"
    }

    self.buttonFont = love.graphics.newFont(NONOGRAM_BUTTON_FONT, NONOGRAM_BUTTON_FONT_SIZE, "mono")
    self.buttonFont:setFilter("nearest", "nearest")

    table.insert(
        self.buttons,
        Button:new{
            position = { 92, 185 },
            text = "PLAY",
            font = self.buttonFont,
            fontColor1 = { 0, 0, 0 },
            fontColor2 = { 85/255, 190/255, 234/255 },
            texture1 = texturePaths.titleButton10,
            texture2 = texturePaths.titleButton11,
            pressFunction = function ()
                -- Game:loadScene(NonogramScene:new{ filePath = NONOGRAM_FOLDER_PATH .. "test2.txt"})
                Game:loadScene(SelectMenu:new{})
            end,
            border = NONOGRAM_BUTTON_BORDER
        }
    )

    table.insert(
        self.buttons,
        Button:new{
            position = { 353, 185 },
            text = "CREATE",
            font = self.buttonFont,
            fontColor1 = { 0, 0, 0 },
            fontColor2 = { 151/255, 232/255, 118/255 },
            texture1 = texturePaths.titleButton20,
            texture2 = texturePaths.titleButton21,
            pressFunction = function ()
                -- Game:loadScene(NonogramScene:new{ filePath = NONOGRAM_FOLDER_PATH .. "test2.txt"})
                Game:loadScene(CreateNonogramScene:new{})
            end,
            border = NONOGRAM_BUTTON_BORDER
        }
    )

    table.insert(
        self.buttons,
        Button:new{
            position = { 353, 272 },
            text = "EXIT",
            font = self.buttonFont,
            fontColor1 = { 0, 0, 0 },
            fontColor2 = { 229/255, 96/255, 109/255 },
            texture1 = texturePaths.titleButton30,
            texture2 = texturePaths.titleButton31,
            pressFunction = function ()
                love.event.quit()
            end,
            border = NONOGRAM_BUTTON_BORDER
        }
    )

    table.insert(
        self.buttons,
        Button:new{
            position = { 92, 272 },
            text = "OPTIONS",
            font = self.buttonFont,
            fontColor1 = { 0, 0, 0 },
            fontColor2 = { 185/255, 118/255, 232/255 },
            texture1 = texturePaths.titleButton40,
            texture2 = texturePaths.titleButton41,
            pressFunction = function ()
                Game:loadScene(OptionsMenu:new{ overlaidScene = self })
            end,
            border = NONOGRAM_BUTTON_BORDER
        }
    )

    backgroundImage = love.graphics.newImage(texturePaths.titleBackgroundSmall)
    backgroundImage:setFilter("nearest", "nearest")
    backgroundImage:setWrap("repeat", "repeat")
    imageWidth, imageHeight = backgroundImage:getDimensions()

    quad = love.graphics.newQuad(0, 0, width, height, backgroundImage:getDimensions())

    time = 0
end

function TitleScene:update(dt)
    xOffset, yOffset = xOffset + (scrollSpeedX * dt), yOffset + (scrollSpeedY * dt)

    if xOffset >= imageWidth then
        xOffset = xOffset - imageWidth
    end
    if yOffset >= imageHeight then
        yOffset = yOffset - imageHeight
    end

    quad:setViewport(xOffset, yOffset, width, height)
end

function TitleScene:handleMousePress(x, y, button)
    if button == 1 then
        for _, b in ipairs(self.buttons) do
            if b:isClicked({ x, y }) then
                b:handleMousePress(x, y, button)
                return
            end
        end
    end
end

function TitleScene:handleMouseRelease(x, y, button)
    if button == 1 then
        for _, b in ipairs(self.buttons) do
            if b:isClicked({ x, y }) then
                b:handleMouseRelease(x, y, button)
            end
            b.marked = false
        end
    end
end

function TitleScene:handleMouseMove(x, y)
    -- self.mousePosition[1], self.mousePosition[2] = x, y
    for _, button in ipairs(self.buttons) do
        button.hovered = button:isClicked({ x, y })
    end
end

function TitleScene:draw()
    love.graphics.draw(backgroundImage, quad)

    love.graphics.printf(unpack(self.titleText))

    for _, button in ipairs(self.buttons) do
        button:draw()
    end
end

return TitleScene