<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use MongoDB\BSON\ObjectId;
use Illuminate\Support\Facades\DB;

class PlayerBadgeController extends Controller
{
    /**
     * Record a perfect quiz completion
     * Call this when player gets 10/10 in a quiz
     */
    public function recordPerfectQuiz(Request $request)
    {
        try {
            $playerId = $request->input('player_id');
            $difficulty = $request->input('difficulty'); // 'easy', 'average', 'difficult'

            // Validate difficulty
            if (!in_array($difficulty, ['easy', 'average', 'difficult'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid difficulty level'
                ], 400);
            }

            $playerObjectId = new ObjectId($playerId);

            // Get or create player badge record
            $playerBadge = DB::connection('mongodb')
                ->table('player_badges')
                ->where('player_info_id', $playerObjectId)
                ->first();

            if (!$playerBadge) {
                // Create new badge record
                $badgeData = [
                    'player_info_id' => $playerObjectId,
                    'easy_count' => $difficulty === 'easy' ? 1 : 0,
                    'average_count' => $difficulty === 'average' ? 1 : 0,
                    'difficult_count' => $difficulty === 'difficult' ? 1 : 0,
                    'easy_badges' => 0,
                    'average_badges' => 0,
                    'difficult_badges' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                DB::connection('mongodb')
                    ->table('player_badges')
                    ->insert($badgeData);

                return response()->json([
                    'success' => true,
                    'message' => 'First perfect quiz recorded!',
                    'data' => [
                        'current_count' => 1,
                        'needed' => 3,
                        'remaining' => 2,
                        'can_claim' => false
                    ]
                ]);
            }

            // Update existing record
            $currentCount = $playerBadge->{$difficulty . '_count'} ?? 0;
            $newCount = $currentCount + 1;

            // Check if player reached 3 perfect quizzes
            $canClaim = ($newCount % 3 === 0);

            if ($canClaim) {
                // Increment badge count
                DB::connection('mongodb')
                    ->table('player_badges')
                    ->where('player_info_id', $playerObjectId)
                    ->update([
                        $difficulty . '_count' => $newCount,
                        $difficulty . '_badges' => ($playerBadge->{$difficulty . '_badges'} ?? 0) + 1,
                        'updated_at' => now(),
                    ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Badge available to claim!',
                    'data' => [
                        'current_count' => $newCount,
                        'needed' => 3,
                        'remaining' => 0,
                        'can_claim' => true,
                        'badge_earned' => true
                    ]
                ]);
            } else {
                // Just update count
                DB::connection('mongodb')
                    ->table('player_badges')
                    ->where('player_info_id', $playerObjectId)
                    ->update([
                        $difficulty . '_count' => $newCount,
                        'updated_at' => now(),
                    ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Perfect quiz recorded!',
                    'data' => [
                        'current_count' => $newCount,
                        'needed' => 3,
                        'remaining' => 3 - ($newCount % 3),
                        'can_claim' => false
                    ]
                ]);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error recording quiz: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get player's badge summary
     */
    public function getPlayerBadges($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = DB::connection('mongodb')
                ->table('player_badges')
                ->where('player_info_id', $playerObjectId)
                ->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'easy' => [
                            'current_count' => 0,
                            'badges_earned' => 0,
                            'can_claim' => false,
                            'remaining' => 3
                        ],
                        'average' => [
                            'current_count' => 0,
                            'badges_earned' => 0,
                            'can_claim' => false,
                            'remaining' => 3
                        ],
                        'difficult' => [
                            'current_count' => 0,
                            'badges_earned' => 0,
                            'can_claim' => false,
                            'remaining' => 3
                        ]
                    ]
                ]);
            }

            $data = [];
            foreach (['easy', 'average', 'difficult'] as $difficulty) {
                $count = $playerBadge->{$difficulty . '_count'} ?? 0;
                $badges = $playerBadge->{$difficulty . '_badges'} ?? 0;
                $currentInSet = $count % 3;

                $data[$difficulty] = [
                    'current_count' => $currentInSet,
                    'badges_earned' => $badges,
                    'can_claim' => ($currentInSet === 0 && $count > 0 && $badges * 3 < $count),
                    'remaining' => $currentInSet === 0 ? 0 : (3 - $currentInSet)
                ];
            }

            return response()->json([
                'success' => true,
                'data' => $data
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching badges: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Claim a badge (mark it as claimed)
     */
    public function claimBadge(Request $request)
    {
        try {
            $playerId = $request->input('player_id');
            $difficulty = $request->input('difficulty');

            if (!in_array($difficulty, ['easy', 'average', 'difficult'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid difficulty level'
                ], 400);
            }

            $playerObjectId = new ObjectId($playerId);

            $playerBadge = DB::connection('mongodb')
                ->table('player_badges')
                ->where('player_info_id', $playerObjectId)
                ->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => false,
                    'message' => 'No badge record found'
                ], 404);
            }

            $count = $playerBadge->{$difficulty . '_count'} ?? 0;
            $badges = $playerBadge->{$difficulty . '_badges'} ?? 0;

            // Check if there's a badge to claim
            if ($count % 3 !== 0 || $count === 0 || $badges * 3 >= $count) {
                return response()->json([
                    'success' => false,
                    'message' => 'No badge available to claim'
                ], 400);
            }

            // Badge is already counted, just mark as "claimed" by resetting the count cycle
            return response()->json([
                'success' => true,
                'message' => 'Badge claimed successfully!',
                'data' => [
                    'difficulty' => $difficulty,
                    'badges_earned' => $badges
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error claiming badge: ' . $e->getMessage()
            ], 500);
        }
    }
}
