---------------------------------------------------------------------------
--- System monitoring
--
-- @module cosy
---------------------------------------------------------------------------

local gears = require("gears")
local unix_std = require("posix.unistd")
local util = require("cosy.util")
local tonumber = tonumber

local sysinfo = {
    -- CPU information
    cpu = {
        -- Total core count
        cores = 0,
        -- CPU usage per core
        load = {
            total = 0,
            _prev = nil,
            _this = nil,
        },
        -- Temperature in millidegrees celcius per physical core
        temp = {
            total = 0,
        },
        -- Virtual to physical core id
        proc_to_core = {},
    }
}

local signals = {}

function sysinfo.cpu:init()
    local cpuinfo = util.fs.read("/proc/cpuinfo")
    for procinfo in cpuinfo:gmatch(".-\n\n") do
        local id, coreid = procinfo:match(
            "processor%s+:%s+(%d+).*"..
            "core id%s+:%s+(%d+).*"
        )

        self.proc_to_core[id] = coreid
    end
    self.cores = #self.proc_to_core
end

function sysinfo.cpu:update()
    sysinfo.cpu:update_load()

    sysinfo.emit_signal("cpu::updated")
end

function sysinfo.cpu:update_load()
    self.load._prev = self.load._this
    self.load._this = {}

    local stat = util.fs.read("/proc/stat")

    for core, user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice
        in stat:gmatch("cpu(%d*)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
    do
        if core == "" then
            core = "total"
        else
            core = tonumber(core) + 1
        end

        self.load._this[core] = {
            user       = tonumber(user),
            nice       = tonumber(nice),
            system     = tonumber(system),
            idle       = tonumber(idle),
            iowait     = tonumber(iowait),
            irq        = tonumber(irq),
            softirq    = tonumber(softirq),
            steal      = tonumber(steal),
            guest      = tonumber(guest),
            guest_nice = tonumber(guest_nice),
        }

        if self.load._prev ~= nil and self.load._prev[core] ~= nil then
            local prev_total = 0
            for _, val in pairs(self.load._prev[core]) do
                prev_total = prev_total + val
            end
            local prev_idle = self.load._prev[core].idle + self.load._prev[core].iowait

            local this_total = 0
            for _, val in pairs(self.load._this[core]) do
                this_total = this_total + val
            end
            local this_idle = self.load._this[core].idle + self.load._this[core].iowait

            local total = prev_total - this_total
            local idle = prev_idle - this_idle

            self.load[core] = (total - idle) / total
        end
    end
end

function sysinfo.connect_signal(name, callback)
    signals[name] = signals[name] or {}
    table.insert(signals[name], callback)
end

function sysinfo.disconnect_signal(name, callback)
    signals[name] = signals[name] or {}

    for k, v in ipairs(signals[name]) do
        if v == callback then
            table.remove(signals[name], k)
            break
        end
    end
end

function sysinfo.emit_signal(name, ...)
    signals[name] = signals[name] or {}

    for _, cb in ipairs(signals[name]) do
        cb(...)
    end
end

sysinfo.cpu:init()

sysinfo.refresh_timer = gears.timer.start_new(
    1,
    function()
        sysinfo.cpu:update()
        return true
    end
)

return sysinfo
