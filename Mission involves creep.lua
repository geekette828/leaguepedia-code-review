local argsUtil = require("Module:ArgsUtil")
local cargoUtil = require("Module:CargoUtil")

local p = {}

-- kill ranges based on difficulty level
local killRanges = {
    easy = { 4, 12 },
    hard = { 2, 5 },
    special = { 4, 8 }
}

-- Function to calculate the reward range based on the kill range
local function calculateRewardRange(lowerBound, upperBound)
    local lowerReward = 20 * lowerBound * 1.5
    local upperReward = 20 * upperBound * 1.5
    return lowerReward .. "-" .. upperReward
end

function p.main(frame)
    local args = argsUtil.merge(frame.args, frame:getParent().args)
    local creepName = args[1] or mw.title.getCurrentTitle().text

    -- Perform the missions Cargo query
    local missionQueryOptions = {
        tables = "Missions, missionNPCs",
        fields = "Missions._pageTitle, Missions.name, Missions.missionID, missionNPCs.npc",
        join = "Missions.missionID=missionNPCs.missionID",
        where = "Missions.missionID LIKE 'T_KillEnemies%'",
        groupBy = "",
        limit = 100,
        orderBy = ""
    }
    
    local missionResults = cargoUtil.queryData(missionQueryOptions)

    -- Perform the creep difficulty Cargo query
    local creepQueryOptions = {
        tables = "Creeps",
        fields = "Creeps.name, Creeps.difficulty",
        where = "Creeps.name='" .. creepName:gsub("'", "''") .. "'",
        groupBy = "",
        limit = 100,
        orderBy = ""
    }
    
    local creepDifficultyResults = cargoUtil.queryData(creepQueryOptions)

    -- Build the result table
    local html = mw.html.create('table')
        :addClass('lkg-table tdc2 tdc3 tdc4')
        :tag('tr')
            :tag('th'):wikitext('Mission Name'):done()
            :tag('th'):wikitext('Given By'):done()
            :tag('th'):wikitext('Kill Range'):done()
            :tag('th'):wikitext('Reward Range'):done()
        :done()
        
    for _, missionRow in ipairs(missionResults) do
        local pageName = missionRow["Missions._pageTitle"]
        local missionName = missionRow["Missions.name"]
        local missionNPC = missionRow["missionNPCs.npc"]
        
        for _, creepRow in ipairs(creepDifficultyResults) do
            local creepDifficulty = creepRow["Creeps.difficulty"]
	        
            local difficulty = string.lower(creepDifficulty)
            local killRange = killRanges[difficulty]
            local rewardRange = calculateRewardRange(killRange[1], killRange[2])
        
            -- Build the table row with retrieved data
            html:tag('tr')
                :tag('td'):wikitext("[[" .. pageName  .. "|" .. (missionName or 'N/A') .. "]]"):done()
                :tag('td'):wikitext("[[File:" .. missionNPC  .. ".png|link=" .. missionNPC  .. "|40px]]"):done()
                :tag('td'):wikitext(table.concat(killRange, "-")):done()
                :tag('td'):wikitext(rewardRange)
                    :wikitext(' [[File:Credits.png|link=|20px]]') -- Adding the icon after the reward range
                    :done()
            :done()
        end
    end

    return tostring(html)
end

return p
