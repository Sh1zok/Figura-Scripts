--[[
    ■■■■■ TextureMerger
    ■   ■ Source: https://github.com/Sh1zok/Figura-Scripts/tree/main/TextureMerger
    ■■■■  v1.3.0

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

function apiCustoms:mergeTextures(changeableTexture, changingTexture, blendingFactor, doNotUpdate, chromaColor)
    -- Assertation
    assert(type(changeableTexture) == "Texture", "Invalid argument 1 to function mergeTextures. Expected Texture, but got " .. type(changeableTexture))
    assert(type(changingTexture) == "Texture", "Invalid argument 2 to function mergeTextures. Expected Texture or Table, but got " .. type(changingTexture))
    assert(type(blendingFactor) == "number" or not blendingFactor, "Invalid argument 3 to function mergeTextures. Expected number or nil, but got " .. type(blendingFactor))
    assert(type(chromaColor) == "Vector3" or type(chromaColor) == "string" or not chromaColor, "Invalid argument 5 to function mergeTextures. Expected Vecrot3 or string or nil, but got " .. type(chromaColor))

    -- Parsing chroma color
    if chromaColor then
        if type(chromaColor) == "string" then chromaColor = vectors:hexToRGB(chromaColor) end
        chromaColor = vec(chromaColor[1], chromaColor[2], chromaColor[3], 1)
    end

    -- Some locals
    local changeableTextureDimensions, changingTextureDimensions = changeableTexture:getDimensions(), changingTexture:getDimensions()
    local mergeAreaWidth, mergeAriaHeight = math.min(changeableTextureDimensions.x, changingTextureDimensions.x), math.min(changeableTextureDimensions.y, changingTextureDimensions.y)

    -- A function that merges pixel colors
    local function mergeFunction(changablePixelColor, changablePixelX, changablePixelY)
        local changingPixelColor = changingTexture:getPixel(changablePixelX, changablePixelY)
        local alpha = math.clamp(changingPixelColor[4] * (blendingFactor or 1), 0, 1)

        if changingPixelColor == chromaColor then return vec(0, 0, 0, 0) end
        return vec(
            math.clamp(changingPixelColor[1] * alpha + changablePixelColor[1] * (1 - alpha), 0, 1),
            math.clamp(changingPixelColor[2] * alpha + changablePixelColor[2] * (1 - alpha), 0, 1),
            math.clamp(changingPixelColor[3] * alpha + changablePixelColor[3] * (1 - alpha), 0, 1),
            math.clamp(alpha + changablePixelColor[4] * (1 - alpha), 0, 1)
        )
    end

    -- Applies merge function to texture and returns the mergedTexture as a result
    if not doNotUpdate then
        return changeableTexture:applyFunc(0, 0, mergeAreaWidth, mergeAriaHeight, mergeFunction):update()
    else
        return changeableTexture:applyFunc(0, 0, mergeAreaWidth, mergeAriaHeight, mergeFunction)
    end
end
