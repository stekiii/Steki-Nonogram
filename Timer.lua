Timer =
{
    started = false,
    goalTime = 1,
    currTime = 0,
    repetitions = 1,
    timesFinished = 0
}

function Timer:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function Timer:update(dt)
    if not self.started then
        return
    end

    self.currTime = self.currTime + dt

    if self.currTime >= self.goalTime then
        self.timesFinished = self.timesFinished + 1

        if self.timesFinished >= self.repetitions then
            self.started = false
        end

        self.currTime = self.currTime - self.goalTime
        return true
    end

    return false
end

function Timer:start()
    self.started = true
end

function Timer:reset()
    self.started = false
    self.currTime = 0
    self.timesFinished = 0
end

function Timer:set(goalTime, repetitions)
    self.repetitions = repetitions or self.repetitions
    self.goalTime = goalTime
    self:reset()
end

return Timer