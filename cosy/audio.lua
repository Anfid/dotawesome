---------------------------------------------------------------------------
--- Audio control
--
-- @module cosy
---------------------------------------------------------------------------

local awful = require("awful")
local awesome = _G.awesome
local posix_signal = require("posix.signal")
local naughty = require("naughty")

local audio = {}
audio.volume = {}
audio.mute = {}
audio.sink = 0

-- Init subscription to volume events
audio.subscription_pid = awful.spawn.with_line_callback("pactl subscribe", {
    stdout = function(line)
        local event, upd_sink = line:match("Event '(%a+)' on sink #(%d)")
        upd_sink = tonumber(upd_sink)
        if event == "change" and upd_sink ~= nil then
            audio:sink_info_update()
        end
    end,
    stderr = function(line)
        -- TODO: Reconnect on error?
        naughty.notify({
                preset = naughty.config.presets.critical,
                title = "Audio",
                text = line,
            })
    end
})

function audio:sink_info_update()
    awful.spawn.easy_async(
        "pactl list sinks",
        function(out)
            for sink, mute, vol in out:gmatch(
                    "Sink #(%d+).*"..
                    "\n%s*Mute:%s*(%a+).*"..
                    "\n%s*Volume:[^\n]-(%d+)%%[^\n]*\n"
                ) do
                local sink = tonumber(sink)
                local vol = tonumber(vol)
                local mute = mute == "yes"
                if self.volume[sink] ~= vol then
                    self.volume[sink] = vol
                    awesome.emit_signal("audio::volume")
                end

                if self.mute[sink] ~= mute then
                    self.mute[sink] = mute
                    awesome.emit_signal("audio::mute")
                end
            end
        end
    )
end

-- Init default sink
awful.spawn.easy_async("pactl list sinks short",
    function(out)
        audio.sink = tonumber(out:match("^(%d).*\n"))
        awesome.emit_signal("audio::volume")
    end
)

audio:sink_info_update()

function audio:volume_get(sink)
    local sink = sink or self.sink
    return self.volume[sink]
end

function audio:volume_set(val, sink)
    local sink = sink or self.sink
    awful.spawn("pactl set-sink-volume "..sink.." "..val)
end

function audio:volume_mute(val, sink)
    local sink = sink or self.sink
    local val = val and tostring(val) or "toggle"

    awful.spawn("pactl set-sink-mute "..sink.." "..tostring(val))
end

audio.mt = {}

function audio.mt:__gc()
    posix_signal.kill(self.subscription_pid)
end

return setmetatable(audio, audio.mt)
