-- Requires a crafting table upgrade and an empty turtle inventory.
-- Connect an enabled wired modem at the front; expose the turtle on its network.
-- Connect the left/back inventories to the same wired network and enable them.
-- Usage: craft_sticks <left inventory network name> <back inventory network name>
assert(turtle and turtle.craft, "A crafting turtle is required")
assert(peripheral.hasType("front", "modem"), "No modem at the front")
local modem = peripheral.wrap("front")
assert(not modem.isWireless(), "A wired modem is required")
local turtleName = assert(modem.getNameLocal(), "Enable the front modem to expose this turtle")
local inputName, outputName = ...
if not inputName or not outputName then
    print("Usage: craft_sticks <input name> <output name>")
    print("Turtle: " .. turtleName)
    print("Inventories on the front modem network:")
    for _, name in ipairs(modem.getNamesRemote()) do
        if modem.hasTypeRemote(name, "inventory") then
            print("  " .. name)
        end
    end
    return
end
assert(inputName ~= outputName, "Input and output must be different inventories")
assert(inputName ~= turtleName and outputName ~= turtleName,
    "Input/output must not be the turtle itself")
assert(modem.hasTypeRemote(inputName, "inventory"), "Input not found on front modem network")
assert(modem.hasTypeRemote(outputName, "inventory"), "Output not found on front modem network")
local input = {
    list = function()
        return modem.callRemote(inputName, "list")
    end,
    pushItems = function(...)
        return modem.callRemote(inputName, "pushItems", ...)
    end,
}
local output = {
    pullItems = function(...)
        return modem.callRemote(outputName, "pullItems", ...)
    end,
}
for slot = 1, 16 do
    assert(turtle.getItemCount(slot) == 0, "Empty the turtle inventory first")
end

local selected = turtle.getSelectedSlot()
local total = 0

local function expectItem(slot, name, count)
    local item = turtle.getItemDetail(slot)
    assert(item and item.name == name and item.count == count,
        "Unexpected crafting result in slot " .. slot)
end

local function run()
    while true do
        local sourceSlot
        for slot, item in pairs(input.list()) do
            if item.name == "minecraft:oak_log" then
                sourceSlot = slot
                break
            end
        end
        if not sourceSlot then
            print("No oak logs left")
            return
        end
        assert(input.pushItems(turtleName, sourceSlot, 1, 1) == 1,
            "Could not transfer oak log into turtle slot 1")
        expectItem(1, "minecraft:oak_log", 1)

        turtle.select(16)
        assert(turtle.craft(1), "Could not craft oak planks; check crafting upgrade")
        expectItem(16, "minecraft:oak_planks", 4)

        -- Crafting grid: two planks each in slots 1 and 5.
        assert(turtle.transferTo(1, 2), "Could not move planks to slot 1")
        assert(turtle.transferTo(5, 2), "Could not move planks to slot 5")
        assert(turtle.craft(2), "Could not craft sticks")
        expectItem(16, "minecraft:stick", 8)

        while turtle.getItemCount(16) > 0 do
            assert(output.pullItems(turtleName, 16) > 0,
                "Output blocked/full; remaining sticks kept in slot 16")
        end
        total = total + 8
        print("Sticks output: " .. total)
    end
end

local ok, err = pcall(run)
turtle.select(selected)
if not ok then
    error(err, 0)
end
print("Done: " .. total .. " sticks")
