--DOC_GEN_OUTPUT --DOC_HIDE
local gears = require("gears") --DOC_HIDE

local test = "do.it"
local res = gears.string.startswith(test,"do")
print(res)
assert(res == true) --DOC_HIDE

res = gears.string.startswith(test,"it")
print(res)
assert(res == false) --DOC_HIDE
