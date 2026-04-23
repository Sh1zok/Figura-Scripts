--[[
    ■■■■■ VoiceChatLib
    ■   ■ Author: Sh1zok
    ■■■■  v1.0.2

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



--[[
    Initialization
]]--
voiceChat = {
    get = {
        hostVoiceVolume = 0, -- Host's ACCURATE microphone volume level. Float number between 0 and 1
        smoothHostVoiceVolume = 0, -- Host's SMOOTH microphone volume level. Float number between 0 and 1
        rawAudioStream = {}, -- Raw audio data. Indexes from 0 to 959
        isMicrophoneActive = false, -- True if the microphone is active
        ticksUntilRefreshPing = 2,
    },
    hostVoiceVolumeRefreshRateTicks = 2,
    voiceSmoothingStrenght = 20,
    voiceCutoffThreshold = 0.05
}

local zeroRaw = {}
for index = 0, 959 do zeroRaw[index] = 0 end
voiceChat.get.rawAudioStream = zeroRaw




--[[
    Functions
]]--
function voiceChat.calculateVoiceVolume(rawAudio)
    local voiceVolume = 0

    for index = 0, #rawAudio do
        voiceVolume = voiceVolume + math.abs(rawAudio[index])
    end

    return voiceVolume / #rawAudio
end

function pings.voiceChatSync(hostVoiceVolume, isMicrophoneActive)
    voiceChat.get.hostVoiceVolume = hostVoiceVolume
    voiceChat.get.isMicrophoneActive = isMicrophoneActive
end

function events.render()
    voiceChat.get.smoothHostVoiceVolume = math.lerp(
        voiceChat.get.smoothHostVoiceVolume,
        voiceChat.get.hostVoiceVolume,
        math.min(voiceChat.voiceSmoothingStrenght / client:getFPS(), 1)
    )
end

function events.tick()
    if not voiceChat.get.isMicrophoneActive then return end
    voiceChat.get.ticksUntilRefreshPing = voiceChat.get.ticksUntilRefreshPing - 1
    if voiceChat.get.ticksUntilRefreshPing > 0 then return end

    if host:isHost() then pings.voiceChatSync(voiceChat.get.hostVoiceVolume, true) end
    voiceChat.get.ticksUntilRefreshPing = voiceChat.hostVoiceVolumeRefreshRateTicks
end



--[[
    Host-only stuff
]]--
if not host:isHost() or not client:isModLoaded("figurasvc") then return end

-- Reading raw audio stream
function events.host_microphone(audio) voiceChat.get.rawAudioStream = audio end

function events.tick()
    local oldHostVoiceVolume = voiceChat.get.hostVoiceVolume

    voiceChat.get.hostVoiceVolume = voiceChat.calculateVoiceVolume(voiceChat.get.rawAudioStream) / 5250
    if voiceChat.get.hostVoiceVolume <= voiceChat.voiceCutoffThreshold then voiceChat.get.hostVoiceVolume = 0 end

    voiceChat.get.isMicrophoneActive = voiceChat.get.hostVoiceVolume ~= oldHostVoiceVolume
    if not voiceChat.get.isMicrophoneActive and voiceChat.get.hostVoiceVolume ~= 0 then
        pings.voiceChatSync(0, false)
        voiceChat.get.rawAudioStream = zeroRaw
    end
end
