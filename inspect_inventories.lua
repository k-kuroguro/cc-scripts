-- Detect inventories exposed as peripherals on the left and right.
for _, side in ipairs({ "left", "right" }) do
    if peripheral.hasType(side, "inventory") then
        print(side .. ": Inventory - " .. peripheral.getType(side))
    elseif peripheral.isPresent(side) then
        print(side .. ": Not an inventory - " .. peripheral.getType(side))
    else
        print(side .. ": No peripheral")
    end
end
