-- ======================================================================
-- Copyright (c) 2012 RapidFire Studio Limited
-- All Rights Reserved.
-- http://www.rapidfirestudio.com

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:

-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ======================================================================

require "util"

----------------------------------------------------------------
-- local variables
----------------------------------------------------------------

local INF = 1/0
local cachedPaths = nil

----------------------------------------------------------------
-- local functions
----------------------------------------------------------------

function dist (pos1, pos2)

  return util.distance(pos1, pos2)
end

function dist_between ( nodeA, nodeB )

  return util.distance ( nodeA.position, nodeB.position)
end

function heuristic_cost_estimate ( nodeA, nodeB )

  return util.distance ( nodeA.position, nodeB.position)
end

function is_valid_node ( node, neighbor )
-- check for watertiles
  return true
end

function lowest_f_score ( set, f_score )

  local lowest, bestNode = INF, nil
  for _, node in ipairs ( set ) do
    local score = f_score [ node ]
    if score < lowest then
      lowest, bestNode = score, node
    end
  end
  return bestNode
end

function neighbor_nodes (theNode)
-- get Neighbor nodes with FARL:getRail
  local neighbors = {}
  for i=0,2 do
    local newDir, newNode = FARL.getRail(theNode, theNode.travelDir, i)
    if type(newDir) == "number" and is_valid_node(newNode) then
      newNode.travelDir = newDir
      table.insert(neighbors, newNode)
    end
  end  
--  for _, node in ipairs ( nodes ) do
--    if theNode ~= node and is_valid_node ( theNode, node ) then
--      table.insert ( neighbors, node )
--    end
--  end
  return neighbors
end

function not_in ( set, theNode )

  for _, node in ipairs ( set ) do
    if same_node(node, theNode) then return false end
  end
  return true
end

function same_node(nodeA, nodeB)
  if    nodeA.position.x == nodeB.position.x
    and nodeA.position.y == nodeB.position.y
    and nodeA.name == nodeB.name
    and nodeB.direction == nodeB.direction then
    return true
  else
    return false
  end
end

function remove_node ( set, theNode )

  for i, node in ipairs ( set ) do
    if same_node(node, theNode) then
      set [ i ] = set [ #set ]
      set [ #set ] = nil
      break
    end
  end
end

function unwind_path ( flat_path, map, current_node )

  if map [ current_node ] then
    table.insert ( flat_path, 1, map [ current_node ] )
    return unwind_path ( flat_path, map, map [ current_node ] )
  else
    return flat_path
  end
end

----------------------------------------------------------------
-- pathfinding functions
----------------------------------------------------------------

function a_star ( start, goal, valid_node_func )

  local closedset = {}
  local openset = { start }
  local came_from = {}

  if valid_node_func then is_valid_node = valid_node_func end

  local g_score, f_score = {}, {}
  g_score [ start ] = 0
  f_score [ start ] = g_score [ start ] + heuristic_cost_estimate ( start, goal )

  while #openset > 0 do

    local current = lowest_f_score ( openset, f_score )
    if same_node(current, goal) then
      local path = unwind_path ( {}, came_from, goal )
      table.insert ( path, goal )
      return path
    end

    remove_node ( openset, current )
    table.insert ( closedset, current )

    local neighbors = neighbor_nodes (current)
    for _, neighbor in ipairs ( neighbors ) do
      if not_in ( closedset, neighbor ) then

        local tentative_g_score = g_score [ current ] + dist_between ( current, neighbor )

        if not_in ( openset, neighbor ) or tentative_g_score < g_score [ neighbor ] then
          came_from   [ neighbor ] = current
          g_score   [ neighbor ] = tentative_g_score
          f_score   [ neighbor ] = g_score [ neighbor ] + heuristic_cost_estimate ( neighbor, goal )
          if not_in ( openset, neighbor ) then
            table.insert ( openset, neighbor )
          end
        end
      end
    end
  end
  return nil -- no valid path
end

----------------------------------------------------------------
-- exposed functions
----------------------------------------------------------------

function clear_cached_paths ()

  cachedPaths = nil
end

function distance ( pos1, pos2 )

  return dist ( pos1, pos2 )
end

function path ( start, goal, ignore_cache, valid_node_func )

  if not cachedPaths then cachedPaths = {} end
  if not cachedPaths [ start ] then
    cachedPaths [ start ] = {}
  elseif cachedPaths [ start ] [ goal ] and not ignore_cache then
    return cachedPaths [ start ] [ goal ]
  end

  return a_star ( start, goal, valid_node_func )
end