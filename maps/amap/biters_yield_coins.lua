local Event = require 'utils.event'
local RPG_Settings = require 'modules.rpg.table'
local insert = table.insert
local floor = math.floor
local random = math.random
local Functions = require 'modules.rpg.functions'
local WPT = require 'maps.amap.table'

local coin_yield = {
    ['behemoth-biter'] = 5,
    ['behemoth-spitter'] = 5,
    ['behemoth-worm-turret'] = 20,
    ['big-biter'] = 3,
    ['big-spitter'] = 3,
    ['big-worm-turret'] = 16,
    ['biter-spawner'] = 32,
    ['medium-biter'] = 2,
    ['medium-spitter'] = 2,
    ['medium-worm-turret'] = 12,
    ['small-biter'] = 1,
    ['small-spitter'] = 1,
    ['small-worm-turret'] = 8,
    ['spitter-spawner'] = 32
}

local entities_that_earn_coins = {
    ['artillery-turret'] = true,
    ['gun-turret'] = true,
    ['laser-turret'] = true,
    ['flamethrower-turret'] = true
}

--extra coins for "boss" biters from biter_health_booster.lua
local function get_coin_count(entity)
    local coin_count = coin_yield[entity.name]
    if not coin_count then
        return
    end
    if not global.biter_health_boost_units then
        return coin_count
    end
    local unit_number = entity.unit_number
    if not unit_number then
        return coin_count
    end
    if not global.biter_health_boost_units[unit_number] then
        return coin_count
    end
    if not global.biter_health_boost_units[unit_number][3] then
        return coin_count
    end
    local m = 1 / global.biter_health_boost_units[unit_number][2]
    coin_count = floor(coin_count * m)
    if coin_count < 1 then
        return 1
    end
    return coin_count
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end

    if entity.force.index == game.forces.player.index then
      local name = event.entity.name
          if  entities_that_earn_coins[name] then
            local unit_number = event.entity.unit_number
            local this = WPT.get()
            this.turret[unit_number]=nil
          --  game.print("已消除")
          end
    end

    if entity.force.index ~= 2 then
        return
    end

    local cause = event.cause

    local coin_count = get_coin_count(entity)
    if not coin_count then
        return
    end

    local players_to_reward = {}
    local p
    local reward_has_been_given = false

    if cause then
        if cause.valid then
            if (cause and cause.name == 'character' and cause.player) then
                p = cause.player
            end

            if cause.name == 'character' then
                insert(players_to_reward, cause)
                reward_has_been_given = true
            end
            if cause.type == 'car' then
                local player = cause.get_driver()
                local passenger = cause.get_passenger()
                if player then
                    insert(players_to_reward, player.player)
                end
                if passenger then
                    insert(players_to_reward, passenger.player)
                end
                reward_has_been_given = true
            end
            if cause.type == 'locomotive' then
                local train_passengers = cause.train.passengers
                if train_passengers then
                    for _, passenger in pairs(train_passengers) do
                        insert(players_to_reward, passenger)
                    end
                    reward_has_been_given = true
                end
            end
            for _, player in pairs(players_to_reward) do
                local forest_zone
                if p then
                    forest_zone = RPG_Settings.get_value_from_player(p.index, 'forest_zone')
                end
                if forest_zone then
                    if random(1, 12) == 1 then
                        player.insert({name = 'coin', count = coin_count})
                    end
                else
                    player.insert({name = 'coin', count = coin_count})
                end
            end
        end
        if entities_that_earn_coins[cause.name] then
        --  game.print(cause.unit_number)
        local unit_number= cause.unit_number
        local this = WPT.get()
          if this.turret[unit_number] then
this.turret[unit_number].insert({name = 'coin', count = coin_count})
          end
-- if event.cause.last_user then
--     local player = event.cause.last_user
--   --  game.print(player.name)
--     player.insert({name = 'coin', count = coin_count})
--
--   --  Functions.gain_xp(event.entity.last_user, 1)
--     reward_has_been_given = true
--end

            -- event.entity.surface.spill_item_stack(cause.position, {name = 'coin', count = coin_count}, true)

        end
    end

    -- if reward_has_been_given == false then
    --     event.entity.surface.spill_item_stack(event.entity.position, {name = 'coin', count = coin_count}, true)
    -- end
end

local on_player_or_robot_built_entity = function(event)

  local force = event.created_entity.force


      if not force.index == game.forces.player.index then
        return
      end
  local name = event.created_entity.name
      if not entities_that_earn_coins[name] then
        return
      end
local unit_number = event.created_entity.unit_number
local player = event.created_entity.last_user
local this = WPT.get()
this.turret[unit_number]=player
end


local function on_player_mined_entity(event)
  if not event.entity.valid then
      return
  end
  local name = event.entity.name
  if event.entity.force.index == game.forces.player.index then
    local name = event.entity.name
        if  entities_that_earn_coins[name] then
          local unit_number = event.entity.unit_number
          local this = WPT.get()
          this.turret[unit_number]=nil
        --  game.print("已消除")
        end
  end
end
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_built_entity, on_player_or_robot_built_entity)
Event.add(defines.events.on_robot_built_entity, on_player_or_robot_built_entity)

Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_player_mined_entity)
