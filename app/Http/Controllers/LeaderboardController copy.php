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
     * NOW SUPPORTS: difficulty and category filtering
     */
    public function getLeaderboard(Request $request)
    {
        try {
            $mode = $request->query('mode', 'challenge'); // 'challenge' or 'battle'
            $difficulty = $request->query('difficulty'); // EASY, AVERAGE, DIFFICULT
            $category = $request->query('category'); // Math, Science

            \Log::info('Leaderboard request:', [
                'mode' => $mode,
                'difficulty' => $difficulty,
                'category' => $category
            ]);

            // Get all players with their game statistics
            $leaderboard = \DB::connection('mongodb')
                ->table('player_info')
                ->get()
                ->map(function ($player) use ($mode, $difficulty, $category) {
                    $playerId = (string)$player->_id;

                    // Build query for game results
                    $query = \DB::connection('mongodb')
                        ->table('game_result')
                        ->where('player_id', $playerId)
                        ->where('participation_type', $mode === 'challenge' ? 'Whiz Challenge' : 'Whiz Battle');

                    // Add difficulty filter if provided
                    if ($difficulty) {
                        // Normalize difficulty: EASY -> Easy, AVERAGE -> Average, DIFFICULT -> Difficult
                        $normalizedDifficulty = ucfirst(strtolower($difficulty));
                        $query = $query->where('difficulty_level', $normalizedDifficulty);
                    }

                    // Add category filter if provided (Math/Science)
                    if ($category) {
                        $query = $query->where('category', $category);
                    }

                    $gameResults = $query->get();

                    // Calculate statistics
                    $totalRewards = 0;
                    $easyCount = 0;
                    $averageCount = 0;
                    $difficultCount = 0;
                    $lastClaimDate = null;

                    foreach ($gameResults as $result) {
                        // Count by difficulty
                        if (isset($result->difficulty_level)) {
                            $diff = strtolower($result->difficulty_level);
                            if ($diff === 'easy') {
                                $easyCount++;
                            } elseif ($diff === 'average' || $diff === 'medium') {
                                $averageCount++;
                            } elseif ($diff === 'difficult' || $diff === 'hard') {
                                $difficultCount++;
                            }
                        }

                        // Sum rewards
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
                        'rewards' => $totalRewards,
                        'easy_count' => $easyCount,
                        'easy' => $easyCount,
                        'average_count' => $averageCount,
                        'avg' => $averageCount,
                        'difficult_count' => $difficultCount,
                        'diff' => $difficultCount,
                        'last_claim_date' => $lastClaimDate ?? 'N/A',
                        'last' => $lastClaimDate ?? 'N/A',
                    ];
                })
                ->sortByDesc('total_rewards')
                ->values()
                ->toArray();

            return response()->json([
                'success' => true,
                'users' => $leaderboard,
                'mode' => $mode,
                'filters' => [
                    'difficulty' => $difficulty,
                    'category' => $category,
                ],
            ]);

        } catch (\Exception $e) {
            \Log::error('Leaderboard error: ' . $e->getMessage());
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
