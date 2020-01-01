---------------------------------------------------------------------------
--- Display the current client layout (`awful.layout`) icon or name.
--
-- @DOC_awful_widget_layoutbox_default_EXAMPLE@
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @widgetmod awful.widget.layoutbox
---------------------------------------------------------------------------

local setmetatable = setmetatable
local capi = { screen = screen, tag = tag }
local common = require("awful.widget.common")
local layout = require("awful.layout")
local tooltip = require("awful.tooltip")
local beautiful = require("beautiful")
local surface = require("gears.surface")
local gdebug = require("gears.debug")
local gtable = require("gears.table")
local timer = require("gears.timer")
local wibox = require("wibox")
local wlayout = require("wibox.layout")
local base = require("wibox.widget.base")

local function get_screen(s)
    return s and capi.screen[s]
end

local layoutbox = { mt = {} }

local default_template = {
    {
        id = "imagebox",
        widget = wibox.widget.imagebox
    },
    {
        id = "textbox",
        widget = wibox.widget.textbox
    },
    layout = wlayout.fixed.horizontal
}


local boxes = nil

local function layoutbox_label(t, tscreen)
    local theme = beautiful.get()
    local bg = "#ffffff"
    local bg_image = "#00ffff"
    local layoutbox_disable_icon = theme.layoutbox_disable_icon or false
    local layout_screen = layout.get(tscren)
    local text = layout.getname(layout_screen)

    local img = surface.load_silently(beautiful["layout_" .. text], false)
    -- TODO says values are nil when uncommented
    --t.imagebox.image = img
    --t.textbox.text   = text
    local other_args = {}
    return text, bg, bg_image, not layoutbox_disable_icon and img or nil, other_args
end

-- Remove some callback boilerplate from the user provided templates
local function create_callback(w, t)
    common._set_common_property(w, "layout", t)
end

local function update(w, screen, buttons, data, update_function, args)
    local layouts = layout.layouts -- TODO get all of the layouts

    local sscreen = get_screen(screen)

    local function label(c, sscreen) return layoutbox_label(c, sscreen) end

    update_function(w, buttons, label, data, layouts, {
        widget_template = args.widget_template or default_template,
        create_callback = create_callback,
    })
end

--- Create a layoutbox widget. It draws a picture with the current layout
-- symbol of the current tag.
-- @tparam table args The arguments.
-- @tparam screen args.screen The screen number that the layout will be represented for.
-- @tparam table args.buttons The `awful.button`s for this layoutbox.
-- @return The layoutbox.
function layoutbox.new(args)
    args = args or {}
    local screen = args.screen

    if type(args) == "number" or type(args) == "screen" or args.fake_remove then
        screen, args = args, {}

        gdebug.deprecate(
            "Use awful.widget.layoutbox{screen=s} instead of awful.widget.layoutbox(screen)",
            {deprecated_in=5}
        )
    end

    assert(type(args) == "table")

    screen = get_screen(screen or 1)

    local uf = args.update_function or common.list_update
    local w = base.make_widget_from_value(args.layout or wlayout.fixed.horizontal)

    local data = setmetatable({}, { __mode = 'k' })

    local queued_update = {}

    function w._do_layoutbox_update_now()
        if screen.valid then
            update(w, screen, args.buttons, data, uf, args)
        end
        queued_update[screen] = false
    end

    function w._do_layoutbox_update()
        -- Add a delayed callback for the first update.
        if not queued_update[screen] then
            timer.delayed_call(w._do_taglist_update_now)
            queued_update[screen] = true
        end
    end

    -- Do we already have the update callbacks registered?
    if boxes == nil then
        boxes = setmetatable({}, { __mode = "kv" })
        capi.tag.connect_signal("property::selected", function(t)
            local tag_screen = get_screen(t.screen)
            local wig = boxes[tag_screen]
            if wig then
                update(wig, tag_screen, args.buttons, data, uf, args)
            end
        end)
        capi.tag.connect_signal("property::layout", function(t)
            local tag_screen = get_screen(t.screen)
            local wig = boxes[screen]
            if wig then
                update(wig, tag_screen, args.buttons, data, uf, args)
            end
        end)
        capi.tag.connect_signal("property::screen", function()
            for s, x in pairs(boxes) do
                if s.valid then
                    update(x, s, args.buttons, data, uf, args)
                end
            end
        end)
        layoutbox.boxes = boxes
    end

    -- Do we already have a layoutbox for this screen?
    local w = boxes[screen]
    if not w then
        -- TODO rip this out with template
        w = wibox.widget {
            {
                id     = "imagebox",
                widget = wibox.widget.imagebox
            },
            {
                id     = "textbox",
                widget = wibox.widget.textbox
            },
            layout = wlayout.fixed.horizontal
        }

        w._layoutbox_tooltip = tooltip {objects = {w}, delay_show = 1}

        -- Apply the buttons, visible, forced_width and so on
        gtable.crush(w, args)

        update(w, screen, args.buttons, data, uf, args)
        boxes[screen] = w
    end

    return w
end

function layoutbox.mt:__call(...)
    return layoutbox.new(...)
end

--@DOC_widget_COMMON@

--@DOC_object_COMMON@

return setmetatable(layoutbox, layoutbox.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
