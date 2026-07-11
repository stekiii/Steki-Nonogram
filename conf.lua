local textureFolderPath = "textures/"
local fontsFolderPath = "fonts/"

TEXTURE_PATHS = {
    field1 = textureFolderPath .. "field1.png",
    field2 = textureFolderPath .. "field2.png",
    field3 = textureFolderPath .. "field3.png",
    field4 = textureFolderPath .. "field4.png",
    hoverfield1 = textureFolderPath .. "hoverfield1.png",
    hoverfield2 = textureFolderPath .. "hoverfield2.png",
    hoverfield3 = textureFolderPath .. "hoverfield3.png",
    hoverfield4 = textureFolderPath .. "hoverfield4.png",
    mark = textureFolderPath .. "mark.png",
    cross = textureFolderPath .. "cross.png",
    hintFieldRow = textureFolderPath .. "hintRow.png",
    hintFieldColumn = textureFolderPath .. "hintColumn.png",
    fillField1 = textureFolderPath .. "fillField1.png",
    fillField2 = textureFolderPath .. "fillField2.png",
    fillField3 = textureFolderPath .. "fillField3.png",
    fillField4 = textureFolderPath .. "fillField4.png",
    exitButton = textureFolderPath .. "exitButton.png",
    titleButton10 = textureFolderPath .. "button10.png",
    titleButton11 = textureFolderPath .. "button11.png",
    titleButton20 = textureFolderPath .. "button20.png",
    titleButton21 = textureFolderPath .. "button21.png",
    titleButton30 = textureFolderPath .. "button30.png",
    titleButton31 = textureFolderPath .. "button31.png",
    titleButton40 = textureFolderPath .. "button40.png",
    titleButton41 = textureFolderPath .. "button41.png",
    optionsMenu = textureFolderPath .. "optionsMenu.png",
    optionsMenuButton0 = textureFolderPath .. "optionsMenuButton0.png",
    optionsMenuButton1 = textureFolderPath .. "optionsMenuButton1.png",
    optionsMenuExit0 = textureFolderPath .. "optionsMenuExit0.png",
    optionsMenuExit1 = textureFolderPath .. "optionsMenuExit1.png",
    selectButtonFolder = textureFolderPath .. "selectButtonFolder.png",
    selectButtonFile = textureFolderPath .. "selectButtonFile.png",
    plusButton = textureFolderPath .. "plusButton.png",
    minusButton = textureFolderPath .. "minusButton.png",
    plusButtonSmall = textureFolderPath .. "plusButtonSmall.png",
    minusButtonSmall = textureFolderPath .. "minusButtonSmall.png",
    backButton = textureFolderPath .. "backButton.png",
    saveButton0 = textureFolderPath .. "saveButton0.png",
    saveButton1 = textureFolderPath .. "saveButton1.png",
    createrScreenMenu = textureFolderPath .. "createScreenMenu.png",
    solved = textureFolderPath .. "solved.png"
}

FONTS_PATHS = {
    hv = fontsFolderPath .. "HomeVideo-BLG6G.ttf",
    hvb = fontsFolderPath .. "HomeVideoBold-R90Dv.ttf",
    ka1 = fontsFolderPath .. "ka1.ttf",
    kf = fontsFolderPath .. "Karma Future.otf",
    ks = fontsFolderPath .. "Karma Suture.otf",
    pb = fontsFolderPath .. "Pixeboy-z8XGD.ttf",
    vati = fontsFolderPath .. "Vaticanus-G3yVG.ttf",
    mono = fontsFolderPath .. "monogram.ttf",
    ch = fontsFolderPath .. "charybdis.regular.ttf",
    om = fontsFolderPath .. "origami-mommy.regular.ttf"
}

DEFAULT_WIDTH = 640
DEFAULT_HEIGHT = 360
SCREEN_WIDTH = 0
SCREEN_HEIGHT = 0
WINDOW_WIDTH = 0
WINDOW_HEIGHT = 0
MAX_WINDOW_WIDTH = 0
MAX_WINDOW_HEIGHT = 0

FULLSCREEN = false

NONOGRAM_FOLDER_PATH = "nonograms"
CUSTOM_NONOGRAM_FOLDER_PATH = NONOGRAM_FOLDER_PATH .. "/Custom Nonograms"

NONOGRAM_SCALE_INCREMENT = 0.15

NONOGRAM_FIELD_OFFSET = 5
NONOGRAM_FIELD_BORDER = 2

NONOGRAM_HINT_FIELD_CONSTANTS = {
    NONOGRAM_HINT_ALIGNMENT = 8,
    NONOGRAM_FIELD_AND_HINT_ALIGNMENT = 9,
    NONOGRAM_HINT_FIELD_OFFSET = 12,
    -- NONOGRAM_HINT_FIELD_INITIAL_OFFSET = 8,
    NONOGRAM_HINT_FONT_SIZE = 40,
    -- NONOGRAM_HINT_FIELD_SCALE = 1,
    -- NONOGRAM_HINT_FIELD_Y_OFFSET = 6,
    -- NONOGRAM_HINT_FIELD_X_OFFSET = 2,
    NONOGRAM_HINT_FIELD_BORDER = 3,
    NONOGRAM_HINT_FIELD_FONT = FONTS_PATHS.ks
}

NONOGRAM_FILL_FIELD_OFFSET = 12
NONOGRAM_FILL_ALIGNMENT = 9

NONOGRAM_TITLE_FONT = FONTS_PATHS.om
-- NONOGRAM_TITLE_FONT_SIZE = 58
NONOGRAM_TITLE_FONT_SIZE = 64
NONOGRAM_BUTTON_FONT = FONTS_PATHS.ka1
NONOGRAM_BUTTON_FONT_SIZE = 31
NONOGRAM_BUTTON_BORDER = 4

NONOGRAM_SAVE_BUTTON_FONT_SIZE = 18

NONOGRAM_OPTIONS_FONT = FONTS_PATHS.ks
NONOGRAM_OPTIONS_FONT_SIZE = 31

NONOGRAM_SELECT_MENU_FONT = FONTS_PATHS.ks
NONOGRAM_SELECT_MENU_FONT_SIZE = 16

function love.conf(t)
    -- t.identity = "saves"
    -- t.window.vsync = 1
    t.window.title = "Nonogram Steki"
end