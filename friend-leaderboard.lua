local json = require("json")
local utils = require("leaderboard_utils")

local leaderboard = {}

Constants = {
  IMPORT_METHODS = { "merge", "replace", "add" },
  DEFAULT_METHOD = "merge",

  DEFAULT_OPTIONS = {
    Combined=false
  }
}

Name = Name or "leaderboard"
-- upstream that can import data to this leaderboard
Upstream = Upstream or { "TEtRmrFTVZyBlC5jzAs8GC3KT_A_BocMhCZG0FHb-yI" }
-- downstream that will receive data from this leaderboard
Downstream = Downstream or nil
Weights = Weights or {}
Scores = Scores or {}

-- get leaderboard, return a list of wallets and their points, sorted by points
local function rank_players()
  local data = {}
  for wallet, score in pairs(Scores) do
    table.insert(data, { wallet = wallet, points = score.points, raw = score.raw })
  end
  table.sort(data, function(a, b) return a.points > b.points end)

  return data
end

-- get leaderboard for a combined leaderboard
local function rank_players_combined()
  return utils.normalize_and_rank_scores_weighted(Scores, Weights)
end

-- default raw data to points logic
local function raw_to_points(raw)
  return utils.calculate_points_by_weight(raw, Weights)
end

-- Create a normal leaderboard
function leaderboard.new(opts)
  -- set default options
  opts = opts or Constants.DEFAULT_OPTIONS
  local is_combined_leaderboard = opts.Combined or false
  local get_leaderboard = is_combined_leaderboard and rank_players_combined or rank_players
  local raw_to_points = opts.CalculatePoints or raw_to_points

  -- import data for a normal leaderboard
  local function import_data(msg)
    assert(utils.can_import_data(msg, Upstream), "You are not allowed to import data")

    local imported = utils.decode_and_validate_data(msg.Data)

    -- construct a leaderboard based on the imported data
    local scores = {}
    for wallet, raw in pairs(imported) do
      -- calculate points based on raw data, returned value must be a number
      local points = raw_to_points(raw)
      assert(type(points) == "number", "Points must be a number")

      scores[wallet] = {
        points=points,
        raw=raw
      }
    end

    local method = msg.Tags.Method or Constants.DEFAULT_METHOD
    -- backwards compatibility with Replace tag
    local replace = msg.Tags.Replace or method == "replace"
    if replace then -- replace (new leaderboard with imported data)
      Scores = scores
    elseif method == "merge" then -- merge (default) (keep existing data and replace with imported data)
      for wallet, data in pairs(scores) do
        Scores[wallet] = data
      end
    elseif method == "add" then -- add (add points to existing data)
      for wallet, data in pairs(scores) do
        if Scores[wallet] then
          Scores[wallet].points = Scores[wallet].points + data.points

          -- if raw data is action map, add the amount of actions to the existing data
          if utils.is_action_map(data) then
            for metric, amount in pairs(data.raw) do
              if not Scores[wallet].raw[metric] then
                Scores[wallet].raw[metric] = 0
              end
              Scores[wallet].raw[metric] = Scores[wallet].raw[metric] + amount
            end
          else
            -- if raw data is not action map, replace the raw data
            Scores[wallet] = data
          end
        else
          Scores[wallet] = data
        end
      end
    end

    -- if downstream is set, import new leaderboard data to downstream
    if Downstream then
      -- remove raw data before sending to downstream
      local data = {}
      for wallet, score in pairs(Scores) do
        data[wallet] = score.points
      end

      ao.send({ Target = Downstream, Action = "ImportData", Data = json.encode(data), Metric = Name })
    end

    return "Imported data successfully"
  end

  local function import_data_combined(msg)
    assert(utils.can_import_data(msg, Upstream), "You are not allowed to import data")

    local metric = msg.Tags.Metric
    assert(metric, "Metric is required")

    local imported = utils.decode_and_validate_data(msg.Data)

    -- update leaderboards
    Scores[metric] = imported

    return "Imported data successfully"
  end

  -- Handler: ImportData
  local function ImportData(msg)
    if is_combined_leaderboard then
      return import_data_combined(msg)
    else
      return import_data(msg)
    end
  end

  -- Handler: GetLeaderboard
  local function GetLeaderboard(msg)
    local data = get_leaderboard()

    local all = msg.Tags.All or false
    if not all then
       -- pagination tags
      local start = tonumber(msg.Tags['Start'] or '1')
      local limit = tonumber(msg.Tags['Limit'] or '10')
      local total = #data
      local end_ = start + limit - 1
      if end_ > total then
        end_ = total
      end

      -- trim data based on pagination
      data = { table.unpack(data, start, end_) }
    end

    Handlers.utils.reply(json.encode(data))(msg)
  end

  -- Handler: GetRank
  local function GetRank(msg)
    local wallet = msg.From
    assert(wallet, "Wallet is required")

    local data = get_leaderboard()
    local total = #data
    local rank = nil
    local raw = nil
    local points = nil
    for i, d in ipairs(data) do
      if d.wallet == wallet then
        rank = i
        raw = d.raw
        points = d.points
        break
      end
    end

    if not rank then
      Handlers.utils.reply(json.encode(nil))(msg)
      return
    end

    Handlers.utils.reply(json.encode({ rank = rank, total = total, raw = raw, points = points }))(msg)
  end

  -- Handler: Info
  local function GetInfo(msg)
    local info = Info or {}
    info["type"] = is_combined_leaderboard and "Combined" or "Normal"

    -- number of wallets that's present in all metrics if the leaderboard is a combined leaderboard
    -- scores: { metric_1: { wallet: score }, metric_2: { wallet: score } }
    -- count the number of wallets that's present in all metrics

    -- get the metric with the most wallets
    if is_combined_leaderboard then
      local wallets = {}
      local number_of_metrics = 0
      for metric, scores in pairs(Scores) do
        number_of_metrics = number_of_metrics + 1
        for wallet, _ in pairs(scores) do
          wallets[wallet] = (wallets[wallet] or 0) + 1
        end
      end

      local number_of_wallets = 0
      for _, count in pairs(wallets) do
        if count == number_of_metrics then
          number_of_wallets = number_of_wallets + 1
        end
      end

      info["common-wallets"] = number_of_wallets
    end

    ao.send({
      Target = msg.From,
      Info = json.encode(info)
    })
  end

  -- add upstream
  -- local function addUpstream(msg)
  --   local upstream = msg.Tags.Upstream
  --   if upstream then
  --     table.insert(Upstream, upstream)
  --   end
  -- end

  -- Handlers.add("add-upstream", Handlers.utils.hasMatchingTag("Action", "AddUpstream"), addUpstream) 
  Handlers.add("import", Handlers.utils.hasMatchingTag("Action", "ImportData"), ImportData)
  Handlers.add("get-rank", Handlers.utils.hasMatchingTag("Action", "GetRank"), GetRank)
  Handlers.add("get-leaderboard", Handlers.utils.hasMatchingTag("Action", "GetLeaderboard"), GetLeaderboard)
  Handlers.add('info', Handlers.utils.hasMatchingTag('Action', 'Info'), GetInfo)
end

return leaderboard