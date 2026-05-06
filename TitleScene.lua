local Scene = require 'Scene'
local Button = require 'Button'
local CreateNonogramScene = require 'CreateNonogramScene'
local OptionsMenu = require 'OptionsMenu'
local SelectMenu = require 'SelectMenu'

local texturePaths = TEXTURE_PATHS

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
    self.titleFont:setFilter("nearest")

    self.titleText = {
        {{ 0, 0, 0 }, "NONOGRAM\nSTEKI"},
        self.titleFont,
        0,
        35,
        SCREEN_WIDTH,
        "center"
    }

    self.buttonFont = love.graphics.newFont(NONOGRAM_BUTTON_FONT, NONOGRAM_BUTTON_FONT_SIZE, "mono")
    self.buttonFont:setFilter("nearest")

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
    love.graphics.printf(unpack(self.titleText))

    for _, button in ipairs(self.buttons) do
        button:draw()
    end
end

return TitleScene