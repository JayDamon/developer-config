--------------------------
---- WORKSPACE ROUTING ----
--------------------------

-- Route workspaces to active monitors based on what's connected.
-- Detects monitors by description so connector changes (DP-2 vs DP-5) don't matter.
-- Runs on every config load and whenever a monitor is connected or disconnected.
-- (Replaces the old scripts/workspaces.sh + scripts/monitor-watch.sh.)

local rules = {}

local function find_monitor(pattern)
    for _, m in ipairs(hl.get_monitors()) do
        if m.description:find(pattern, 1, true) then
            return m.name
        end
    end
end

local function route(ws, mon)
    -- Default binding for future workspace creation (replaces any earlier rule for ws)
    if rules[ws] then
        rules[ws]:set_enabled(false)
    end
    rules[ws] = hl.workspace_rule({ workspace = tostring(ws), monitor = mon })

    -- Also move the workspace if it already exists (e.g. on hotplug with open windows)
    if hl.get_workspace(ws) then
        pcall(hl.dispatch, hl.dsp.workspace.move({ workspace = ws, monitor = mon }))
    end
end

local function route_range(from, to, mon)
    for ws = from, to do
        route(ws, mon)
    end
end

local function route_all()
    local monitors = hl.get_monitors()
    if #monitors == 0 then
        return
    end

    local ultrawide = find_monitor("C49RG9")
    local dell      = find_monitor("U2715H")
    local laptop    = hl.get_monitor("eDP-1") and "eDP-1" or nil

    if ultrawide then
        route_range(1, 5, ultrawide)
        route(16, ultrawide) -- gaming workspace always on primary

        if dell then
            route_range(11, 15, dell)
            -- laptop or ultrawide gets 6-10 when Dell is also present
            route_range(6, 10, laptop or ultrawide)
        else
            route_range(6, 10, laptop or ultrawide)
        end
    elseif laptop and dell then
        route_range(1, 5, laptop)
        route_range(6, 16, dell)
    else
        route_range(1, 16, laptop or dell or monitors[1].name)
    end
end

-- Short delay lets Hyprland settle before querying monitors.
local function schedule_route()
    hl.timer(route_all, { timeout = 500, type = "oneshot" })
end

schedule_route()
hl.on("monitor.added", schedule_route)
hl.on("monitor.removed", schedule_route)
