--[[
    ■■■■■ LooksCrafter
    ■   ■ Source: https://github.com/Sh1zok/Figura-Scripts/tree/main/LooksCrafter
    ■■■■  v1.1.1

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



local handlers = {}
local modelPartsDefaultVisibilityStates = {}
local API = {}



local function tableDeepCopy(table)
    local copy = {}
    for key, value in pairs(table) do
        if type(value) == "table" then copy[key] = tableDeepCopy(value) end
        copy[key] = value
    end

    return copy
end

local function mergeTextures(changeableTexture, changingTexture, chromaKeyColor)
    local changeableTextureDimensions, changingTextureDimensions = changeableTexture:getDimensions(), changingTexture:getDimensions()
    local mergeAreaWidth, mergeAriaHeight = math.min(changeableTextureDimensions.x, changingTextureDimensions.x), math.min(changeableTextureDimensions.y, changingTextureDimensions.y)

    local function mergeFunction(changablePixelColor, changablePixelX, changablePixelY)
        local changingPixelColor = changingTexture:getPixel(changablePixelX, changablePixelY)

        if changingPixelColor == chromaKeyColor then return vec(0, 0, 0, 0) end
        return vec(
            math.clamp(changingPixelColor[1] * changingPixelColor[4] + changablePixelColor[1] * (1 - changingPixelColor[4]), 0, 1),
            math.clamp(changingPixelColor[2] * changingPixelColor[4] + changablePixelColor[2] * (1 - changingPixelColor[4]), 0, 1),
            math.clamp(changingPixelColor[3] * changingPixelColor[4] + changablePixelColor[3] * (1 - changingPixelColor[4]), 0, 1),
            math.clamp(changingPixelColor[4] + changablePixelColor[4] * (1 - changingPixelColor[4]), 0, 1)
        )
    end

    return changeableTexture:applyFunc(0, 0, mergeAreaWidth, mergeAriaHeight, mergeFunction)
end

function pings.synchronizeSlotItem(textureName, slotName, itemName, shouldUpdateLook)
    local textureHandler = handlers[textures[textureName]]
    if not host:isHost() then textureHandler:setSlot(slotName, itemName, not shouldUpdateLook) end

    if shouldUpdateLook then textureHandler:updateLook() end
end



function API:getHandler(textureFilter)
    assert(type(textureFilter) == "Texture" or not textureFilter, "Invalid argument to function getHandler. Expected Texture, but got " .. type(textureFilter))

    if textureFilter then return handlers[textureFilter] end
    return tableDeepCopy(handlers)
end

function API:newHandler(baseTexture, customConfigName)
    assert(type(baseTexture) == "Texture", "Invalid argument 1 to function newHandler. Expected Texture, but got " .. type(baseTexture))
    assert(not self:getHandler(baseTexture), "This texture(" .. baseTexture:getName() .. ") is already has a handler")
    assert(type(customConfigName) == "string" or not customConfigName, "Invalid argument 2 to function newHandler. Expected string or nil, but got " .. type(customConfigName))

    local slots = {}
    local slotPriorities = {}
    local slotEquippedItems = {}

    local syncCooldownSeconds = 60
    local syncMaxIterationsPerSync = 5

    local configName = customConfigName or avatar:getName() .. "_LooksCrafter_" .. baseTexture:getName()

    local interface = {}

    function interface:updateLook()
        baseTexture:restore()
        for modelPart, visibilityState in pairs(modelPartsDefaultVisibilityStates) do
            modelPart:setVisible(visibilityState)
            modelPartsDefaultVisibilityStates[modelPart] = nil
        end

        for _, slotName in pairs(slotPriorities) do
            if slotEquippedItems[slotName] then
                mergeTextures(baseTexture, slots[slotName][slotEquippedItems[slotName]].texture, slots[slotName][slotEquippedItems[slotName]].chromaKeyColor)

                if slots[slotName][slotEquippedItems[slotName]].modelParts then
                    for modelPart, visibilityState in pairs(slots[slotName][slotEquippedItems[slotName]].modelParts) do
                        modelPartsDefaultVisibilityStates[modelPart] = modelPart:getVisible()
                        modelPart:setVisible(visibilityState)
                    end
                end
            end
        end

        baseTexture:update()
        return self
    end

    function interface:changeBaseTexture(newBaseTexture)
        assert(type(newBaseTexture) == "Texture", "Invalid argument to function changeBaseTexture. Expected Texture, but got " .. type(newBaseTexture))
        assert(not self:getHandler(newBaseTexture), "This texture(" .. newBaseTexture:getName() .. ") is already has a handler")

        baseTexture = newBaseTexture

        return self:updateLook()
    end

    function interface:newSlot(name, priority, defaultItemName, items)
        assert(type(name) == "string", "Invalid argument 1 to function newSlot. Expected string, but got " .. type(name))
        assert(type(priority) == "number", "Invalid argument 2 to function newSlot. Expected number, but got " .. type(priority))
        assert(type(defaultItemName) == "string" or not defaultItemName, "Invalid argument 3 to function newSlot. Expected string, nil or false, but got " .. type(defaultItemName))
        assert(type(items) == "table", "Invalid argument 4 to function newSlot. Expected table, but got " .. type(items))
        assert(items[defaultItemName] or not defaultItemName, "Invalid default item name.")
        assert(not slotPriorities[priority], "This priority(" .. priority .. ") is already occupied")
        assert(not slots[name], "This name(" .. name .. ") is already occupied")

        slots[name] = items
        slotPriorities[priority] = name

        local oldConfigName = config:getName()
        config:setName(configName)

        -- Prevents config corruption with item names that no longer exists
        if config:load(name) and not items[config:load(name)] then config:save(name, nil) end

        -- Equips first item from table to prevent nudity
        slotEquippedItems[name] = config:load(name) or defaultItemName
        -- Since `false` indicates that there is no item in the slot, we set the default value only if the value is EXACTLY `nil`
        if slotEquippedItems[name] == nil then pairs(items)(items) end

        if not config:load(name) then config:save(name, slotEquippedItems[name]) end
        config:setName(oldConfigName)

        return self:updateLook()
    end

    function interface:setSlot(slotName, itemName, shouldNotUpdateLook)
        assert(type(slotName) == "string", "Invalid argument 1 to function setSlot. Expected string, but got " .. type(slotName))
        assert(type(itemName) == "string" or itemName == false, "Invalid argument 2 to function setSlot. Expected string or false, but got " .. type(itemName))
        assert(slots[slotName], "Invalid slot name in argument 1 to function setSlot.")
        assert(slots[slotName][itemName] or itemName == false, "Invalid item name in argument 2 to function setSlot.")

        if host:isHost() then
            local oldConfigName = config:getName()
            config:setName(configName)
            config:save(slotName, itemName)
            config:setName(oldConfigName)
        end

        local oldItemName
        if slots[slotName][slotEquippedItems[slotName]].onUnequip and slotEquippedItems[slotName] ~= itemName then slots[slotName][slotEquippedItems[slotName]]:onUnequip() end
        oldItemName, slotEquippedItems[slotName] = slotEquippedItems[slotName], itemName
        if slots[slotName][slotEquippedItems[slotName]].onEquip and itemName ~= oldItemName then slots[slotName][slotEquippedItems[slotName]]:onEquip() end

        pings.synchronizeSlotItem(baseTexture:getName(), slotName, itemName, true)

        if shouldNotUpdateLook then return self else return self:updateLook() end
    end

    function interface:getItemInSlot(slotName)
        assert(type(slotName) == "string", "Invalid argument to function getItemInSlot. Expected string, but got " .. type(slotName))
        return slotEquippedItems[slotName]
    end

    function interface:getSlots() return tableDeepCopy(slots) end

    function interface:setSyncCooldown(seconds)
        assert(type(seconds) == "number", "Invalid argument to function setSyncCooldown. Expected number, but got " .. type(seconds))
        syncCooldownSeconds = seconds

        return self
    end

    function interface:setMaxParallelSyncs(newSyncMaxIterationsPerSync)
        assert(type(newSyncMaxIterationsPerSync) == "number", "Invalid argument to function setMaxParallelSyncs. Expected number, but got " .. type(newSyncMaxIterationsPerSync))
        syncMaxIterationsPerSync = newSyncMaxIterationsPerSync

        return self
    end



    if host:isHost() then
        local syncedSlotNames = {}
        local ticksSinceLastSync = (syncCooldownSeconds * 0.9) * 20
        local syncIterationIndex = 1
        events.tick:register(function()
            if ticksSinceLastSync / 20 >= syncCooldownSeconds then
                local oldConfigName = config:getName()
                config:setName(configName)
                local configContent = config:load()
                config:setName(oldConfigName)

                for slotName in pairs(slots) do
                    if not syncedSlotNames[slotName] then
                        pings.synchronizeSlotItem(baseTexture:getName(), slotName, configContent[slotName], syncIterationIndex > syncMaxIterationsPerSync or #syncedSlotNames >= #slots)

                        syncIterationIndex = syncIterationIndex + 1
                        syncedSlotNames[slotName] = true
                    end

                    if syncIterationIndex > syncMaxIterationsPerSync or #syncedSlotNames >= #slots then
                        syncIterationIndex = 1
                        syncedSlotNames = {}
                        break
                    end
                end

                ticksSinceLastSync = -1
            end

            ticksSinceLastSync = ticksSinceLastSync + 1
        end, baseTexture:getName() .. "_lookHandlerSync")
    end



    interface = setmetatable(interface, {__newindex = function() error("Cannot assign new method/field to a handler", 2) end})

    handlers[baseTexture] = interface
    return interface
end



return API
