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
        -- Virtual to physical core id
        proc_to_core = {},
    },
    mem = {
        -- Total RAM in kB
        total = 0,
        -- Free RAM in kB
        free = 0,
        -- Available RAM in kB
        available = 0,
    },
    temp = {
        -- Temperature in millidegrees celcius per physical core
        cpu = {
            path = nil,
            core = {},
        }
    }
}

local signals = {}

function sysinfo.cpu:init()
    local cpuinfo = util.file.read("/proc/cpuinfo")
    local core_count = 0
    for procinfo in cpuinfo:gmatch(".-\n\n") do
        local id, coreid = procinfo:match(
            "processor%s+:%s+(%d+).*"..
            "core id%s+:%s+(%d+).*"
        )

        self.proc_to_core[id] = coreid
        core_count = core_count + 1
    end
    self.cores = core_count
end

function sysinfo.cpu:update()
    self:update_load()

    sysinfo.emit_signal("cpu::updated")
end

function sysinfo.cpu:update_load()
    self.load._prev = self.load._this
    self.load._this = {}

    local stat = util.file.read("/proc/stat")

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

function sysinfo.mem:update()
    local stat = util.file.read("/proc/meminfo")
    local total, free, avail = stat:match(
        "MemTotal:%s+(%d+).*"..
        "MemFree:%s+(%d+).*"..
        "MemAvailable:%s+(%d+).*"
    )
    self.total = tonumber(total)
    self.free = tonumber(free)
    self.available = tonumber(avail)
end

function sysinfo.temp:init()
    for line in io.popen("for x in /sys/class/hwmon/hwmon*; do printf \"%s \" $x; cat $x/name; done"):lines() do
        local path, name = line:match("([^%s]-)%s+([^\n]-)\n")
        if name == "coretemp" then
            self.cpu.path = path
        end
    end
end

function sysinfo.temp:update()
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
sysinfo.temp:init()
sysinfo.mem:update()

sysinfo.refresh_timer = gears.timer.start_new(
    1,
    function()
        sysinfo.cpu:update()
        sysinfo.mem:update()
        return true
    end
)

return sysinfo
