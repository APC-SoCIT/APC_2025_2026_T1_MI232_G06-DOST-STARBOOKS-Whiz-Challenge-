<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use MongoDB\BSON\ObjectId;

class LeaderboardController extends Controller
{
    /**
     * Get leaderboard data for players
     * Aggregates data from game_result table
     */
    public function getLeaderboard(Request $request)
    {
        try {
            $mode = $request->query('mode', 'challenge'); // 'challenge' or 'battle'

            // Get all players with their game statistics
            $leaderboard = \DB::connection('mongodb')
                ->table('player_info')
                ->get()
                ->map(function ($player) use ($mode) {
                    $playerId = (string)$player->_id;

                    // Get game results for this player
                    $gameResults = \DB::connection('mongodb')
                        ->table('game_result')
                        ->where('player_id', $playerId)
                        ->where('participation_type', $mode === 'challenge' ? 'Whiz Challenge' : 'Whiz Battle')
                        ->get();

                    // Calculate statistics
                    $totalRewards = 0;
                    $easyCount = 0;
                    $averageCount = 0;
                    $difficultCount = 0;
                    $lastClaimDate = null;

                    foreach ($gameResults as $result) {
                        // Count by difficulty
                        if (isset($result->difficulty_level)) {
                            $difficulty = strtolower($result->difficulty_level);
                            if ($difficulty === 'easy') {
                                $easyCount++;
                            } elseif ($difficulty === 'average' || $difficulty === 'medium') {
                                $averageCount++;
                            } elseif ($difficulty === 'difficult' || $difficulty === 'hard') {
                                $difficultCount++;
                            }
                        }

                        // Sum rewards (assuming there's a reward field)
                        if (isset($result->rewards_earned)) {
                            $totalRewards += $result->rewards_earned;
                        }

                        // Track latest claim date
                        if (isset($result->date_completed)) {
                            $resultDate = is_string($result->date_completed)
                                ? $result->date_completed
                                : $result->date_completed->toDateTime()->format('m/d/Y H:i');

                            if (!$lastClaimDate || strtotime($resultDate) > strtotime($lastClaimDate)) {
                                $lastClaimDate = $resultDate;
                            }
                        }
                    }

                    return [
                        'id' => $playerId,
                        '_id' => ['$oid' => $playerId],
                        'username' => $player->username ?? 'Unknown',
                        'avatar' => $player->avatar ?? 'assets/images-avatars/Adventurer.png',
                        'total_rewards' => $totalRewards,
                        'rewards' => $totalRewards, // Alias for compatibility
                        'easy_count' => $easyCount,
                        'easy' => $easyCount, // Alias for compatibility
                        'average_count' => $averageCount,
                        'avg' => $averageCount, // Alias for compatibility
                        'difficult_count' => $difficultCount,
                        'diff' => $difficultCount, // Alias for compatibility
                        'last_claim_date' => $lastClaimDate ?? 'N/A',
                        'last' => $lastClaimDate ?? 'N/A', // Alias for compatibility
                    ];
                })
                ->sortByDesc('total_rewards') // Sort by total rewards descending
                ->values() // Reset array keys
                ->toArray();

            return response()->json([
                'success' => true,
                'users' => $leaderboard,
                'mode' => $mode,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => 'Error fetching leaderboard data',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get a specific player's rank and stats
     */
    public function getPlayerRank($playerId, Request $request)
    {
        try {
            $mode = $request->query('mode', 'challenge');

            // Get full leaderboard
            $request->merge(['mode' => $mode]);
            $leaderboardResponse = $this->getLeaderboard($request);
            $leaderboard = json_decode($leaderboardResponse->content(), true);

            if (!$leaderboard['success']) {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to fetch leaderboard'
                ], 500);
            }

            // Find player's position
            $users = $leaderboard['users'];
            $playerRank = null;
            $playerData = null;

            foreach ($users as $index => $user) {
                if ($user['id'] === $playerId || $user['_id']['$oid'] === $playerId) {
                    $playerRank = $index + 1;
                    $playerData = $user;
                    break;
                }
            }

            if (!$playerData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player not found in leaderboard'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'rank' => $playerRank,
                'player' => $playerData,
                'total_players' => count($users),
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => 'Error fetching player rank',
                'message' => $e->getMessage()
            ], 500);
        }
    }
}
