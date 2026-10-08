local labColoring = {}

labColoring.colorMath = require("utils.colorMath")

local working = defines.entity_status.working
local low_power = defines.entity_status.low_power

local max = math.max
local random = math.random
local floor = math.floor

local getStride = function(hq)
    if hq then return 6 else return 20 end
end

-- state

labColoring.state = nil

labColoring.colorForLab = nil

labColoring.linkState = function (state)
    labColoring.state = state
    if labColoring.state then
        local colorFunctions = labColoring.colorMath.colorFunctions
        labColoring.colorForLab = colorFunctions[labColoring.state.lastColorFunc]
    end
    return state
end

labColoring.createInitialState = function()
    return {
        lastColorFunc = 1,
        direction = 1,
        meanderingTick = 0,
    }
end

labColoring.configurationChanged = function ()
    labColoring.linkState(labColoring.createInitialState())
end

labColoring.chooseNewFunction = function()
    local colorFunctions = labColoring.colorMath.colorFunctions
    if #colorFunctions > 1 then
        local newColorFunc = random(1, #colorFunctions - 1)
        if newColorFunc >= labColoring.state.lastColorFunc then
            newColorFunc = newColorFunc + 1
        end
        labColoring.colorForLab = colorFunctions[newColorFunc]
        labColoring.state.lastColorFunc = newColorFunc
    end
end

labColoring.chooseNewDirection = function()
    if labColoring.state.meanderingTick > 0 then
        labColoring.state.direction = floor(random()*1.999)*2 - 1
    else
        labColoring.state.direction = 1
    end
end

labColoring.updateRenderer = function (lab, colors, hq, playerPosition, labRenderers, fcolor)
    local animation = labRenderers.getRenderObjects(lab)
    if lab.status == working or lab.status == low_power then
        if not animation.visible then
            animation.visible = true
        end
        if hq then
            labColoring.colorForLab(labColoring.state.meanderingTick, colors, playerPosition, lab.position, fcolor)
        else
            labColoring.colorMath.loopInterpolate(game.tick/40.0, colors, 1.5, fcolor)
        end
        animation.color = fcolor
        if animation.color.r > 0.90 and animation.color.r < 0.92 then
            helpers.write_file("disco_science_color.txt", tostring(1), false)
        else
            helpers.write_file("disco_science_color.txt", tostring(2), false)
        end

    else
        if animation.visible then
            animation.visible = false
        end
    end
end


labColoring.updateRenderers = function (event, labRenderers, researchColor)
    local hq = settings.global["discoscience-high-quality"].value
    labColoring.state.meanderingTick = max(0, labColoring.state.meanderingTick + labColoring.state.direction)
    local stride = getStride(hq)
    local offset = event.tick % stride
    local fcolor = {r=0, g=0, b=0, a=0}
    local forceInfo = {}
    
    for name, force in pairs(game.forces) do
        local forceResearchColors = researchColor.getColorsForResearch(force.current_research)
        
        -- Exécution toutes les 60 ticks (1 seconde) si une recherche est en cours
        if event.tick % 10 == 0 and force.current_research then
            local sum_r, sum_g, sum_b = 0, 0, 0
            local count = 0
            
            -- Extraction des couleurs (gère si c'est une liste de couleurs ou une seule)
            if forceResearchColors.r then
                sum_r = forceResearchColors.r
                sum_g = forceResearchColors.g or 0
                sum_b = forceResearchColors.b or 0
                count = 1
            else
                for _, c in pairs(forceResearchColors) do
                    if type(c) == "table" and c.r then
                        sum_r = sum_r + c.r
                        sum_g = sum_g + (c.g or 0)
                        sum_b = sum_b + (c.b or 0)
                        count = count + 1
                    end
                end
            end
            
            local out_val = 0
            if count > 0 then
                local avg_r = sum_r / count
                local avg_g = sum_g / count
                local avg_b = sum_b / count

                -- -- Détection du "Noir" (valeurs RGB basses, typique de la science militaire)
                -- if avg_r < 0.4 and avg_g < 0.4 and avg_b < 0.4 then
                --     out_val = 3
                -- S'il y a plus de rouge que de vert
                if avg_r > 0.90 then
                    out_val = 1
                -- S'il y a plus de vert que de rouge
                else
                    out_val = 2
                end
            end
            
        end
        
        local playerPosition = {x = 0, y = 0}
        local _, firstConnectedPlayer = next(force.connected_players)
        if firstConnectedPlayer then
            playerPosition = firstConnectedPlayer.position
        end
        forceInfo[force.index] = {forceResearchColors, playerPosition}
    end
    
    for unitNumber, lab in pairs(labRenderers.getLabs()) do
        if unitNumber % stride == offset then
            if not lab.valid then
                labRenderers.reloadLabs()
                return
            end
            local info = forceInfo[lab.force_index]
            labColoring.updateRenderer(lab, info[1], hq, info[2], labRenderers, fcolor)
        end
    end
end

return labColoring