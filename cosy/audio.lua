---------------------------------------------------------------------------
--- Audio control
--
-- @module cosy
---------------------------------------------------------------------------

local awful = require("awful")
local posix_signal = require("posix.signal")
local naughty = require("naughty")

local tonumber = tonumber
local tostring = tostring

local audio = {
    volume = {},
    mute = {},
    sink = 0,
    on_event = {},
}

local signals = {}

function audio.init_pulse_subscription()
    audio.subscription_pid = awful.spawn.with_line_callback("pactl subscribe", {
        stdout = function(line)
            local event, object, id = line:match([[Event '(%a+)' on ([a-z\-]+) #(%d)]])
            local id = tonumber(id)
            audio.on_event[object][event](id)
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
end

-- Event actions
audio.on_event.sink = {}

function audio.on_event.sink.change(id)
    if id ~= nil then
        audio:sink_status_update()
    end
end

function audio.on_event.sink.remove(id)
    if id == audio.sink then
        audio:init_default_sink()
    end
end

function audio.on_event.sink.new(id)
    if id == audio.sink then
        audio:init_default_sink()
    end
end

function audio:init_cava()
    audio.cava_pid = awful.spawn("cava -p ".. require("gears.filesystem").get_configuration_dir().."/cava_raw.conf")
end

function audio:init_default_sink()
    awful.spawn.easy_async("pactl list sinks short",
        function(out)
            self.sink = tonumber(out:match("(%d+)%s+[^\n]-%s+IDLE\n") or out:match("(%d+)%s+[^\n]-%s+RUNNING\n"))
            self.emit_signal("audio::volume")
        end
    )
end

function audio:sink_status_update()
    awful.spawn.easy_async(
        "pactl list sinks",
        function(out)
            for sink, mute, vol in out:gmatch(
                    "Sink #(%d+).-"..
                    "\n%s+Mute:%s*(%a+).-"..
                    "\n%s+Volume:[^\n]-(%d+)%%[^\n]-\n"
                ) do
                local sink = tonumber(sink)
                local vol = tonumber(vol)
                local mute = mute == "yes"
                if self.volume[sink] ~= vol then
                    self.volume[sink] = vol
                    self.emit_signal("audio::volume")
                end

                if self.mute[sink] ~= mute then
                    self.mute[sink] = mute
                    self.emit_signal("audio::mute")
                end
            end
        end
    )
end

function audio:volume_get(sink)
    local sink = sink or self.sink
    if sink ~= nil then
        return self.volume[sink]
    else
        return 0
    end
end

function audio:volume_set(val, sink)
    local sink = sink or self.sink
    if sink ~= nil then
        awful.spawn("pactl set-sink-volume "..sink.." "..val)
    end
end

function audio:volume_mute(val, sink)
    local sink = sink or self.sink
    local val = val and tostring(val) or "toggle"

    if sink ~= nil then
        awful.spawn("pactl set-sink-mute "..sink.." "..val)
    end
end

function audio.connect_signal(name, callback)
    signals[name] = signals[name] or {}
    table.insert(signals[name], callback)
end

function audio.disconnect_signal(name, callback)
    signals[name] = signals[name] or {}

    for k, v in ipairs(signals[name]) do
        if v == callback then
            table.remove(signals[name], k)
            break
        end
    end
end

function audio.emit_signal(name, ...)
    signals[name] = signals[name] or {}

    for _, cb in ipairs(signals[name]) do
        cb(...)
    end
end

audio.mt = {}

function audio.mt:__gc()
    posix_signal.kill(audio.subscription_pid)
    posix_signal.kill(audio.cava_pid)
end

audio:init_pulse_subscription()
audio:init_default_sink()
audio:sink_status_update()
audio:init_cava()

audio:connect_signal("audio::volume", function() require("dbg").notify("Volume emitted") end)

if _G._VERSION == "Lua 5.1" then
    -- Lua 5.1 and LuaJIT without Lua5.2 compat does not support __gc on tables, so we need to use newproxy
    local g = newproxy(false)
    debug.setmetatable(g, {__gc = audio.mt.__gc})
    audio._garbage = g
end

return setmetatable(audio, audio.mt)
