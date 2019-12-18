--DOC_GEN_OUTPUT --DOC_HIDE
local gears = require("gears") --DOC_HIDE

local test = "do.it"
local res = gears.string.endswith(test,"it")
assert(res == true) --DOC_HIDE

res = gears.string.endswith(test,"do")
assert(res == false) --DOC_HIDE

