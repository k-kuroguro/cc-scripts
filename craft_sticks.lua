-- Requires a crafting table upgrade and an empty turtle inventory.
-- Put oak logs in the left inventory. Output goes behind the initial heading.
assert(turtle and turtle.craft, "A crafting turtle is required")
assert(peripheral.hasType("left", "inventory"), "No inventory on the left")
for slot = 1, 16 do
    assert(turtle.getItemCount(slot) == 0, "Empty the turtle inventory first")
end

local heading = 0
local selected = turtle.getSelectedSlot()
local total = 0

local function face(target)
    while heading ~= target do
        assert(turtle.turnRight(), "Could not turn")
        heading = (heading + 1) % 4
    end
end

local function expectItem(slot, name, count)
    local item = turtle.getItemDetail(slot)
    assert(item and item.name == name and item.count == count,
        "Unexpected crafting result in slot " .. slot)
end

local function run()
    while true do
        face(3) -- Original left.
        turtle.select(1)
        if not turtle.suck(1) then
            print("Input empty or unavailable")
            return
        end

        local item = turtle.getItemDetail(1)
        if not item or item.name ~= "minecraft:oak_log" then
            -- Do not craft other wood types or unrelated items.
            local returned = turtle.drop()
            assert(returned and turtle.getItemCount(1) == 0,
                "Unexpected input; could not return it (kept in slot 1)")
            error("Input contains a non-oak-log item; remove it and run again", 0)
        end

        turtle.select(16)
        assert(turtle.craft(1), "Could not craft oak planks; check crafting upgrade")
        expectItem(16, "minecraft:oak_planks", 4)

        -- Crafting grid: two planks each in slots 1 and 5.
        assert(turtle.transferTo(1, 2), "Could not move planks to slot 1")
        assert(turtle.transferTo(5, 2), "Could not move planks to slot 5")
        assert(turtle.craft(2), "Could not craft sticks")
        expectItem(16, "minecraft:stick", 8)

        face(2) -- Original back. Without an inventory, drop into the world.
        while turtle.getItemCount(16) > 0 do
            assert(turtle.drop(), "Output blocked/full; sticks kept in slot 16")
        end
        total = total + 8
        print("Sticks output: " .. total)
        face(0)
    end
end

local ok, err = pcall(run)
-- Restore the starting heading even after a crafting/output error.
face(0)
turtle.select(selected)
if not ok then
    error(err, 0)
end
print("Done: " .. total .. " sticks")
