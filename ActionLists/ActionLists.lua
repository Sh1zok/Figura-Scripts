--[[
    ■■■■■ ActionLists
    ■   ■ Author: @sh1zok_was_here
    ■■■■  v1.5.0

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

local blankTexture = textures:newTexture("ActionLists.blankTexture", 1, 1)

--#region Modifying pages metatable
local pagesMetatable = figuraMetatables.Page -- Link to the pages metatable. If something here was changed, it will change in figurаMetatable.Page too
local pagesOriginalIndexMethod = pagesMetatable.__index -- Save the original __index method for future use
local pagesCustomMethods = {} -- Custom methods for pages

-- Checks the custom methods table first. If it finds something, it returns that. If it doesn't it uses the original __index method to find something instead.
function pagesMetatable:__index(key)
    if pagesCustomMethods[key] then return pagesCustomMethods[key] end
    return pagesOriginalIndexMethod(self, key)
end
--#endregion

--#region The action list logic
function pagesCustomMethods:newActionList()
    --[[
        Setting up some variables
    ]]--
    local interface = {} -- The interface through which interactions with the action list are performed
    local userdata = self:newAction() -- The button that appears in the action wheel
    local selectedActionIndex = 1 -- Index of the selected action
    local visualSize = 7 -- Length of the visible part of the list on the screen
    local actionListTitle = "" -- Title of actionList. Can be a string or a table(for JSON)
    local defaultColor, defaultHoverColor, defaultItem, defaultHoverItem -- Default stuff are only visible when the selected action does not have any of the things listed here
    local defaultTexture, defaultHoverTexture = {}, {}
    local selectedActionColor, actionListColor = vec(1, 1, 1), vec(0.75, 0.75, 0.75)
    local actionList = { -- The action list itself
        [1] = {
            title = "This action list is empty...",
            onRightClick = function() host:setActionbar("Sh1zok was here ;3") end -- Easter egg :p
        }
    }
    local globalOnLeftClick, globalOnRightClick, globalOnScroll

    -- New title for button(userdata) maker
    local function makeNewTitle()
        local title -- New title for button
        if type(actionListTitle) == "string" then title = {{text = actionListTitle}} end
        if type(actionListTitle) == "table" then title = {actionListTitle} end

        -- Calculating visual indexes limits
        local topVisualIndex = selectedActionIndex - math.floor(visualSize / 2)
        local bottomVisualIndex = selectedActionIndex + math.floor(visualSize / 2)
        if bottomVisualIndex - topVisualIndex > visualSize then bottomVisualIndex = bottomVisualIndex - 1 end
        if topVisualIndex < 1 then
            topVisualIndex = 1
            bottomVisualIndex = visualSize
        end
        if bottomVisualIndex > #actionList then
            bottomVisualIndex = bottomVisualIndex - (bottomVisualIndex - #actionList) + 1
            topVisualIndex = bottomVisualIndex - visualSize
        end

        -- Adding a action list under the button title
        for index, value in ipairs(actionList) do
            if index >= topVisualIndex and index <= bottomVisualIndex then
                if index == selectedActionIndex then
                    table.insert(title, {text = "\n " .. "=> ", color = "#" .. vectors.rgbToHex(selectedActionColor)})
                    if type(value.title) == "table" then
                        table.insert(title, value.activeTitle or value.title)
                    else
                        table.insert(title, {text = value.activeTitle or value.title, color = "#" .. vectors.rgbToHex(selectedActionColor)})
                    end
                else
                    table.insert(title, {text = "\n " .. index .. ". ", color = "#" .. vectors.rgbToHex(actionListColor)})
                    if type(value.title) == "table" then
                        table.insert(title, value.title)
                    else
                        table.insert(title, {text = value.title, color = "#" .. vectors.rgbToHex(actionListColor)})
                    end
                end
            end
        end

        return toJson(title) -- Returns JSON
    end
    userdata.setTitle(userdata, makeNewTitle()) -- Making entry title



    --[[
        Interface setters: List&Title appearance
            After every setting title getting an update. Sometimes it can eat too many resources. 
            If there is too much init instructions you can choose to don't update title with true in optional parameter.
    ]]--
    function interface:setTitle(title, shouldntMakeNewTitle)
        if title == nil then title = "" end
        assert(type(title) == "string" or type(title) == "table", "Invalid argument to function setTitle. Expected string or Table, but got " .. type(table))
        actionListTitle = title

        if not shouldntMakeNewTitle then userdata.setTitle(userdata, makeNewTitle()) end
        return interface -- Returns self for chaining
    end
    function interface:title(title, shouldntMakeNewTitle) return interface:setTitle(title, shouldntMakeNewTitle) end -- Alias

    function interface:setActionList(table, shouldntMakeNewTitle)
        if table == nil then table = {} end
        assert(type(table) == "table", "Invalid argument to function setActionList. Expected Table, but got " .. type(table))
        actionList = table

        if not shouldntMakeNewTitle then userdata.setTitle(userdata, makeNewTitle()) end
        return interface -- Returns self for chaining
    end
    function interface:actionList(table, shouldntMakeNewTitle) return interface:setActionList(table, shouldntMakeNewTitle) end -- Alias

    function interface:setActionListColor(colorOrR, g, b, shouldntMakeNewTitle)
        if g ~= nil or b ~= nil then
            assert(type(colorOrR) == "number", "Invalid argument 1 to function setActionListColor. Expected number, but got " .. type(colorOrR))
            assert(type(g) == "number", "Invalid argument 2 to function setActionListColor. Expected number, but got " .. type(g))
            assert(type(b) == "number", "Invalid argument 3 to function setActionListColor. Expected number, but got " .. type(b))

            colorOrR = vec(colorOrR, g, b)
        end

        if colorOrR == nil then colorOrR = vec(0, 0, 0) end
        assert(type(colorOrR) == "Vector3", "Invalid argument to function setActionListColor. Expected Vector3, but got " .. type(colorOrR))
        actionListColor = colorOrR

        if not shouldntMakeNewTitle then userdata.setTitle(userdata, makeNewTitle()) end
        return interface -- Returns self for chaining
    end
    function interface:actionListColor(colorOrR, g, b, shouldntMakeNewTitle) return interface:setActionListColor(colorOrR, g, b, shouldntMakeNewTitle) end -- Alias

    function interface:setSelectedActionColor(colorOrR, g, b, shouldntMakeNewTitle)
        if g ~= nil or b ~= nil then
            assert(type(colorOrR) == "number", "Invalid argument 1 to function setSelectedActionColor. Expected number, but got " .. type(colorOrR))
            assert(type(g) == "number", "Invalid argument 2 to function setSelectedActionColor. Expected number, but got " .. type(g))
            assert(type(b) == "number", "Invalid argument 3 to function setSelectedActionColor. Expected number, but got " .. type(b))

            colorOrR = vec(colorOrR, g, b)
        end

        if colorOrR == nil then colorOrR = vec(0, 0, 0) end
        assert(type(colorOrR) == "Vector3", "Invalid argument to function setSelectedActionColor. Expected Vector3, but got " .. type(colorOrR))
        selectedActionColor = colorOrR

        if not shouldntMakeNewTitle then userdata.setTitle(userdata, makeNewTitle()) end
        return interface -- Returns self for chaining
    end
    function interface:selectedActionColor(colorOrR, g ,b, shouldntMakeNewTitle) return  interface:setSelectedActionColor(colorOrR, g, b, shouldntMakeNewTitle) end -- Alias

    function interface:setSelectedActionIndex(index, shouldntMakeNewTitle)
        if index == nil then index = 1 end
        assert(type(index) == "number", "Invalid argument to function setSelectedAction. Expected number, but got " .. type(index))
        selectedActionIndex = index

        if not shouldntMakeNewTitle then userdata.setTitle(userdata, makeNewTitle()) end
        return interface -- Returns self for chaining
    end
    function interface:selectedActionIndex(index, shouldntMakeNewTitle) return interface:setSelectedAction(index, shouldntMakeNewTitle) end -- Alias

    function interface:setVisualSize(size, shouldntMakeNewTitle)
        if size == nil then size = 7 end
        assert(type(size) == "number", "Invalid argument to function setVisualSize. Expected number, but got " .. type(index))
        visualSize = size

        if not shouldntMakeNewTitle then userdata.setTitle(userdata, makeNewTitle()) end
        return interface -- Returns self for chaining
    end
    function interface:visualSize(size, shouldntMakeNewTitle) return interface:setVisualSize(size, shouldntMakeNewTitle) end -- Alias



    --[[
        Interface setters: Button(userdata) appearance
    ]]--
    function interface:setColor(colorOrR, g, b)
        if g ~= nil or b ~= nil then
            assert(type(colorOrR) == "number", "Invalid argument 1 to function setColor. Expected number, but got " .. type(colorOrR))
            assert(type(g) == "number", "Invalid argument 2 to function setColor. Expected number, but got " .. type(g))
            assert(type(b) == "number", "Invalid argument 3 to function setColor. Expected number, but got " .. type(b))

            colorOrR = vec(colorOrR, g, b)
        end

        if colorOrR == nil then colorOrR = vec(0, 0, 0) end
        assert(type(colorOrR) == "Vector3", "Invalid argument to function setColor. Expected Vector3, but got " .. type(colorOrR))
        defaultColor = colorOrR

        userdata:setColor(actionList[selectedActionIndex].color or defaultColor)
        return interface -- Returns self for chaining
    end
    function interface:color(colorOrR, g, b) return interface:setColor(colorOrR, g, b) end -- Alias

    function interface:setHoverColor(colorOrR, g, b)
        if g ~= nil or b ~= nil then
            assert(type(colorOrR) == "number", "Invalid argument 1 to function setHoverColor. Expected number, but got " .. type(colorOrR))
            assert(type(g) == "number", "Invalid argument 2 to function setHoverColor. Expected number, but got " .. type(g))
            assert(type(b) == "number", "Invalid argument 3 to function setHoverColor. Expected number, but got " .. type(b))

            colorOrR = vec(colorOrR, g, b)
        end

        if colorOrR == nil then colorOrR = vec(0, 0, 0) end
        assert(type(colorOrR) == "Vector3", "Invalid argument to function setHoverColor. Expected Vector3, but got " .. type(colorOrR))
        defaultHoverColor = colorOrR

        userdata:setHoverColor(actionList[selectedActionIndex].hoverColor or defaultHoverColor)
        return interface -- Returns self for chaining
    end
    function interface:hoverColor(colorOrR, g, b) return interface:setHoverColor(colorOrR, g, b) end -- Alias

    function interface:setItem(item)
        if item == nil then item = "minecraft:air" end
        assert(type(item) == "string", "Invalid argument to function setItem. Expected string, but got " .. type(item))
        defaultItem = item

        userdata:setItem(actionList[selectedActionIndex].item or defaultItem)
        return interface -- Returns self for chaining
    end
    function interface:item(item) return interface:setItem(item) end -- Alias

    function interface:setHoverItem(item)
        if item == nil then item = defaultItem end
        assert(type(item) ~= "string", "Invalid argument to function setHoverItem. Expected string, but got " .. type(item))
        defaultHoverItem = item

        userdata:setHoverItem(actionList[selectedActionIndex].hoverItem or defaultHoverItem)
        return interface -- Returns self for chaining
    end
    function interface:hoverItem(item) return interface:setHoverItem(item) end -- Alias

    function interface:setTexture(texture, u, v, width, height, scale)
        assert(type(texture) == "Texture", "Invalid argument 1 to function setTexture. Expected Texture, but got " .. type(texture))

        if u or v then
            assert(type(u) == "number", "Invalid argument 2 to function setTexture. Expected number, but got " .. type(u))
            assert(type(v) == "number", "Invalid argument 3 to function setTexture. Expected number, but got " .. type(v))
        end

        if width or height then
            assert(type(width) == "number", "Invalid argument 4 to function setTexture. Expected number, but got " .. type(width))
            assert(type(height) == "number", "Invalid argument 5 to function setTexture. Expected number, but got " .. type(height))
        end

        if scale then assert(type(scale) == "number", "Invalid argument 6 to function setTexture. Expected number, but got " .. type(scale)) end
        defaultTexture = {texture, u, v, width, height, scale}

        if actionList[selectedActionIndex].texture then -- Prevents indexing a sometimes nil value(actionList[selectedActionIndex].texture) with some keys
            userdata:setTexture(
                actionList[selectedActionIndex].texture[1] or defaultTexture[1],
                actionList[selectedActionIndex].texture[2] or defaultTexture[2],
                actionList[selectedActionIndex].texture[3] or defaultTexture[3],
                actionList[selectedActionIndex].texture[4] or defaultTexture[4],
                actionList[selectedActionIndex].texture[5] or defaultTexture[5],
                actionList[selectedActionIndex].texture[6] or defaultTexture[6]
            )
        else
            userdata:setTexture(defaultTexture[1], defaultTexture[2], defaultTexture[3], defaultTexture[4], defaultTexture[5], defaultTexture[6])
        end

        return interface -- Returns self for chaining
    end
    function interface:texture(texture, u, v, width, height, scale) return interface:setTexture(texture, u, v, width, height, scale) end -- Alias

    function interface:setHoverTexture(texture, u, v, width, height, scale)
        assert(type(texture) == "Texture", "Invalid argument 1 to function setHoverTexture. Expected Texture, but got " .. type(texture))

        if u or v then
            assert(type(u) == "number", "Invalid argument 2 to function setHoverTexture. Expected number, but got " .. type(u))
            assert(type(v) == "number", "Invalid argument 3 to function setHoverTexture. Expected number, but got " .. type(v))
        end

        if width or height then
            assert(type(width) == "number", "Invalid argument 4 to function setHoverTexture. Expected number, but got " .. type(width))
            assert(type(height) == "number", "Invalid argument 5 to function setHoverTexture. Expected number, but got " .. type(height))
        end

        if scale then assert(type(scale) == "number", "Invalid argument 6 to function setHoverTexture. Expected number, but got " .. type(scale)) end
        defaultHoverTexture = {texture, u, v, width, height, scale}

        if actionList[selectedActionIndex].hoverTexture then
            userdata:setHoverTexture(
                actionList[selectedActionIndex].hoverTexture[1] or defaultHoverTexture[1],
                actionList[selectedActionIndex].hoverTexture[2] or defaultHoverTexture[2],
                actionList[selectedActionIndex].hoverTexture[3] or defaultHoverTexture[3],
                actionList[selectedActionIndex].hoverTexture[4] or defaultHoverTexture[4],
                actionList[selectedActionIndex].hoverTexture[5] or defaultHoverTexture[5],
                actionList[selectedActionIndex].hoverTexture[6] or defaultHoverTexture[6]
            )
        else
            userdata:setHoverTexture(defaultHoverTexture[1], defaultHoverTexture[2], defaultHoverTexture[3], defaultHoverTexture[4], defaultHoverTexture[5], defaultHoverTexture[6])
        end

        return interface -- Returns self for chaining
    end
    function interface:hoverTexture(texture, u, v, width, height, scale) return interface:setHoverTexture(texture, u, v, width, height, scale) end -- Alias



    --[[
        Interface setters: OnAction methods
    ]]--
    function interface:setOnLeftClick(method)
        assert(type(method) == "function", "Invalid argument 1 to function setOnLeftClick. Expected function, but got " .. type(method))
        globalOnLeftClick = method

        return interface -- Returns self for chaining
    end
    function interface:onLeftClick(method) return interface:setOnLeftClick(method) end -- Alias

    function interface:setOnRightClick(method)
        assert(type(method) == "function", "Invalid argument 1 to function setOnRightClick. Expected function, but got " .. type(method))
        globalOnRightClick = method

        return interface -- Returns self for chaining
    end
    function interface:onRightClick(method) return interface:setOnRightClick(method) end -- Alias

    function interface:setOnScroll(method)
        assert(type(method) == "function", "Invalid argument 1 to function setOnScroll. Expected function, but got " .. type(method))
        globalOnScroll = method

        return interface -- Returns self for chaining
    end
    function interface:onScroll(method) return interface:setOnScroll(method) end -- Alias



    --[[
        Interface getters
    ]]--
    function interface:getUserdata() return userdata end
    function interface:getActionList() return actionList end
    function interface:getTitle() return actionListTitle end
    function interface:getVisualSize() return visualSize end
    function interface:getColor() return defaultColor end
    function interface:getHoverColor() return defaultHoverColor end
    function interface:getSelectedActionIndex() return selectedActionIndex end
    function interface:getSelectedActionColor() return selectedActionColor end
    function interface:getActionListColor() return actionListColor end



    --[[
        Button(userdata) custom logic
    ]]--
    userdata:setOnLeftClick(function()
        if actionList[selectedActionIndex].onLeftClick and actionList[selectedActionIndex].onLeftClick then actionList[selectedActionIndex]:onLeftClick() end
        if globalOnLeftClick then globalOnLeftClick() end -- Calling a global onLeftClick method if it is defined
    end)
    userdata:setOnRightClick(function()
        if actionList[selectedActionIndex] and actionList[selectedActionIndex].onRightClick then actionList[selectedActionIndex]:onRightClick() end
        if globalOnRightClick then globalOnRightClick() end -- Calling a global onRightClick method if it is defined
    end)
    userdata:setOnScroll(function(scrollDirection)
        if not actionList[selectedActionIndex] then -- Prevents errors when the list is REALLY empty
            if globalOnScroll then globalOnScroll(scrollDirection, nil) end -- Calling a global onScroll method if it is defined
            return
        end

        if scrollDirection > 0 and selectedActionIndex <= 1 then selectedActionIndex = #actionList + 1 end -- Preventing list out of bounds past the beginning of a list
        if scrollDirection < 0 and selectedActionIndex >= #actionList then selectedActionIndex = 0 end -- Preventing list out of bounds past end of list
        selectedActionIndex = selectedActionIndex - scrollDirection

        if globalOnScroll then globalOnScroll(scrollDirection, selectedActionIndex) end -- Calling a global onScroll method if it is defined

        if actionList[selectedActionIndex].onSelect then actionList[selectedActionIndex]:onSelect(scrollDirection) end

        if actionList[selectedActionIndex].color or defaultColor then userdata:setColor(actionList[selectedActionIndex].color or defaultColor) end
        if actionList[selectedActionIndex].hoverColor or defaultHoverColor then userdata:setHoverColor(actionList[selectedActionIndex].hoverColor or defaultHoverColor) end
        if actionList[selectedActionIndex].item or defaultItem then userdata:setItem(actionList[selectedActionIndex].item or defaultItem) end
        if actionList[selectedActionIndex].hoverItem or defaultHoverItem then userdata:setHoverItem(actionList[selectedActionIndex].hoverItem or defaultHoverItem) end
        if actionList[selectedActionIndex].texture or defaultTexture[1] then
            if actionList[selectedActionIndex].texture then -- Prevents indexing a sometimes nil value(actionList[selectedActionIndex].texture) with some keys
                userdata:setTexture(
                    actionList[selectedActionIndex].texture[1] or defaultTexture[1],
                    actionList[selectedActionIndex].texture[2] or defaultTexture[2],
                    actionList[selectedActionIndex].texture[3] or defaultTexture[3],
                    actionList[selectedActionIndex].texture[4] or defaultTexture[4],
                    actionList[selectedActionIndex].texture[5] or defaultTexture[5],
                    actionList[selectedActionIndex].texture[6] or defaultTexture[6]
                )
            else
                userdata:setTexture(defaultTexture[1], defaultTexture[2], defaultTexture[3], defaultTexture[4], defaultTexture[5], defaultTexture[6])
            end
        else
            userdata:setTexture(blankTexture)
        end
        if actionList[selectedActionIndex].hoverTexture or defaultHoverTexture[1] then
            if actionList[selectedActionIndex].hoverTexture then
                userdata:setHoverTexture(
                    actionList[selectedActionIndex].hoverTexture[1] or defaultHoverTexture[1],
                    actionList[selectedActionIndex].hoverTexture[2] or defaultHoverTexture[2],
                    actionList[selectedActionIndex].hoverTexture[3] or defaultHoverTexture[3],
                    actionList[selectedActionIndex].hoverTexture[4] or defaultHoverTexture[4],
                    actionList[selectedActionIndex].hoverTexture[5] or defaultHoverTexture[5],
                    actionList[selectedActionIndex].hoverTexture[6] or defaultHoverTexture[6]
                )
            else
                userdata:setHoverTexture(defaultHoverTexture[1], defaultHoverTexture[2], defaultHoverTexture[3], defaultHoverTexture[4], defaultHoverTexture[5], defaultHoverTexture[6])
            end
        elseif actionList[selectedActionIndex].texture or defaultTexture[1] then
            if actionList[selectedActionIndex].texture then -- Prevents indexing a sometimes nil value(actionList[selectedActionIndex].texture) with some keys
                userdata:setHoverTexture(
                    actionList[selectedActionIndex].texture[1] or defaultTexture[1],
                    actionList[selectedActionIndex].texture[2] or defaultTexture[2],
                    actionList[selectedActionIndex].texture[3] or defaultTexture[3],
                    actionList[selectedActionIndex].texture[4] or defaultTexture[4],
                    actionList[selectedActionIndex].texture[5] or defaultTexture[5],
                    actionList[selectedActionIndex].texture[6] or defaultTexture[6]
                )
            else
                userdata:setHoverTexture(defaultTexture[1], defaultTexture[2], defaultTexture[3], defaultTexture[4], defaultTexture[5], defaultTexture[6])
            end
        else
            userdata:setHoverTexture(blankTexture)
        end

        userdata.setTitle(userdata, makeNewTitle())
    end)



    --[[
        Returning an interface
    ]]--
    return interface
end
--#endregion
