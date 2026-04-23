--[[
    ■■■■■ Smoothie
    ■   ■ Author: Sh1zok
    ■■■■  v0.10.3

MIT License

Copyright (c) 2025 Sh1zok

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

local vanillaEyesPoint = models:newPart("smoothieVanillaEyesPivot"):setPos(0, 28, 0)
local smoothie = {}



function smoothie:newSmoothHead(modelPart)
    -- Checking the validity of the parameter
    assert(type(modelPart) == "ModelPart", "Invalid argument to function newSmoothHead. Expected ModelPart, but got " .. type(modelPart))
    modelPart:setParentType("NONE") -- Preparing modelPart

    -- Setting up some variables
    local interface = {}
    local headModelPart = modelPart
    local strength = 1
    local speed = 1
    local tiltMultiplier = 1
    local keepVanillaPosition = true
    local headRotPrevFrame = vec(0, 0, 0)

    -- Head rotation processor
    events.RENDER:register(function(delta, context)
        -- Checking the need to process the head rotation
        if not player:isLoaded() then return end
        if not (context == "RENDER" or context == "FIRST_PERSON" or context == "MINECRAFT_GUI") then return end

        -- Math part
        local headRot = math.lerp(
            headRotPrevFrame,
            ((vanilla_model.HEAD:getOriginRot() + 180) % 360 - 180) * strength,
            math.min(8 / math.max(client:getFPS(), 1) * speed, 1)
        )
        headRot[3] = math.lerp(
            headRotPrevFrame[3],
            2.5 * ((vanilla_model.HEAD:getOriginRot() + 180) % 360 - 180)[2] / 50 * tiltMultiplier,
            math.min(8 / math.max(client:getFPS(), 1) * speed, 1)
        )

        -- Applying new head rotation
        headModelPart:setOffsetRot(headRot)
        headRotPrevFrame = headRot

        -- Fixing crouching pose
        if keepVanillaPosition then headModelPart:setPos(-vanilla_model.HEAD:getOriginPos()) end
    end, "Smoothie.SmoothHead")

    --[[
        Interface
    ]]--
    function interface:setStrength(value)
        if value == nil then value = 1 end
        assert(type(value) == "number", "Invalid argument to function setStrength. Expected number, but got " .. type(value))
        strength = value

        return interface -- Returns interface for chaining
    end
    function interface:strength(value) return interface:setStrength(value) end  -- Alias

    function interface:setSpeed(value)
        if value == nil then value = 1 end
        assert(type(value) == "number", "Invalid argument to function setSpeed. Expected number, but got " .. type(value))
        speed = value

        return interface -- Returns interface for chaining
    end
    function interface:speed(value) return interface:setSpeed(value) end  -- Alias

    function interface:setTiltMultiplier(value)
        if value == nil then value = 1 end
        assert(type(value) == "number", "Invalid argument to function setTiltMultiplier. Expected number, but got " .. type(value))
        tiltMultiplier = value

        return interface -- Returns interface for chaining
    end
    function interface:tiltMultiplier(value) return interface:setTiltMultiplier(value) end  -- Alias

    function interface:setKeepVanillaPosition(state)
        if state == nil then state = true end
        assert(type(state) == "boolean", "Invalid argument to function setKeepVanillaPosition. Expected boolean, but got " .. type(state))
        keepVanillaPosition = state

        return interface -- Returns interface for chaining
    end
    function interface:keepVanillaPosition(state) return interface:setKeepVanillaPosition(state) end -- Alias

    return interface
end



function smoothie:newEye(modelPart)
    -- Checking the validity of the parameter
    assert(type(modelPart) == "ModelPart", "Invalid argument to function newEye. Expected ModelPart, but got " .. type(modelPart))

    -- Setting up some variables
    local interface = {}
    local eyeModelPart = modelPart
    local offsetStrength = {top = 1, bottom = 1, left = 1, right = 1}

    -- Eye processor
    events.RENDER:register(function(_, context)
        -- Checking the need to process the head rotation
        if not player:isLoaded() then return end
        if not (context == "RENDER" or context == "FIRST_PERSON" or context == "MINECRAFT_GUI") then return end
        if not eyeModelPart then return end

        -- Math part
        local vanillaHeadRot = (vanilla_model.HEAD:getOriginRot() + 180) % 360 - 180

        -- Applying new eye offset
        eyeModelPart:setPos(
            math.clamp(
                -math.sign(vanillaHeadRot[2]) * ((vanillaHeadRot[2] / 60) ^ 2),
                -offsetStrength.left,
                offsetStrength.right
            ),
            math.clamp(
                math.sign(vanillaHeadRot[1]) * ((vanillaHeadRot[1] / 125) ^ 2),
                -offsetStrength.bottom,
                offsetStrength.top
            ),
            0
        )
    end, "Smoothie.EyeProcessor")

    function interface:setTopOffsetStrength(value)
        assert(type(value) == "number", "Invalid argument to function setTopOffsetStrength. Expected number, but got " .. type(value))
        offsetStrength.top = value

        return interface
    end
    function interface:topOffsetStrength(value) return interface:setTopOffsetStrength(value) end -- Alias

    function interface:setBottomOffsetStrength(value)
        assert(type(value) == "number", "Invalid argument to function setBottomOffsetStrength. Expected number, but got " .. type(value))
        offsetStrength.bottom = value

        return interface
    end
    function interface:bottomOffsetStrength(value) return interface:setBottomOffsetStrength(value) end -- Alias

    function interface:setLeftOffsetStrength(value)
        assert(type(value) == "number", "Invalid argument to function setLeftOffsetStrength. Expected number, but got " .. type(value))
        offsetStrength.left = value

        return interface
    end
    function interface:leftOffsetStrength(value) return interface:setLeftOffsetStrength(value) end -- Alias

    function interface:setRightOffsetStrength(value)
        assert(type(value) == "number", "Invalid argument to function setRightOffsetStrength. Expected number, but got " .. type(value))
        offsetStrength.right = value

        return interface
    end
    function interface:rightOffsetStrength(value) return interface:setRightOffsetStrength(value) end -- Alias

    return interface
end



function smoothie:newEar(modelPart)
    -- Checking the validity of the parameter
    assert(type(modelPart) == "ModelPart", "Invalid argument to function newEar. Expected ModelPart, but got " .. type(modelPart))

    -- Setting up some variables
    local interface = {}
    local earModelPart = modelPart
    local headRotationDelta, prevHeadRotationAngle = vec(0, 0, 0), vec(0, 0, 0)
    local speed, bouncy = 1, 1
    local earRotationVelocity = vec(0, 0, 0)
    local rotationLimits = {top = 90, bottom = 90, left = 90, right = 90}

    -- Ear rotation logic
    events.RENDER:register(function(delta)
        -- Calculating the difference in head rotation
        local headRotationAngle = (vanilla_model.HEAD:getOriginRot() + 180) % 360 - 180
        headRotationDelta = headRotationDelta + (prevHeadRotationAngle - headRotationAngle)
        headRotationDelta[1] = math.clamp(headRotationDelta[1], -rotationLimits.bottom, rotationLimits.top)
        headRotationDelta[2] = math.clamp(headRotationDelta[2], -rotationLimits.left, rotationLimits.right)
        prevHeadRotationAngle = headRotationAngle

        -- Calculation the speed of rotation and the rotation of the ear itself
        earRotationVelocity = earRotationVelocity + -((speed * 200) * (earModelPart:getOffsetRot() - headRotationDelta) + math.sqrt(speed * 2000) * (bouncy / 10) * earRotationVelocity) / math.max(client:getFPS(), 1)
        earModelPart:setOffsetRot(earModelPart:getOffsetRot() + earRotationVelocity / math.max(client:getFPS(), 1))

        -- Soft reduction of head deviation to zeros
        headRotationDelta = math.lerp(headRotationDelta, vec(0, 0, 0), 5 / math.max(client:getFPS(), 1))
    end, "Smoothie.earProcessor")

    function interface:setBouncy(value)
        assert(type(value) == "number", "Invalid argument to function setBouncy. Expected number, but got " .. type(value))
        bouncy = value

        return interface
    end
    function interface:bouncy(value) return interface:setBouncy(value) end -- Alias

    function interface:setSpeed(value)
        assert(type(value) == "number", "Invalid argument to function setSpeed. Expected number, but got " .. type(value))
        speed = value

        return interface
    end
    function interface:speed(value) return interface:setSpeed(value) end -- Alias

    function interface:setTopLimit(value)
        assert(type(value) == "number", "Invalid argument to function setTopLimit. Expected number, but got " .. type(value))
        rotationLimits.top = value

        return interface
    end
    function interface:topLimit(value) return interface:setTopLimit(value) end -- Alias

    function interface:setBottomLimit(value)
        assert(type(value) == "number", "Invalid argument to function setBottomLimit. Expected number, but got " .. type(value))
        rotationLimits.bottom = value

        return interface
    end
    function interface:bottomLimit(value) return interface:setBottomLimit(value) end -- Alias

    function interface:setLeftLimit(value)
        assert(type(value) == "number", "Invalid argument to function setLeftLimit. Expected number, but got " .. type(value))
        rotationLimits.left = value

        return interface
    end
    function interface:leftLimit(value) return interface:setLeftLimit(value) end -- Alias

    function interface:setRightLimit(value)
        assert(type(value) == "number", "Invalid argument to function setRightLimit. Expected number, but got " .. type(value))
        rotationLimits.right = value

        return interface
    end
    function interface:rightLimit(value) return interface:setRightLimit(value) end -- Alias

    return interface
end



function smoothie:newPhysicalBody(modelPart)
    -- Checking the validity of the parameter
    assert(type(modelPart) == "ModelPart", "Invalid argument to function newPhysicalBody. Expected ModelPart, but got " .. type(modelPart))

    -- Setting up some variables
    local interface = {}
    local physicalModelPart = modelPart
    local bodyYaw, prevBodyYaw, bodyYawDelta = 0, 0, 0
    local playerVerticalVelocity, prevPlayerVerticalVelocity, playerVerticalVelocityDelta = 0, 0, 0
    local physBodyRotationVelocity = vec(0, 0, 0)
    local bouncy = 0.5
    local speed = 150
    local rotationLimits = {top = 45, bottom = 45, left = 15, right = 15}

    -- Initialization
    if player:isLoaded() then bodyYaw, prevBodyYaw = player:getBodyYaw(), player:getBodyYaw() end

    -- Physical body processor
    events.RENDER:register(function(delta)
        if not player:isLoaded() then return end

        -- Calculating the difference in body yaw
        bodyYaw = player:getBodyYaw()
        bodyYawDelta = bodyYawDelta + (bodyYaw - prevBodyYaw)
        prevBodyYaw = bodyYaw


        -- Calculating the difference in player's vectical velocity
        playerVerticalVelocity = player:getVelocity().y
        playerVerticalVelocityDelta = playerVerticalVelocityDelta + (playerVerticalVelocity - prevPlayerVerticalVelocity)
        prevPlayerVerticalVelocity = playerVerticalVelocity

        local deltas = vec(-playerVerticalVelocityDelta * 100, bodyYawDelta, bodyYawDelta)

        -- Calculation the physical body rotation
        physBodyRotationVelocity = physBodyRotationVelocity + -(speed * (physicalModelPart:getOffsetRot() - deltas) + math.sqrt(speed * bouncy) / 2 * physBodyRotationVelocity / math.max(bouncy, 0.01)) / math.max(client:getFPS(), 1)
        local physBodyRotation = physicalModelPart:getOffsetRot() + physBodyRotationVelocity / math.max(client:getFPS(), 1)
        physBodyRotation[1] = math.clamp(physBodyRotation[1], -rotationLimits.bottom, rotationLimits.top)
        physBodyRotation[2] = math.clamp(physBodyRotation[2], -rotationLimits.left, rotationLimits.right)
        physBodyRotation[3] = math.clamp(physBodyRotation[3], -rotationLimits.left, rotationLimits.right)

        physicalModelPart:setOffsetRot(physBodyRotation)

        -- Soft reduction of deltas to zeros
        playerVerticalVelocityDelta = math.lerp(playerVerticalVelocityDelta, 0, 15 / math.max(client:getFPS(), 1))
        bodyYawDelta = math.lerp(bodyYawDelta, 0, 15 / math.max(client:getFPS(), 1))
    end, "Smoothie.physicalBodyProcessor")

    function interface:setSpeed(value)
        assert(type(value) == "number", "Invalid argument to function setSpeed. Expected number, but got " .. type(value))
        speed = value

        return interface
    end
    function interface:speed(value) return interface:setSpeed(value) end -- Alias

    function interface:setBouncy(value)
        assert(type(value) == "number", "Invalid argument to function setBouncy. Expected number, but got " .. type(value))
        bouncy = value

        return interface
    end
    function interface:bouncy(value) return interface:setBouncy(value) end -- Alias

    function interface:setTopLimit(value)
        assert(type(value) == "number", "Invalid argument to function setTopLimit. Expected number, but got " .. type(value))
        rotationLimits.top = value

        return interface
    end
    function interface:topLimit(value) return interface:setTopLimit(value) end -- Alias

    function interface:setBottomLimit(value)
        assert(type(value) == "number", "Invalid argument to function setBottomLimit. Expected number, but got " .. type(value))
        rotationLimits.bottom = value

        return interface
    end
    function interface:bottomLimit(value) return interface:setBottomLimit(value) end -- Alias

    function interface:setLeftLimit(value)
        assert(type(value) == "number", "Invalid argument to function setLeftLimit. Expected number, but got " .. type(value))
        rotationLimits.left = value

        return interface
    end
    function interface:leftLimit(value) return interface:setLeftLimit(value) end -- Alias

    function interface:setRightLimit(value)
        assert(type(value) == "number", "Invalid argument to function setRightLimit. Expected number, but got " .. type(value))
        rotationLimits.right = value

        return interface
    end
    function interface:rightLimit(value) return interface:setRightLimit(value) end -- Alias

    return interface
end



function smoothie:setEyesPivot(modelPart)
    -- Checking the validity of the parameter
    assert(type(modelPart) == "ModelPart", "Invalid argument to function setEyesPivot. Expected ModelPart, but got " .. type(modelPart))

    local eyesPivotModelPart = modelPart
    local eyesOffset = vec(0, 0, 0)

    events.POST_RENDER:remove("Smoothie.eyesPivotProcessor")
    events.POST_RENDER:register(function()
        if not player:isLoaded() then return end

        local newEyesOffset = eyesPivotModelPart:partToWorldMatrix():apply() - vanillaEyesPoint:partToWorldMatrix():apply()
        newEyesOffset = newEyesOffset + vanilla_model.HEAD:getOriginPos() / 16
        if newEyesOffset:length() ~= newEyesOffset:length() then return end -- Cathing the NaN

        eyesOffset = newEyesOffset
        renderer:offsetCameraPivot(eyesOffset)
        renderer:setEyeOffset(eyesOffset)
    end, "Smoothie.eyesPivotProcessor")
end

return smoothie
