local OverlayScene = require 'OverlayScene'

OptionsMenu = OverlayScene:new{
    optionsMenuTexture = {},
    buttons = {},
    font = {}
}


function OptionsMenu:new(o)
    o = o or {}

    o.optionsMenuTexture = o.optionsMenuTexture or nil

    setmetatable(o, self)
    self.__index = self

    return o
end

function OptionsMenu:handleMousePress(x, y, button)
    if button == 1 then
        for _, b in pairs(self.buttons) do
            if b:isClicked({ x, y }) then
                b:handleMousePress(x, y, button)
                return
            end
        end
    end
end

function OptionsMenu:handleMouseRelease(x, y, button)
    if button == 1 then
        for _, b in pairs(self.buttons) do
            if b:isClicked({ x, y }) then
                b:handleMouseRelease(x, y, button)
            end
            b.marked = false
        end
    end
end

function OptionsMenu:handleMouseMove(x, y)
    for _, button in pairs(self.buttons) do
        button.hovered = button:isClicked({ x, y })
    end
end

function OptionsMenu:drawOnTop()
    local texture = self.optionsMenuTexture
    love.graphics.draw(texture,
        (SCREEN_WIDTH - texture:getPixelWidth()) / 2,
        (SCREEN_HEIGHT - texture:getPixelHeight()) / 2)

    for _, button in pairs(self.buttons) do
        button:draw()
    end

    local buttonTexture = self:getTexture(self.buttons.resolutionButton.texture1)

    love.graphics.printf(
        { { 1, 1, 1 }, "Resolution : " },
        self.font,
        111,
        90,
        buttonTexture:getPixelWidth(),
        "left"
    )

    love.graphics.printf(
        { { 1, 1, 1 }, WINDOW_WIDTH .. " x " .. WINDOW_HEIGHT},
        self.font,
        111,
        90,
        buttonTexture:getPixelWidth() - 56,
        "right"
    )

    buttonTexture = self:getTexture(self.buttons.fullscreenButton.texture1)

    love.graphics.printf(
        { { 1, 1, 1 }, "Fullscreen : " },
        self.font,
        111,
        178,
        buttonTexture:getPixelWidth(),
        "left"
    )

    love.graphics.printf(
        { { 1, 1, 1 }, Game.fullscreen and "ON" or "OFF"},
        self.font,
        111,
        178,
        buttonTexture:getPixelWidth() - 56,
        "right"
    )
end

function OptionsMenu:loadGraphicElements()
    self.font = love.graphics.newFont(NONOGRAM_OPTIONS_FONT, NONOGRAM_OPTIONS_FONT_SIZE, "mono")
    self.font:setFilter("nearest")

    self.optionsMenuTexture = self:getTexture(TEXTURE_PATHS.optionsMenu)
    
    table.insert(self.buttons, Button:new{
        position = { 549, 40 },
            -- {
            --     (SCREEN_WIDTH + self.optionsMenuTexture:getPixelWidth() - 3*self:getTexture(TEXTURE_PATHS.cross):getPixelWidth()) / 2,
            --     (SCREEN_HEIGHT - self.optionsMenuTexture:getPixelHeight() + self:getTexture(TEXTURE_PATHS.cross):getPixelWidth()) / 2
            -- },
        texture1 = TEXTURE_PATHS.optionsMenuExit0,
        texture2 = TEXTURE_PATHS.optionsMenuExit1,
        pressFunction = function ()
            Game:returnScene(self.overlaidScene)
        end
    })

    self.buttons.resolutionButton = Button:new{
        position = { 83, 75 },
        texture1 = TEXTURE_PATHS.optionsMenuButton0,
        texture2 = TEXTURE_PATHS.optionsMenuButton1,
        pressFunction = function ()
            -- if Game.fullscreen then
            --     Game:toggleFullscreen()
            -- end
            local newScale = Game.gameScale + 0.5

            if SCREEN_WIDTH * newScale > MAX_WINDOW_WIDTH then
                newScale = 1
            end

            Game:resize(newScale * SCREEN_WIDTH, newScale * SCREEN_HEIGHT)
        end
    }

    self.buttons.fullscreenButton = Button:new{
        position = { 83, 163 },
        texture1 = TEXTURE_PATHS.optionsMenuButton0,
        texture2 = TEXTURE_PATHS.optionsMenuButton1,
        pressFunction = function ()
            Game:toggleFullscreen()
        end
    }

end

return OptionsMenu