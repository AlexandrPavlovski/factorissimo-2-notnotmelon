local function generate_factory_floor_planet_icons(planet)
    if not planet.icons and not planet.icon then
        error("Planet " .. planet.name .. " has no icon or icons")
    end

    local icons = table.deepcopy(planet.icons or {})
    if planet.icon then
        table.insert(icons, {icon = planet.icon, icon_size = planet.icon_size or 64})
    end

    -- shift all planet icons to the top left corner
    for _, icon in pairs(icons) do
        local old_shift = icon.shift or {0, 0}
        local x = old_shift.x or old_shift[1] or 0
        local y = old_shift.y or old_shift[2] or 0

        icon.shift = {x - 2, y - 2}
        icon.scale = (icon.scale or 1) * 0.75
        icon.icon_size = icon.icon_size or planet.icon_size or 64
    end

    -- add a factory icon to the bottom right corner
    table.insert(icons, {
        icon = "__factorissimo-2-notnotmelon__/graphics/technology/factory-architecture-1.png",
        icon_size = 128,
        shift = {8, 8},
        scale = 0.5
    })

    return icons
end

-- we need to copy all existing planets in order to create factory floors for them
local factory_floors = {}
for _, planet in pairs(data.raw.planet) do
    if planet.hidden then goto continue end
    if planet.ignored_for_factorissimo then goto continue end

    local factory_floor = table.deepcopy(planet)
    local original_localised_name = planet.localised_name or {"space-location-name." .. planet.name}
    factory_floor.name = planet.name .. "-factory-floor"
    factory_floor.localised_name = ""
    factory_floor.localised_description = {"space-location-description.factory-floor", original_localised_name, planet.name}
    factory_floor.lightning_properties = nil
    factory_floor.distance = factory_floor.distance - (1.25 * factory_floor.magnitude)
    factory_floor.draw_orbit = false
    factory_floor.solar_power_in_space = 0
    factory_floor.fly_condition = true
    factory_floor.auto_save_on_first_trip = false
    factory_floor.asteroid_spawn_definitions = nil
    factory_floor.order = "z-[factory-floor]" .. (planet.order or planet.name)
    factory_floor.map_gen_settings = nil
    factory_floor.surface_properties = factory_floor.surface_properties or {}
    factory_floor.surface_properties["solar-power"] = 0
    factory_floor.surface_properties["day-night-cycle"] = 0
    factory_floor.surface_properties["ceiling"] = 0
    factory_floor.magnitude = (factory_floor.magnitude or 1) / 2
    factory_floor.starmap_icons = nil
    factory_floor.starmap_icon = "__factorissimo-2-notnotmelon__/graphics/starmap/factory-floor-" .. math.floor((planet.orientation or 0) * 64 + 32) % 64 .. ".png"
    factory_floor.icon = nil
    factory_floor.icon_size = 64
    factory_floor.icons = generate_factory_floor_planet_icons(planet)
    factory_floor.starmap_icon_size = 115
    factory_floor.factoriopedia_alternative = planet.name
    factory_floor.hidden_in_factoriopedia = true
    table.insert(factory_floors, factory_floor)

    ::continue::
end
data:extend(factory_floors)

-- ensure that the factorissimo planets are unlocked when the original planets are unlocked
for _, technology in pairs(data.raw.technology) do
    if technology.effects and type(technology.effects) == "table" then
        local new_effects = {}
        for _, effect in pairs(technology.effects) do
            table.insert(new_effects, effect)
            local planet, factory_floor

            if type(effect) ~= "table" then goto continue end
            if effect.type ~= "unlock-space-location" then goto continue end
            if not effect.space_location then goto continue end
            local planet = data.raw.planet[effect.space_location]
            if not planet or not planet.name then goto continue end
            local factory_floor = data.raw.planet[planet.name .. "-factory-floor"]
            if not factory_floor then goto continue end

            table.insert(new_effects, {
                type = "unlock-space-location",
                space_location = factory_floor.name,
                use_icon_overlay_constant = true,
            })

            ::continue::
        end
        technology.effects = new_effects
    end
end
