Solver =
{
    initialInputChannel = love.thread.getChannel("in"),
    inputChannel = love.thread.getChannel("in_"),
    outputChannel = love.thread.getChannel("out_"),
    quitChannel = love.thread.getChannel("quit_"),
    thead = nil,
    currentSolverIndex = 1,
    solved = -1, -- -1 not executed yet, 0 failed, 1 succeeded
    steps = {},
    executionTime = 0
}
--[[
steps format

step =
{
    changes = {}
}

change = {
    row = 1,
    col = 1,
    action = NonogramFieldState.Empty
}
--]]

SolverSourceList = {
    {
        name = "CSP / Combinations",
        file = "solvers/csp.lua"
    },
    {
        name = "DFS",
        file = "solvers/dfs.lua"
    },
    -- {
    --     name = "Simple DFS",
    --     file = "solvers/dfs_old.lua"
    -- }
}

function Solver:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function Solver:start(nonogram, sceneHash)
    if not self:isRunning() then
        self.solved = -1

        self.initialInputChannel:push(sceneHash)

        self.inputChannel = love.thread.getChannel("in_" .. sceneHash)
        self.outputChannel = love.thread.getChannel("out_" .. sceneHash)
        self.quitChannel = love.thread.getChannel("quit_" .. sceneHash)

        self.inputChannel:push(nonogram)
        self.thread = love.thread.newThread(SolverSourceList[self.currentSolverIndex].file)
        self.thread:start()
    end
end

function Solver:reset()
    self.solved = -1
    self.thread = nil
end

function Solver:checkFinished()
    if self.solved ~= -1 then
        return true
    end

    local solved = self.outputChannel:pop()
    if solved ~= nil then
        self.solved = solved and 1 or 0
        self.steps = self.outputChannel:pop()
        self.executionTime = self.outputChannel:pop()
        self.thread = nil

        return true
    end

    return false
end

function Solver:isSolved()
    return self.solved == 1
end

function Solver:getSteps()
    return self.steps
end

function Solver:getCurrentSolver()
    return SolverSourceList[self.currentSolverIndex]
end

function Solver:isRunning()
    return self.thread ~= nil
end

function Solver:nextSolver()
    if self:isRunning() then
        return
    end

    self.currentSolverIndex = self.currentSolverIndex % #SolverSourceList + 1
end

function Solver:previousSolver()
    if self:isRunning() then
        return
    end

    self.currentSolverIndex = (self.currentSolverIndex + #SolverSourceList - 2) % #SolverSourceList + 1
end

function Solver:quit()
    if self:isRunning() then
        self.quitChannel:push(true)
    end
end

return Solver