<?php

namespace App\Http\Controllers;

use App\Models\PlayerBadge;
use App\Models\OfficialBadge;
use Illuminate\Http\Request;
use MongoDB\BSON\ObjectId;

class OfficialBadgeController extends Controller
{
    /**
     * Record a perfect score and check for badge eligibility
     */
    public function recordPerfectScore(Request $request)
    {
        try {
            $playerId = $request->input('player_id');
            $difficulty = strtolower($request->input('difficulty')); // 'easy', 'average', 'difficult'

            if (!in_array($difficulty, ['easy', 'average', 'difficult'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid difficulty level'
                ], 400);
            }

            $playerObjectId = new ObjectId($playerId);

            // Get or create player badge record
            $playerBadge = PlayerBadge::firstOrCreate(
                ['player_info_id' => $playerObjectId],
                [
                    'easy_badge_count' => 0,
                    'average_badge_count' => 0,
                    'difficult_badge_count' => 0,
                    'official_easy_count' => 0,
                    'official_average_count' => 0,
                    'official_difficult_count' => 0,
                ]
            );

            // Increment the badge count for this difficulty
            $field = $difficulty . '_badge_count';
            $playerBadge->increment($field);
            $playerBadge->refresh();

            $currentCount = $playerBadge->$field;

            // Check if player reached a milestone (every 3 perfect scores)
            if ($currentCount % 3 === 0) {
                $officialField = 'official_' . $difficulty . '_count';
                $currentOfficialCount = $playerBadge->$officialField ?? 0;

                // Check if player already has the official badge (MAX LIMIT = 1)
                if ($currentOfficialCount >= 1) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Amazing! You\'ve already collected the official badge for ' . ucfirst($difficulty) . ' difficulty! 🏆',
                        'data' => [
                            'current_count' => $currentInSet,
                            'badges_remaining' => 3 - $currentInSet,
                            'can_claim' => false,
                            'max_badges_reached' => true,
                            'official_badge_collected' => true,
                        ]
                    ]);
                }

                // Create the ONE unclaimed official badge
                OfficialBadge::create([
                    'player_badge_id' => $playerBadge->_id,
                    'difficulty' => $difficulty,
                    'earned_date' => now(),
                    'badge_number' => 1,
                    'claimed' => false,
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Official badge unlocked! You can now claim it.',
                    'data' => [
                        'current_count' => $currentCount % 3, // Reset to 0
                        'badges_remaining' => 3,
                        'can_claim' => true,
                        'official_badge_earned' => true,
                        'badge_number' => 1,
                    ]
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Perfect score recorded!',
                'data' => [
                    'current_count' => $currentCount % 3,
                    'badges_remaining' => 3 - ($currentCount % 3),
                    'can_claim' => false,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Error recording perfect score: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error recording perfect score: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get player's badge summary with progress
     */
    public function getPlayerSummary($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'official_badges' => [
                            'easy' => 0,
                            'average' => 0,
                            'difficult' => 0,
                        ],
                        'progress' => [
                            'easy' => ['current_count' => 0, 'badges_remaining' => 3],
                            'average' => ['current_count' => 0, 'badges_remaining' => 3],
                            'difficult' => ['current_count' => 0, 'badges_remaining' => 3],
                        ]
                    ]
                ]);
            }

            $data = [
                'official_badges' => [
                    'easy' => $playerBadge->official_easy_count ?? 0,
                    'average' => $playerBadge->official_average_count ?? 0,
                    'difficult' => $playerBadge->official_difficult_count ?? 0,
                ],
                'progress' => []
            ];

            foreach (['easy', 'average', 'difficult'] as $difficulty) {
                $field = $difficulty . '_badge_count';
                $currentCount = $playerBadge->$field ?? 0;
                $currentInSet = $currentCount % 3;

                $data['progress'][$difficulty] = [
                    'current_count' => $currentInSet,
                    'badges_remaining' => $currentInSet === 0 ? 3 : (3 - $currentInSet),
                ];
            }

            return response()->json([
                'success' => true,
                'data' => $data
            ]);

        } catch (\Exception $e) {
            \Log::error('Error fetching player summary: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player summary: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get unclaimed official badges for a player
     * FIXED: Properly format the badge IDs for Flutter
     */
    public function getUnclaimedBadges($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => true,
                    'data' => ['badges' => []]
                ]);
            }

            $unclaimedBadges = OfficialBadge::where('player_badge_id', $playerBadge->_id)
                ->where('claimed', false)
                ->orderBy('earned_date', 'desc')
                ->get();

            // FIXED: Format the badges to include string IDs
            $formattedBadges = $unclaimedBadges->map(function ($badge) {
                return [
                    '_id' => (string) $badge->_id, // Convert ObjectId to string
                    'player_badge_id' => (string) $badge->player_badge_id,
                    'difficulty' => $badge->difficulty,
                    'earned_date' => $badge->earned_date,
                    'badge_number' => $badge->badge_number,
                    'claimed' => $badge->claimed,
                    'claimed_at' => $badge->claimed_at,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => ['badges' => $formattedBadges]
            ]);

        } catch (\Exception $e) {
            \Log::error('Error fetching unclaimed badges: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching unclaimed badges: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Claim an official badge
     */
    public function claimBadge($badgeId)
    {
        try {
            \Log::info('Attempting to claim badge: ' . $badgeId);

            $badgeObjectId = new ObjectId($badgeId);

            $officialBadge = OfficialBadge::find($badgeObjectId);

            if (!$officialBadge) {
                \Log::error('Badge not found: ' . $badgeId);
                return response()->json([
                    'success' => false,
                    'message' => 'Badge not found'
                ], 404);
            }

            if ($officialBadge->claimed) {
                \Log::warning('Badge already claimed: ' . $badgeId);
                return response()->json([
                    'success' => false,
                    'message' => 'Badge already claimed'
                ], 400);
            }

            // Mark badge as claimed and record the exact timestamp
            $officialBadge->claimed = true;
            $officialBadge->claimed_at = now();
            $officialBadge->save();

            \Log::info('Badge marked as claimed: ' . $badgeId);

            // Increment the official count
            $playerBadge = PlayerBadge::find($officialBadge->player_badge_id);
            if ($playerBadge) {
                $officialField = 'official_' . $officialBadge->difficulty . '_count';
                $playerBadge->increment($officialField);
                \Log::info('Incremented ' . $officialField . ' for player badge: ' . $playerBadge->_id);
            }

            return response()->json([
                'success' => true,
                'message' => 'Badge claimed successfully!',
                'data' => [
                    'difficulty' => $officialBadge->difficulty,
                    'claimed_at' => $officialBadge->claimed_at->toIso8601String(),
                    'badge_number' => $officialBadge->badge_number,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Error claiming badge: ' . $e->getMessage());
            \Log::error('Stack trace: ' . $e->getTraceAsString());
            return response()->json([
                'success' => false,
                'message' => 'Error claiming badge: ' . $e->getMessage()
            ], 500);
        }
    }
}
