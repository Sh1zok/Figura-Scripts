--[[
    ■■■■■ TextureMerger
    ■   ■ Source: https://github.com/Sh1zok/Figura-Scripts/tree/main/TextureMerger
    ■■■■  v1.1.2

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

--#region Modifies TextureAPI metatable
local apiMetatable = figuraMetatables.TextureAPI
local apiOriginalIndexMethod = apiMetatable.__index
local apiCustoms = {}

-- Checks the custom methods table first. If it finds something, it returns that. If it doesn't it uses the original __index method to find something instead
function apiMetatable:__index(key) return apiCustoms[key] or apiOriginalIndexMethod(self, key) end
--#endregion

function apiCustoms:mergeTextures(changeableTexture, changingTexture, mergedTextureName, blendingFactor)
    -- Assertation
    assert(type(changeableTexture) == "Texture", "Invalid argument 1 to function mergeTextures. Expected Texture, but got " .. type(changeableTexture))
    assert(type(changingTexture) == "Texture", "Invalid argument 2 to function mergeTextures. Expected Texture or Table, but got " .. type(changingTexture))
    assert(type(mergedTextureName) == "string" or not mergedTextureName, "Invalid argument 3 to function mergeTextures. Expected string or nil, but got " .. type(mergedTextureName))
    assert(type(blendingFactor) == "number" or not blendingFactor, "Invalid argument 4 to function mergeTextures. Expected number or nil, but got " .. type(blendingFactor))

    -- Some locals
    local mergedTexture = textures:copy(mergedTextureName or "merged." .. client:intUUIDToString(client:generateUUID()):sub(1, 8), changeableTexture)
    local changeableTextureDimensions, changingTextureDimensions = changeableTexture:getDimensions(), changingTexture:getDimensions()
    local mergeAreaWidth, mergeAriaHeight = math.min(changeableTextureDimensions.x, changingTextureDimensions.x), math.min(changeableTextureDimensions.y, changingTextureDimensions.y)

    -- A function that merges pixel colors
    local function mergeFunction(changablePixelColor, changablePixelX, changablePixelY)
        local alpha = math.clamp(changingPixelColor[4] * (blendingFactor or 1), 0, 1)
        local changingPixelColor = changingTexture:getPixel(changablePixelX, changablePixelY)
        return vec(
            math.clamp(changingPixelColor[1] * alpha + changablePixelColor[1] * (1 - alpha), 0, 1),
            math.clamp(changingPixelColor[2] * alpha + changablePixelColor[2] * (1 - alpha), 0, 1),
            math.clamp(changingPixelColor[3] * alpha + changablePixelColor[3] * (1 - alpha), 0, 1),
            math.clamp(alpha + changablePixelColor[4] * (1 - alpha), 0, 1)
        )
    end

    -- Applies merge function to texture and returns the mergedTexture as a result
    return mergedTexture:applyFunc(0, 0, mergeAreaWidth, mergeAriaHeight, mergeFunction)
end
