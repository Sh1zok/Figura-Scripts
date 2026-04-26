--[[
    ■■■■■ Reanimated
    ■   ■ Source: https://github.com/Sh1zok/Figura-Scripts/tree/main/Reanimated
    ■■■■  v0.3.1

MIT License

Copyright (c) 2026 Sh1zok

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--



--[[
    Functions

    A few functions to reduce code duplication
]]--

-- A function that searches for a set of keyframes to then interpolate them
--
-- Finds the first keyframe whose time is less than the animation's playback time
-- If there isn't one, it creates a pseudo-keyframe. It then collects the previous keyframe,
-- the target keyframe, and the next target keyframe. Once found, returns these keyframes
local function getKeyframes(keyframes, time, maxTime)
    -- Sorting keyframes by time
    local keyframeTimings = {}
    local timing = next(keyframes)
    while timing do keyframeTimings[#keyframeTimings + 1], timing = timing, next(keyframes, timing) end
    table.sort(keyframeTimings)

    -- Finding keyframes
    local previousKeyframe, currentKeyframe, targetKeyframe, nextTargetKeyframe
    for keyframeIndex, keyframeTime in ipairs(keyframeTimings) do
        if not currentKeyframe or keyframeTime < time then
            -- Find the previous keyframe. If it doesn't exist take the data from the current keyframe and set the timestamp to zero
            local thisKeyframeTime = keyframeTimings[keyframeIndex - 1] or keyframeTimings[keyframeIndex]
            previousKeyframe = {data = keyframes[thisKeyframeTime], time = thisKeyframeTime}
            if not keyframeTimings[keyframeIndex - 1] then previousKeyframe.time = 0 end

            -- Find the current keyframe. If there is no previous keyframe and the animation playback time has not yet reached the current keyframe,
            -- then adjust the current keyframe's time to match the animation playback time. This is necessary to prevent interpolation issues
            -- when there is no keyframe with a timestamp of zero
            thisKeyframeTime = keyframeTimings[keyframeIndex]
            currentKeyframe = {data = keyframes[thisKeyframeTime], time = thisKeyframeTime}
            if time < thisKeyframeTime and not keyframeTimings[keyframeIndex - 1] then currentKeyframe.time = time end

            -- Find the target keyframe. If it doesn't exist, take the current keyframe and set the animation length as the timestamp
            thisKeyframeTime = keyframeTimings[keyframeIndex + 1] or keyframeTimings[keyframeIndex]
            targetKeyframe = {data = keyframes[thisKeyframeTime], time = thisKeyframeTime}
            if not keyframeTimings[keyframeIndex + 1] then targetKeyframe.time = maxTime end

            -- Find the next target keyframe. If there isn't one, use the target keyframe or the current keyframe as the data and set the animation length as the timestamp
            thisKeyframeTime = keyframeTimings[keyframeIndex + 2] or keyframeTimings[keyframeIndex + 1] or keyframeTimings[keyframeIndex]
            nextTargetKeyframe = {data = keyframes[thisKeyframeTime], time = thisKeyframeTime}
            if not keyframeTimings[keyframeIndex + 2] then nextTargetKeyframe.time = maxTime end
        end
    end
    return previousKeyframe, currentKeyframe, targetKeyframe, nextTargetKeyframe
end

-- A function for interpolating keyframes. Just a bunch of mathematical magic
local function interpolateValues(previousKeyframe, currentKeyframe, targetKeyframe, nextTargetKeyframe, time)
    if currentKeyframe.data.interpolation.type == "LINEAR" then -- Basic linear interpolation
        local lerpPercent = 1 - (targetKeyframe.time - time) / (targetKeyframe.time - currentKeyframe.time)
        return math.lerp(currentKeyframe.data.value, targetKeyframe.data.value, lerpPercent)
    elseif currentKeyframe.data.interpolation.type == "SMOOTH" then -- Catmull-Rom
        local timeRatio = 1 - (targetKeyframe.time - time) / (targetKeyframe.time - currentKeyframe.time)

        local coefficients = {
            {-1,  3, -3,  1},
            { 2, -5,  4, -1},
            {-1,  0,  1,  0},
            { 0,  2,  0,  0}
        }
        local timesVector = {timeRatio ^ 3, timeRatio ^ 2, timeRatio, 1}

        local timesMutiplied = {0, 0, 0, 0}
        for i = 1, 4 do
            for j = 1, 4 do timesMutiplied[i] = timesMutiplied[i] + timesVector[j] * coefficients[j][i] end
        end

        return (timesMutiplied[1] * previousKeyframe.data.value + timesMutiplied[2] * currentKeyframe.data.value + timesMutiplied[3] * targetKeyframe.data.value + timesMutiplied[4] * nextTargetKeyframe.data.value) / 2
    elseif currentKeyframe.data.interpolation.type == "BEZIER" then -- Bezier(damn math hell, I hope I will never touch this again)
        -- Point times and values
        local currentFrameTime = currentKeyframe.time
        local targetFrameTime = targetKeyframe.time
        local rightBezierTime = currentFrameTime + currentKeyframe.data.interpolation.bezierRightTime
        local leftBezierTime = targetFrameTime + targetKeyframe.data.interpolation.bezierLeftTime or vec(-0.1, -0.1, -0.1)
        local currentFrameValue = currentKeyframe.data.value
        local rightBezierValue = currentKeyframe.data.value + currentKeyframe.data.interpolation.bezierRightValue
        local leftBezierValue = targetKeyframe.data.value + (targetKeyframe.data.interpolation.bezierLeftValue or vec(0, 0, 0))
        local targetFrameValue = targetKeyframe.data.value

        -- Normalized times
        local normalizedTime = (time - currentFrameTime) / (targetFrameTime - currentFrameTime)
        local normalizedTimeParam1 = (rightBezierTime - currentFrameTime) / (targetFrameTime - currentFrameTime)
        local normalizedTimeParam2 = (leftBezierTime - currentFrameTime) / (targetFrameTime - currentFrameTime)

        -- Solving a cubic equation
        local approximated = normalizedTime
        for _ = 1, 10 do
            local bezierFunc = approximated ^ 3 + 3 * approximated ^ 2 * (1 - approximated) * normalizedTimeParam2 + 3 * approximated * (1 - approximated) ^ 2 * normalizedTimeParam1 - normalizedTime
            local bezierDerivative = 3 * approximated ^ 2 + 6 * approximated * (1 - approximated) * normalizedTimeParam2 - 3 * approximated ^ 2 * normalizedTimeParam2 + 3 * (1 - approximated) ^ 2 * normalizedTimeParam1 - 6 * approximated * (1 - approximated) * normalizedTimeParam1

            if bezierDerivative:length() < 1e-6 then break end
            approximated = math.clamp(approximated - bezierFunc / bezierDerivative, vec(0, 0, 0), vec(1, 1, 1))
        end

        local polyCoeff0 = (1 - approximated) ^ 2 * (1 - approximated) * currentFrameValue
        local polyCoeff1 = 3 * (1 - approximated) ^ 2 * approximated * rightBezierValue
        local polyCoeff2 = 3 * (1 - approximated) * approximated ^ 2 * leftBezierValue
        local polyCoeff3 = approximated ^ 2 * approximated * targetFrameValue

        return polyCoeff0 + polyCoeff1 + polyCoeff2 + polyCoeff3
    elseif currentKeyframe.data.interpolation.type == "STEP" then -- Just current frame value
        return currentKeyframe.data.value
    end
end

-- A function that creates a complete copy of a list, completely unrelated to the original. Needed for copying and resetting animation parameters
local function tableDeepCopy(table)
    local copy = {}

    for key, value in pairs(table) do
        if type(value) == "table" then
            copy[key] = tableDeepCopy(value)
        else
            copy[key] = value
        end
    end

    return copy
end



--[[
    New animation API

    Here are described the methods and variables that will be used
    in the future and also defines the functions of the new animation API
]]--

local animationsList, newAnimationAPI = {models = {}}, {tags = {}}

-- An internal table for storing all transformations of all model parts
-- Contains the __index metamethods for automatically creating/findind missing parts of the table
local modelPartTransforms = setmetatable({}, {
    __index = function(modelPartsTable, modelPart)
        modelPartsTable[modelPart] = setmetatable({}, {
            __index = function(transformTypes, transformType)
                transformTypes[transformType] = {[0] = {}}
                return transformTypes[transformType]
            end
        })

        return modelPartsTable[modelPart]
    end
})

animations = setmetatable(newAnimationAPI, {__index = function(_, key) return animationsList[key] end}) -- Replaceing the original API

-- A function for creates a new animation. It accepts the name of the model to
-- which it will be attached, animation preferences and animation tags
function newAnimationAPI:newAnimation(modelName, preferences, tags)
    -- Assertation
    assert(type(modelName or "models") == "string", "Invalid argument 1 to function newAnimation. Expected string or nil, but got " .. type(modelName))
    assert(type(preferences) == "table", "Invalid argument 2 to function newAnimation. Expected table, but got " .. type(preferences))
    assert(type(preferences.name) == "string", "Invalid name for new animation. Expected string, but got " .. type(preferences.name))
    if not animationsList[modelName or "models"] then animationsList[modelName or "models"] = {} end
    for takenName in pairs(animationsList[modelName or "models"]) do assert(preferences.name ~= takenName, "This animation name is already taken") end

    -- Initialization. Unpack preferences and create an animation interface
    local interface = {
        keyframes = preferences.keyframes or {},
        parameters = preferences.parameter or {},
        tags = tags or {},
        playbackTime = 0,
        speedMultiplier = preferences.speedMultiplier or 1,
        blendMultiplier = preferences.blendMultiplier or 1,
        loopMode = string.upper(preferences.loopMode or "ONCE"),
        maxLength = preferences.maxLength or (1 / 0),
        startOffset = preferences.startOffset or (-1 / 0),
        startDelayValue = preferences.startDelay or 0,
        loopDelayValue = preferences.loopDelay or 0,
        priorityValue = preferences.priority or 0,
        isOverridingRotations = preferences.isOverridingVanillaTransformations or false,
        isOverridingPositions = preferences.isOverridingVanillaTransformations or false,
        isOverridingScales = preferences.isOverridingVanillaTransformations or false
    }
    local name = preferences.name
    local playState = "STOPPED"
    local initialParameters = {} -- The initial animation parameter values table. Necessary for properly restarting the animation and passing the script data through animation frames
    local loopModes = {
        ONCE = function() interface:stop() end,
        HOLD = function()
            events.render:remove("Reanimated." .. name)
            playState = "HOLDING"
        end,
        LOOP = function() interface:restart() end
    }
    local legacyStuff = {name = preferences.name}
    local aliasMethods = {}



    -- A function that runs every frame when the animation is playing
    local renderFunction = function()
        -- Calculating animation playback time
        local deltaTime = 1 / math.max(client:getFPS(), 1)
        interface.playbackTime = math.max(interface.playbackTime, interface.startOffset) + deltaTime * interface.speedMultiplier

        -- Checking is the end of an animation has been reached
        local isEndReached = interface.playbackTime >= interface.maxLength

        -- Calculate all transformations for each model part. Also executes them scripts sometimes
        for modelPart, keyframeTypes in pairs(interface.keyframes) do
            -- Rotation. The transformation is multiplied by the vector (-1, -1, 1) to match the animation in blockbench
            if keyframeTypes.rotation then
                local previousKeyframe, currentKeyframe, targetKeyframe, nextTargetKeyframe = getKeyframes(keyframeTypes.rotation, interface.playbackTime, interface.maxLength)

                modelPartTransforms[modelPart].rotations[interface.priorityValue][interface] = {
                    isMerging = not interface.isOverridingRotations,
                    vector = interpolateValues(previousKeyframe, currentKeyframe, targetKeyframe, nextTargetKeyframe, interface.playbackTime) * vec(-1, -1, 1) * interface.blendMultiplier
                }

                modelPart:updateRot()
            end
            -- Position. The transformation is multiplied by the vector (-1, 1, 1) to match the animation in blockbench
            if keyframeTypes.position then
                local previousKeyframe, currentKeyframe, targetKeyframe, nextTargetKeyframe = getKeyframes(keyframeTypes.position, interface.playbackTime, interface.maxLength)

                modelPartTransforms[modelPart].positions[interface.priorityValue][interface] = {
                    isMerging = not interface.isOverridingPositions,
                    vector = interpolateValues(previousKeyframe, currentKeyframe, targetKeyframe, nextTargetKeyframe, interface.playbackTime) * vec(-1, 1, 1) * interface.blendMultiplier
                }

                modelPart:updatePos()
            end
            -- Scale
            if keyframeTypes.scale then
                local previousKeyframe, currentKeyframe, targetKeyframe, nextTargetKeyframe = getKeyframes(keyframeTypes.scale, interface.playbackTime, interface.maxLength)

                modelPartTransforms[modelPart].scales[interface.priorityValue][interface] = {
                    isMerging = not interface.isOverridingScales,
                    vector = interpolateValues(previousKeyframe, currentKeyframe, targetKeyframe, nextTargetKeyframe, interface.playbackTime) * interface.blendMultiplier
                }

                modelPart:updateScale()
            end
            -- Script
            if keyframeTypes.script then
                if not interface.parameters.executedScriptTimings then interface.parameters.executedScriptTimings = {} end

                -- Sorting keyframes by time
                local scriptTimings = {}
                local timing = next(keyframeTypes.script)
                while timing do scriptTimings[#scriptTimings + 1], timing = timing, next(keyframeTypes.script, timing) end
                table.sort(scriptTimings)

                -- Finding unexecuted script
                local currentKeyframe
                for keyframeIndex, keyframeTime in ipairs(scriptTimings) do
                    if not currentKeyframe or keyframeTime < interface.playbackTime then currentKeyframe = {script = keyframeTypes.script[scriptTimings[keyframeIndex]].script, time = scriptTimings[keyframeIndex]} end
                end

                -- Execute the script once
                if not interface.parameters.executedScriptTimings[currentKeyframe.time] and currentKeyframe.time <= interface.playbackTime then
                    currentKeyframe.script(interface.parameters, deltaTime)
                    interface.parameters.executedScriptTimings[currentKeyframe.time] = true
                end
                if isEndReached then keyframeTypes.script[#(keyframeTypes.script)].script(interface.parameters, deltaTime) end
            end
        end

        if isEndReached then
            if loopModes[string.upper(interface.loopMode)] then loopModes[string.upper(interface.loopMode)]() else interface:stop() end
        end
    end



    -- Initializes or resumes the animation
    --
    -- Returns the given animation for chaining
    function interface:play()
        if playState == "PLAYING" then return self end

        for modelPart in pairs(interface.keyframes) do
            if not modelPartTransforms[modelPart].rotations[interface.priorityValue] then modelPartTransforms[modelPart].rotations[interface.priorityValue] = {} end
            if not modelPartTransforms[modelPart].positions[interface.priorityValue] then modelPartTransforms[modelPart].positions[interface.priorityValue] = {} end
            if not modelPartTransforms[modelPart].scales[interface.priorityValue] then modelPartTransforms[modelPart].scales[interface.priorityValue] = {} end
        end

        events.render:register(renderFunction, "Reanimated." .. name)
        playState = "PLAYING"
        interface.playbackTime = -interface.startDelayValue
        initialParameters = tableDeepCopy(interface.parameters)

        return self -- Returns self for chaining
    end

    -- Stop the animation
    --
    -- Returns the given animation for chaining
    function interface:stop()
        if playState == "STOPPED" then return self end

        events.render:remove("Reanimated." .. name)
        playState = "STOPPED"

        interface.playbackTime = 0
        interface.parameters = tableDeepCopy(initialParameters)
        for modelPart in pairs(interface.keyframes) do
            modelPartTransforms[modelPart].rotations[interface.priorityValue][interface] = nil; modelPart:updateRot()
            modelPartTransforms[modelPart].positions[interface.priorityValue][interface] = nil; modelPart:updatePos()
            modelPartTransforms[modelPart].scales[interface.priorityValue][interface] = nil; modelPart:updateScale()
        end

        return self -- Returns self for chaining
    end

    -- Pause the animation's playback
    --
    -- Returns the given animation for chaining
    function interface:pause()
        if playState == "PAUSED" then return self end

        events.render:remove("Reanimated." .. name)
        playState = "PAUSED"

        return self -- Returns self for chaining
    end

    -- Restarts the animation
    -- Plays the animation if it was stopped
    -- This behavior can also be reproduced by stopping then playing the animation
    --
    -- Returns the given animation for chaining
    function interface:restart()
        if playState == "STOPPED" then initialParameters = tableDeepCopy(interface.parameters) end
        interface.playbackTime = 0
        if playState == "PLAYING" or playState == "HOLDING" then interface.playbackTime = -interface.loopDelayValue end
        interface.parameters = tableDeepCopy(initialParameters)

        events.render:remove("Reanimated." .. name)
        events.render:register(renderFunction, "Reanimated." .. name)
        playState = "PLAYING"

        for modelPart in pairs(interface.keyframes) do
            if not modelPartTransforms[modelPart].rotations[interface.priorityValue] then modelPartTransforms[modelPart].rotations[interface.priorityValue] = {} end
            if not modelPartTransforms[modelPart].positions[interface.priorityValue] then modelPartTransforms[modelPart].positions[interface.priorityValue] = {} end
            if not modelPartTransforms[modelPart].scales[interface.priorityValue] then modelPartTransforms[modelPart].scales[interface.priorityValue] = {} end
            modelPartTransforms[modelPart].rotations[interface.priorityValue][interface] = nil
            modelPartTransforms[modelPart].positions[interface.priorityValue][interface] = nil
            modelPartTransforms[modelPart].scales[interface.priorityValue][interface] = nil
        end

        return self -- Returns self for chaining
    end

    -- A function that merges "play" and "stop" together
    --
    -- Takes a boolean parameter, where if true, the animation will play, and when false, the animation will stop
    function interface:setPlaying(state)
        if state then return interface:play() else return interface:stop() end
    end
    function aliasMethods:playing(state) return self:setPlaying(state) end -- Alias

    -- Gets the name of the animation
    function interface:getName() return name end

    -- Gets the playstate of the animation
    function interface:getPlayState() return playState end

    -- Checks if the animation is playing
    function interface:isPlaying() return playState == "PLAYING" end

    -- Checks if the animation is stopped
    function interface:isStopped() return playState == "STOPPED" end

    -- Checks if the animation is paused
    function interface:isPaused() return playState == "PAUSED" end

    -- Checks if this animation is holding on its last frame
    function interface:isHolding() return playState == "HOLDING" end

    -- Adds a string to run in a determinant time
    --
    -- If there's already code to run at that time, it is overwritten
    function legacyStuff:newCode(time, code)
        assert(code, "newCode 2 do not allow nil values, expected String")
        if type(code) ~= "string" then return interface end

        interface.keyframes[models].script[time or 0] = {script = loadstring(code), interpolation = {}}
        return interface
    end



    -- Sets the animation's playback speed
    --
    -- Negative numbers can be used for an inverted animation
    --
    -- Default speed is 1, 2 is twice the speed, and 0.5 is half the speed
    function legacyStuff:setSpeed(speed)
        assert(type(speed) == "number" or not speed, "Invalid argument to function setSpeed. Expected number or nil, but got " .. type(speed))

        interface.speedMultiplier = speed or 1
        return interface
    end
    function legacyStuff:speed(speed) return legacyStuff:setSpeed(speed) end -- Alias

    -- Gets the animation's speed
    function legacyStuff:getSpeed() return interface.speedMultiplier end -- Legacy

    -- Set the animation's length, in seconds
    function legacyStuff:setLength(length)
        assert(type(length) == "number" or not length, "Invalid argument to function setLength. Expected number or nil, but got " .. type(length))

        interface.maxLength = length or preferences.maxLength
        return interface
    end
    function legacyStuff:length(length) return legacyStuff:setLength(length) end -- Alias

    -- Gets the animation's length, in seconds
    function legacyStuff:getLength() return interface.maxLength end

    -- Sets the animation's priority
    --
    -- Instead of blending, low priority animations are overridden by high priority ones
    --
    -- The default priority of animations is 0
    function legacyStuff:setPriority(priority)
        assert(type(priority) == "number" or not priority, "Invalid argument to function setPriority. Expected number or nil, but got " .. type(priority))

        interface.priorityValue = priority or preferences.priority
        return interface
    end
    function legacyStuff:priority(priority) return legacyStuff:setPriority(priority) end -- Alias

    -- Gets the animation's priority
    function legacyStuff:getPriority() return interface.priorityValue end

    -- Sets the animation's playback current time, in seconds
    function legacyStuff:setTime(time)
        assert(type(time) == "number" or not time, "Invalid argument to function setTime. Expected number or nil, but got " .. type(time))

        interface.playbackTime = time or 0
        return interface
    end
    function legacyStuff:time(time) return legacyStuff:setTime(time) end -- Alias

    -- Get the animation's playback current time, in seconds
    function legacyStuff:getTime() return interface.playbackTime end

    -- Sets how much time to skip for the animation, in seconds
    --
    -- The time is skipped on every loop
    function legacyStuff:setOffset(offset)
        assert(type(offset) == "number" or not offset, "Invalid argument to function setOffset. Expected number or nil, but got " .. type(offset))

        interface.startOffset = offset or 0
        return interface
    end
    function legacyStuff:offset(offset) return legacyStuff:setOffset(offset) end -- Alias

    -- Gets the animation's offset time, in seconds
    function interface:getOffset() return interface.startOffset end

    -- Sets the animation's loop mode
    function legacyStuff:setLoop(loop)
        assert(loop, "setLoop 1 do not allow nil values, expected String")
        assert(type(loop) == "string", "Invalid argument to function setLoop. Expected String, but got " .. type(loop))
        assert(loopModes[string.upper(loop)], "Illegal LoopMode: \"" .. loop .. "\".")

        interface.loopMode = string.upper(loop)
        return interface
    end
    function legacyStuff:loop(loop) return legacyStuff:setLoop(loop) end -- Alias

    -- Gets the animation's loop mode
    function legacyStuff:getLoop() return interface.loopMode end

    -- Sets the animation's keyframe blend factor, which is the strength of the animation
    function legacyStuff:setBlend(blend)
        assert(type(blend) == "number" or not blend, "Invalid argument to function setBlend. Expected number or nil, but got " .. type(blend))

        interface.blendMultiplier = blend or 1
        return interface
    end
    function legacyStuff:blend(blend) return legacyStuff:setBlend(blend) end -- Alias

    function legacyStuff:getBlend() return interface.blendMultiplier end

    -- Set how much time to wait before this animation is initialized, in seconds
    --
    -- Note that while it is waiting, the animation is considered being played
    function legacyStuff:setStartDelay(delay)
        assert(type(delay) == "number" or not delay, "Invalid argument to function setStartDelay. Expected number or nil, but got " .. type(delay))

        interface.startDelayValue = delay or 0
        return interface
    end
    function legacyStuff:startDelay(delay) return legacyStuff:setStartDelay(delay) end -- Alias

    -- Gets the animation's start delay, in seconds
    function legacyStuff:getStartDelay() return interface.startDelayValue end

    -- Set how much time to wait in between the loops of this animation, in seconds
    function legacyStuff:setLoopDelay(delay)
        assert(type(delay) == "number" or not delay, "Invalid argument to function setLoopDelay. Expected number or nil, but got " .. type(delay))

        interface.loopDelayValue = delay
        return interface
    end
    function legacyStuff:loopDelay(delay) return legacyStuff:setLoopDelay(delay) end -- Alias

    -- Gets the animation's loop delay, in seconds
    function legacyStuff:getLoopDelay() return interface.loopDelayValue end

    -- Set if this animation should override its parts vanilla rotation
    function legacyStuff:setOverrideRot(override)
        interface.isOverridingRotations = override or preferences.isOverridingVanillaTransformations
        return interface
    end
    function legacyStuff:overrideRot(override) return legacyStuff:setOverrideRot(override) end -- Alias

    -- Gets if this animation should override its parts vanilla rotation
    function legacyStuff:getOverrideRot() return interface.isOverridingRotations end

    -- Set if this animation should override its parts vanilla position
    function legacyStuff:setOverridePos(override)
        interface.isOverridingPositions = override or preferences.isOverridingVanillaTransformations
        return interface
    end
    function legacyStuff:overridePos(override) return legacyStuff:setOverridePos(override) end -- Alias

    -- Gets if this animation should override its parts vanilla position
    function legacyStuff:getOverridePos() return interface.isOverridingPositions end

    -- Set if this animation should override its parts vanilla scale
    function legacyStuff:setOverrideScale(override)
        interface.isOverridingScales = override or preferences.isOverridingVanillaTransformations
        return interface
    end
    function legacyStuff:overrideScale(override) return legacyStuff:setOverrideScale(override) end -- Alias

    -- Gets if this animation should override its parts vanilla scale
    function legacyStuff:getOverrideScale() return interface.isOverridingScales end

    -- Set if this animation should override all of its parts vanilla transforms
    --
    -- Equivalent of calling "overrideRot", "overridePos" and "overrideScale" altogether
    function legacyStuff:setOverride(override)
        interface.isOverridingRotations = override or preferences.isOverridingVanillaTransformations
        interface.isOverridingPositions = override or preferences.isOverridingVanillaTransformations
        interface.isOverridingScales = override or preferences.isOverridingVanillaTransformations

        return interface
    end
    function legacyStuff:override(override) return legacyStuff:setOverride(override) end -- Alias



    -- Listing and return
    interface = setmetatable(interface, {
        __index = function(_, key) return aliasMethods[key] or legacyStuff[key] end,
        __newindex = function() error("Cannot assign new method/field to an animation object", 2) end
    })
    animationsList[modelName or "models"][name] = interface

    return interface
end

-- A function that searches for animations by tags
function newAnimationAPI.tags:searchFor(tags)
    -- Assertation
    assert(type(tags) == "string" or type(tags) == "table", "Invalid tags list. Expected String or table, but got " .. type(tags))
    if type(tags) == "string" then tags = {tags} end

    -- Looks for animations that have at least one tag from the tags table
    local foundAnimations = {}
    for animGroupName, animGroup in pairs(animationsList) do
        local numberOfFound = 0
        foundAnimations[animGroupName] = {}

        for animName, animation in pairs(animGroup) do
            for _, tag in ipairs(tags) do
                if animation.tags[tag] then
                    foundAnimations[animGroupName][animName] = animation
                    numberOfFound = numberOfFound + 1
                    break
                end
            end
        end

        if numberOfFound == 0 then foundAnimations[animGroupName] = nil end
    end

    -- Returns found animations
    return foundAnimations
end

-- Calls animation methods found through tags
newAnimationAPI.tags = setmetatable(newAnimationAPI.tags, {
    __index = function(_, methodName)
        return function(self, tags)
            for _, animationGroup in pairs(newAnimationAPI.tags:searchFor(tags)) do
                for _, animation in pairs(animationGroup) do animation[methodName](animation) end
            end

            return self
        end
    end
})



--[[
    Replaceing animations

    Convertation from the native animation format to the new animation format specified by the API occurs
]]--

-- Recursively collect animation keyframes data from each model part
local function searchForAnimations(modelPartNBT, modelPart, returningList)
    -- Collect the data
    if modelPartNBT.anim then
        for _, animNBT in pairs(modelPartNBT.anim) do
            if not returningList[animNBT.id] then returningList[animNBT.id] = {} end
            returningList[animNBT.id][modelPart[modelPartNBT.name]] = animNBT.data
        end
    end

    -- Go to the model part's children
    if modelPartNBT.chld then
        for _, nextModelPartNBT in pairs(modelPartNBT.chld) do returningList = searchForAnimations(nextModelPartNBT, modelPart[modelPartNBT.name], returningList) end
    end

    return returningList
end
local animationsData = searchForAnimations(avatar:getNBT().models, _G, {})

-- Deshorting animations data
for _, animationData in pairs(animationsData) do
    for _, keyframesData in pairs(animationData) do
        if keyframesData.pos then keyframesData.position, keyframesData.pos = keyframesData.pos, nil end
        if keyframesData.rot then keyframesData.rotation, keyframesData.rot = keyframesData.rot, nil end
        if keyframesData.scl then keyframesData.scale, keyframesData.scl = keyframesData.scl, nil end
    end
end

-- Importing code keyframes
for APIIndex, animationData in ipairs(avatar:getNBT().animations) do
    if animationData.code then
        if not animationsData[APIIndex - 1] then animationsData[APIIndex - 1] = {} end
        if not animationsData[APIIndex - 1][models] then animationsData[APIIndex - 1][models] = {} end
        animationsData[APIIndex - 1][models].script = animationData.code
    end
end

-- Beautifying keyframes and keyframe data
for _, animationData in pairs(animationsData) do
    for _, keyframeTypes in pairs(animationData) do
        for keyframeType, keyframes in pairs(keyframeTypes) do
            local newKeyframes = {}
            for _, keyframeData in ipairs(keyframes) do newKeyframes[keyframeData.time] = keyframeData end

            for _, keyframeData in pairs(newKeyframes) do
                keyframeData.time, keyframeData.interpolation = nil, {}

                for key, data in pairs(keyframeData) do
                    if key == "pre" then -- Value
                        keyframeData.value = vec(data[1], data[2], data[3])
                        keyframeData.pre = nil
                    end
                    if key == "int" then -- Interpolation
                        if data == "catmullrom" then data = "smooth" end
                        keyframeData.interpolation.type = string.upper(data)
                        keyframeData.int = nil
                    end
                    if key == "src" then -- Script
                        keyframeData.script = loadstring(data)
                        keyframeData.src = nil
                    end
                    if key == "bl" then -- Bezier value
                        keyframeData.interpolation.bezierLeftValue = vec(data[1], data[2], data[3])
                        keyframeData.interpolation.bezierRightValue = -keyframeData.interpolation.bezierLeftValue
                        keyframeData.bl, keyframeData.br = nil, nil
                    end
                    if key == "blt" then -- Bezier time
                        keyframeData.interpolation.bezierLeftTime = vec(data[1], data[2], data[3])
                        keyframeData.interpolation.bezierRightTime = -keyframeData.interpolation.bezierLeftTime
                        keyframeData.blt, keyframeData.brt = nil, nil
                    end
                end

                -- If a keyframe has a Bezier interpolation type but does not have tangent points data, replace them with placeholders
                if keyframeData.interpolation.type == "BEZIER" then
                    if not keyframeData.interpolation.bezierLeftValue then
                        keyframeData.interpolation.bezierLeftValue = vec(0, 0, 0)
                        keyframeData.interpolation.bezierRightValue = -keyframeData.interpolation.bezierLeftValue
                    end
                    if not keyframeData.interpolation.bezierLeftTime then
                        keyframeData.interpolation.bezierLeftTime = vec(-0.1, -0.1, -0.1)
                        keyframeData.interpolation.bezierRightTime = -keyframeData.interpolation.bezierLeftTime
                    end
                end
            end

            keyframeTypes[keyframeType] = newKeyframes
        end
    end
end

-- Generating replacement animations
for APIIndex, animationNBT in pairs(avatar:getNBT().animations) do
    local newAnimation = newAnimationAPI:newAnimation(animationNBT.mdl, {
        name = animationNBT.name,
        blendMultiplier = animationNBT.bld,
        loopMode = animationNBT.loop,
        maxLength = animationNBT.len,
        isOverridingVanillaTransformations = animationNBT.ovr == 1,
        startOffset = animationNBT.off,
        startDelay = animationNBT.sdel,
        loopDelay = animationNBT.ldel
    }, {
        blockbenchAnimation = true,
        [animationNBT.mdl] = true
    })

    if animationsData[APIIndex - 1] then
        for modelPart, keyframesData in pairs(animationsData[APIIndex - 1]) do newAnimation.keyframes[modelPart] = keyframesData end
    end
end



--[[
    ModelParts

    Changing the behavior of methods that transform model parts
]]--

-- Prepairing for injecting custom stuff and override native stuff
local modelpartOrgignalIndexMethod = figuraMetatables.ModelPart.__index -- Save the original __index method for future use
local modelPartCustoms = {} -- Custom elements and methods of every model part

-- Function that arranges all priorities in ascending order
local function arrangePriorities(prioritiesTable)
    local priorities = {}
    local priority = next(prioritiesTable)
    while priority do priorities[#priorities + 1], priority = priority, next(prioritiesTable, priority) end
    table.sort(priorities)

    return priorities
end

-- Custom __index method of every model part
--
-- Looking for the customs first. If it finds something, it returns that
--
-- Otherwise it uses the original __index method to find something instead
function figuraMetatables.ModelPart:__index(key) return modelPartCustoms[key] or figuraMetatables.ModelPart[key] or modelpartOrgignalIndexMethod(self, key) end

-- Table for converting parent type names to vanilla model part names
local parentTypesTable = {
    Head = "HEAD",
    Body = "BODY",
    RightArm = "RIGHT_ARM",
    LeftArm = "LEFT_ARM",
    RightLeg = "RIGHT_LEG",
    LeftLeg = "LEFT_LEG",
    RightElytra = "RIGHT_ELYTRA",
    LeftElytra = "LEFT_ELYTRA",
    Cape = "CAPE_MODEL"
}

-- A function that calculates the pre-final rotation of a model part
--
-- Takes the highest rotations priority and sums them to get the pre-final model part rotation
function modelPartCustoms:updateRot()
    local rotationPriorities = arrangePriorities(modelPartTransforms[self].rotations)

    -- Calculating pre-final rotation of the model part and determining whether the pre-final rotation merges with the vanilla animations
    local modelPartPreFinalRot = vec(0, 0, 0)
    local isMergable = true
    for _, data in pairs(modelPartTransforms[self].rotations[#rotationPriorities - 1]) do
        if not data.isMerging then isMergable = false end
        modelPartPreFinalRot = modelPartPreFinalRot + data.vector
    end

    -- If the pre-final rotation cannot be merged with the vanilla rotation, calculating and applying a counter rotation
    if not isMergable and parentTypesTable[self:getParentType()] then
        local counterRotation
        if parentTypesTable[self:getParentType()] then counterRotation = -vanilla_model[parentTypesTable[self:getParentType()]]:getOriginRot() end
        modelPartPreFinalRot = modelPartPreFinalRot + counterRotation
    end

    -- NaN checks
    if modelPartPreFinalRot[1] ~= modelPartPreFinalRot[1] then modelPartPreFinalRot[1] = 0 end -- x
    if modelPartPreFinalRot[2] ~= modelPartPreFinalRot[2] then modelPartPreFinalRot[2] = 0 end -- y
    if modelPartPreFinalRot[3] ~= modelPartPreFinalRot[3] then modelPartPreFinalRot[3] = 0 end -- z

    -- Applying pre-final rotation to the model part
    return modelpartOrgignalIndexMethod(self, "setRot")(self, modelPartPreFinalRot)
end

-- A function that calculates the pre-final position of a model part
--
-- Takes the highest positions priority and sums them to get the pre-final model part position
function modelPartCustoms:updatePos()
    local positionPriorities = arrangePriorities(modelPartTransforms[self].positions)

    -- Calculating pre-final position of the model part and determining whether the pre-final position merges with the vanilla animations
    local modelPartPreFinalPos = vec(0, 0, 0)
    local isMergable = true
    for _, data in pairs(modelPartTransforms[self].positions[#positionPriorities - 1]) do
        if not data.isMerging then isMergable = false end
        modelPartPreFinalPos = modelPartPreFinalPos + data.vector
    end

    -- If the pre-final position cannot be merged with the vanilla position, calculating and applying a counter position
    if not isMergable and parentTypesTable[self:getParentType()] then
        local counterPosition
        if parentTypesTable[self:getParentType()] then counterPosition = -vanilla_model[parentTypesTable[self:getParentType()]]:getOriginPos() end
        modelPartPreFinalPos = modelPartPreFinalPos + counterPosition
    end

    -- NaN checks
    if modelPartPreFinalPos[1] ~= modelPartPreFinalPos[1] then modelPartPreFinalPos[1] = 0 end -- x
    if modelPartPreFinalPos[2] ~= modelPartPreFinalPos[2] then modelPartPreFinalPos[2] = 0 end -- y
    if modelPartPreFinalPos[3] ~= modelPartPreFinalPos[3] then modelPartPreFinalPos[3] = 0 end -- z

    -- Applying pre-final position to the model part
    return modelpartOrgignalIndexMethod(self, "setPos")(self, modelPartPreFinalPos)
end

-- A function that calculates the pre-final scale of a model part
--
-- Takes the highest scales priority and sums them to get the pre-final model part scale
function modelPartCustoms:updateScale()
    local scalePriorities = arrangePriorities(modelPartTransforms[self].scales)

    -- Calculating pre-final scale of the model part and determining whether the pre-final scale merges with the vanilla animations
    local modelPartPreFinalScale = vec(1, 1, 1)
    local isMergable = true
    for _, data in pairs(modelPartTransforms[self].scale[#scalePriorities - 1]) do
        if not data.isMerging then isMergable = false end
        modelPartPreFinalScale = modelPartPreFinalScale + data.vector
    end

    -- If the pre-final scale cannot be merged with the vanilla scale, calculating and applying a counter scale
    if not isMergable and parentTypesTable[self:getParentType()] then
        local counterScale
        if parentTypesTable[self:getParentType()] then counterScale = -vanilla_model[parentTypesTable[self:getParentType()]]:getOriginScale() end
        modelPartPreFinalScale = modelPartPreFinalScale + counterScale
    end

    -- NaN checks
    if modelPartPreFinalScale[1] ~= modelPartPreFinalScale[1] then modelPartPreFinalScale[1] = 1 end -- x
    if modelPartPreFinalScale[2] ~= modelPartPreFinalScale[2] then modelPartPreFinalScale[2] = 1 end -- y
    if modelPartPreFinalScale[3] ~= modelPartPreFinalScale[3] then modelPartPreFinalScale[3] = 1 end -- z

    -- Applying pre-final scale to the model part
    return modelpartOrgignalIndexMethod(self, "setScale")(self, modelPartPreFinalScale)
end

-- Replacement of the original method for better control over the rotation setting
function modelPartCustoms:setRot(rotOrX, y, z)
    -- Assertation
    assert(type(rotOrX) == "Vector3" or type(rotOrX) == "number" or not rotOrX, "Invalid argument 1 to function setRot. Expected number or Vector3, but got " .. type(rotOrX))
    assert(type(y) == "number" or not y, "Invalid argument 2 to function setRot. Expected number, but got " .. type(y))
    assert(type(z) == "number" or not z, "Invalid argument 3 to function setRot. Expected number, but got " .. type(z))

    if type(rotOrX) == "Vector3" then
        modelPartTransforms[self].rotations[0].script = {vector = rotOrX, isMerging = true}
    else
        -- Replace missing values ​​with placeholders
        modelPartTransforms[self].rotations[0].script = {vector = vec(rotOrX or 0, y or 0, z or 0), isMerging = true}
    end

    -- Setting the rotation
    return self:updateRot()
end
function modelPartCustoms:rot(rotOrX, y, z) return self:setRot(rotOrX, y, z) end -- Alias

function modelPartCustoms:getRot() return modelPartTransforms[self].rotations[0].script end

-- Replacement of the original method for better control over the position setting
function modelPartCustoms:setPos(posOrX, y, z)
    -- Assertation
    assert(type(posOrX) == "Vector3" or type(posOrX) == "number" or not posOrX, "Invalid argument 1 to function setPos. Expected number or Vector3, but got " .. type(posOrX))
    assert(type(y) == "number" or not y, "Invalid argument 2 to function setPos. Expected number, but got " .. type(y))
    assert(type(z) == "number" or not z, "Invalid argument 3 to function setPos. Expected number, but got " .. type(z))

    if type(posOrX) == "Vector3" then
        modelPartTransforms[self].positions[0].script = {vector = posOrX, isMerging = true}
    else
        -- Replace missing values ​​with placeholders
        modelPartTransforms[self].positions[0].script = {vector = vec(posOrX or 0, y or 0, z or 0), isMerging = true}
    end

    -- Setting the position
    return self:updatePos()
end
function modelPartCustoms:pos(posOrX, y, z) return self:setPos(posOrX, y, z) end -- Alias

function modelPartCustoms:getPos() return modelPartTransforms[self].positions[0].script end

-- Replacement of the original method for better control over the scale setting
function modelPartCustoms:setScale(scaleOrX, y, z)
    -- Assertation
    assert(type(scaleOrX) == "Vector3" or type(scaleOrX) == "number" or not scaleOrX, "Invalid argument 1 to function setScale. Expected number or Vector3, but got " .. type(scaleOrX))
    assert(type(y) == "number" or not y, "Invalid argument 2 to function setScale. Expected number, but got " .. type(y))
    assert(type(z) == "number" or not z, "Invalid argument 3 to function setScale. Expected number, but got " .. type(z))

    if type(scaleOrX) == "Vector3" then
        modelPartTransforms[self].scales[0].script = {vector = scaleOrX, isMerging = true}
    else
        -- Replace missing values ​​with placeholders
        modelPartTransforms[self].scales[0].script = {vector = vec(scaleOrX or 1, y or 1, z or 1), isMerging = true}
    end

    -- Setting the scale
    return self:updateScale()
end
function modelPartCustoms:scale(scaleOrX, y, z) return self:setScale(scaleOrX, y, z) end -- Alias

function modelPartCustoms:getScale() return modelPartTransforms[self].scales[0].script end

-- Replacement of the original method for more precise output
function modelPartCustoms:getTrueRot()
    self:updateRot()
    return modelpartOrgignalIndexMethod(self, "getTrueRot")(self)
end

-- Replacement of the original method for more precise output
function modelPartCustoms:getTruePos()
    self:updatePos()
    return modelpartOrgignalIndexMethod(self, "getTruePos")(self)
end

-- Replacement of the original method for more precise output
function modelPartCustoms:getTrueScale()
    self:updateScale()
    return modelpartOrgignalIndexMethod(self, "getTrueScale")(self)
end

-- A Method that allows to get a list of all transformations applied to a model part
function modelPartCustoms:getAllTransforms() return tableDeepCopy(modelPartTransforms[self]) end

function modelPartCustoms:getAnimRot()
    local rotationPriorities = arrangePriorities(modelPartTransforms[self].rotations)

    -- Calculating pre-final rotation of the model part
    local modelPartPreFinalRot = vec(0, 0, 0)
    for _, data in pairs(modelPartTransforms[self].rotations[#rotationPriorities - 1]) do modelPartPreFinalRot = modelPartPreFinalRot + data.vector end

    return modelPartPreFinalRot
end

function modelPartCustoms:getAnimPos()
    local positionPriorities = arrangePriorities(modelPartTransforms[self].positions)

    -- Calculating pre-final position of the model part
    local modelPartPreFinalPos = vec(0, 0, 0)
    for _, data in pairs(modelPartTransforms[self].positions[#positionPriorities - 1]) do modelPartPreFinalPos = modelPartPreFinalPos + data.vector end

    return modelPartPreFinalPos
end

function modelPartCustoms:getAnimScale()
    local scalePriorities = arrangePriorities(modelPartTransforms[self].scales)

    -- Calculating pre-final scale of the model part
    local modelPartPreFinalScale = vec(1, 1, 1)
    for _, data in pairs(modelPartTransforms[self].scale[#scalePriorities - 1]) do modelPartPreFinalScale = modelPartPreFinalScale + data.vector end

    return modelPartPreFinalScale
end

function modelPartCustoms:overrideVanillaRot()
    local rotationPriorities = arrangePriorities(modelPartTransforms[self].rotations)

    -- Determining whether the pre-final rotation merges with the vanilla animations
    for _, data in pairs(modelPartTransforms[self].rotations[#rotationPriorities - 1]) do
        if not data.isMerging then return false end
    end

    return true
end

function modelPartCustoms:overrideVanillaPos()
    local positionPriorities = arrangePriorities(modelPartTransforms[self].positions)

    -- Determining whether the pre-final position merges with the vanilla animations
    for _, data in pairs(modelPartTransforms[self].positions[#positionPriorities - 1]) do
        if not data.isMerging then return false end
    end

    return true
end

function modelPartCustoms:overrideVanillaScale()
    local scalePriorities = arrangePriorities(modelPartTransforms[self].scales)

    -- Determining whether the pre-final scale merges with the vanilla animations
    for _, data in pairs(modelPartTransforms[self].scales[#scalePriorities - 1]) do
        if not data.isMerging then return false end
    end

    return true
end
