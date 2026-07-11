local math = math

Animation = {
    graphicElement = {},
    initialPosition = {},
    goalPosition = {},
    movementFunctionX =
        function(...)

        end,
    movementFunctionY =
        function (...)
            
        end,
    movementFunctionParametersX = {},
    movementFunctionParametersY = {},
    running = false,

    currentTime = 0,
    animationTime = 0
}

function Animation:new(o)
    o = o or {}

    o.initialPosition = { o.graphicElement.position[1], o.graphicElement.position[2] }
    o.animationTime = o.animationTime or 1

    setmetatable(o, self)
    self.__index = self

    return o
end

function Animation:update(dt)
    if not self.running then
        return
    end

    self.currentTime = math.min(self.currentTime + dt, self.animationTime)
    
    self:updateGraphicElementPosition()

    if self.currentTime >= self.animationTime then
        self.running = false
    end
end

function Animation:draw()
    self.graphicElement:draw()
end

function Animation:updateGraphicElementPosition()
    if self.movementFunctionX ~= Animation.movementFunctionX then
        self.graphicElement.position[1] = self.initialPosition[1] + (self.goalPosition[1] - self.initialPosition[1]) * self.movementFunctionX(self.currentTime / self.animationTime, unpack(self.movementFunctionParametersX))
    end

    if self.movementFunctionY ~= Animation.movementFunctionY then
        self.graphicElement.position[2] = self.initialPosition[2] + (self.goalPosition[2] - self.initialPosition[2]) * self.movementFunctionY(self.currentTime / self.animationTime, unpack(self.movementFunctionParametersY))
    end
end

function Animation:start()
    if not self.running then
        self.graphicElement.position = { self.initialPosition[1], self.initialPosition[2] }
        self.currentTime = 0
        self.running = true
    end
end

function Animation:isRunning()
    return self.running
end

return Animation