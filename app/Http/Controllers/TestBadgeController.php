<?php

namespace App\Http\Controllers;

use App\Models\PlayerBadge;
use App\Models\OfficialBadge;
use Illuminate\Http\Request;
use MongoDB\BSON\ObjectId;

class TestBadgeController extends Controller
{
    /**
     * TEST ONLY - Create test badge data for a player
     * This will give them 3 perfect scores and an unclaimed badge
     */
    public function createTestBadges($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            // Delete existing badge data for clean test
            $existingBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();
            if ($existingBadge) {
                // Delete related official badges first
                OfficialBadge::where('player_badge_id', $existingBadge->_id)->delete();
                $existingBadge->delete();
            }

            // Create player badge record with 3 perfect scores in each difficulty
            $playerBadge = PlayerBadge::create([
                'player_info_id' => $playerObjectId,
                'easy_badge_count' => 3,      // 3 perfect scores = ready to claim
                'average_badge_count' => 2,   // 2 perfect scores = needs 1 more
                'difficult_badge_count' => 1, // 1 perfect score = needs 2 more
                'official_easy_count' => 0,   // No official badges claimed yet
                'official_average_count' => 0,
                'official_difficult_count' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Create an unclaimed official badge for EASY difficulty
            $officialBadge = OfficialBadge::create([
                'player_badge_id' => $playerBadge->_id,
                'difficulty' => 'easy',
                'earned_date' => now(),
                'badge_number' => 1,
                'claimed' => false, // NOT claimed yet - CLAIM button should show
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Test badge data created successfully!',
                'data' => [
                    'player_badge_id' => (string)$playerBadge->_id,
                    'unclaimed_badge_id' => (string)$officialBadge->_id,
                    'test_results' => [
                        'Easy: 3/3 perfect scores - CLAIM button should be GREEN and ACTIVE',
                        'Average: 2/3 perfect scores - needs 1 more (LOCKED)',
                        'Difficult: 1/3 perfect scores - needs 2 more (LOCKED)',
                    ],
                    'next_steps' => [
                        '1. Open your Flutter app',
                        '2. Click on the badge icon',
                        '3. You should see Easy badge with CLAIM button active',
                        '4. Click CLAIM to test the claim functionality',
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error creating test data: ' . $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    }

    /**
     * TEST ONLY - Create all badges ready to claim
     */
    public function createAllClaimableBadges($playerId)
    {
        try {
            // Try to create ObjectId, if it fails return helpful error
            try {
                $playerObjectId = new ObjectId($playerId);
            } catch (\Exception $e) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid player ID format. Player ID should be 24 characters (example: 693b5cb425010c522ed077502)',
                    'provided_id' => $playerId,
                    'id_length' => strlen($playerId),
                ], 400);
            }

            // Delete existing badge data
            $existingBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();
            if ($existingBadge) {
                OfficialBadge::where('player_badge_id', $existingBadge->_id)->delete();
                $existingBadge->delete();
            }

            // Create player badge with 3 perfect scores in ALL difficulties
            // BUT official counts are 0 because badges haven't been claimed yet
            $playerBadge = PlayerBadge::create([
                'player_info_id' => $playerObjectId,
                'easy_badge_count' => 3,
                'average_badge_count' => 3,
                'difficult_badge_count' => 3,
                'official_easy_count' => 0,      // FIXED: Set to 0, not claimed yet
                'official_average_count' => 0,  // FIXED: Set to 0, not claimed yet
                'official_difficult_count' => 0, // FIXED: Set to 0, not claimed yet
            ]);

            // Create unclaimed badges for ALL difficulties
            $easyBadge = OfficialBadge::create([
                'player_badge_id' => $playerBadge->_id,
                'difficulty' => 'easy',
                'earned_date' => now(),
                'badge_number' => 1,
                'claimed' => false,
            ]);

            $avgBadge = OfficialBadge::create([
                'player_badge_id' => $playerBadge->_id,
                'difficulty' => 'average',
                'earned_date' => now(),
                'badge_number' => 1,
                'claimed' => false,
            ]);

            $diffBadge = OfficialBadge::create([
                'player_badge_id' => $playerBadge->_id,
                'difficulty' => 'difficult',
                'earned_date' => now(),
                'badge_number' => 1,
                'claimed' => false,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'ALL badges ready to claim! 🎉',
                'data' => [
                    'player_badge_id' => (string)$playerBadge->_id,
                    'test_status' => [
                        'Easy: 3/3 - CLAIM button GREEN and ACTIVE ✅',
                        'Average: 3/3 - CLAIM button BLUE and ACTIVE ✅',
                        'Difficult: 3/3 - CLAIM button RED and ACTIVE ✅',
                    ],
                ],
                'badge_ids' => [
                    'easy' => (string)$easyBadge->_id,
                    'average' => (string)$avgBadge->_id,
                    'difficult' => (string)$diffBadge->_id,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Error in createAllClaimableBadges: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error creating test data: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * TEST ONLY - Reset all badge data for a player
     */
    public function resetBadges($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            // Delete all badge data
            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if ($playerBadge) {
                // Delete official badges first
                $deletedOfficial = OfficialBadge::where('player_badge_id', $playerBadge->_id)->delete();
                // Then delete player badge
                $playerBadge->delete();

                return response()->json([
                    'success' => true,
                    'message' => 'Badge data reset successfully!',
                    'deleted' => [
                        'player_badge' => 1,
                        'official_badges' => $deletedOfficial
                    ]
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'No badge data found to reset.'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error resetting badges: ' . $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    }

    /**
     * TEST ONLY - View current badge status
     */
    public function viewBadgeStatus($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => true,
                    'message' => 'No badge data found for this player.',
                    'data' => null
                ]);
            }

            $unclaimedBadges = OfficialBadge::where('player_badge_id', $playerBadge->_id)
                ->where('claimed', false)
                ->get();

            $claimedBadges = OfficialBadge::where('player_badge_id', $playerBadge->_id)
                ->where('claimed', true)
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'perfect_scores' => [
                        'easy' => $playerBadge->easy_badge_count ?? 0,
                        'average' => $playerBadge->average_badge_count ?? 0,
                        'difficult' => $playerBadge->difficult_badge_count ?? 0,
                    ],
                    'official_badges_claimed' => [
                        'easy' => $playerBadge->official_easy_count ?? 0,
                        'average' => $playerBadge->official_average_count ?? 0,
                        'difficult' => $playerBadge->official_difficult_count ?? 0,
                    ],
                    'unclaimed_badges' => $unclaimedBadges->map(function($badge) {
                        return [
                            'id' => (string)$badge->_id,
                            'difficulty' => $badge->difficulty,
                            'earned_date' => $badge->earned_date,
                            'badge_number' => $badge->badge_number,
                        ];
                    }),
                    'claimed_badges' => $claimedBadges->map(function($badge) {
                        return [
                            'id' => (string)$badge->_id,
                            'difficulty' => $badge->difficulty,
                            'earned_date' => $badge->earned_date,
                            'claimed_at' => $badge->claimed_at,
                            'badge_number' => $badge->badge_number,
                        ];
                    }),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error viewing badge status: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * TEST ONLY - Add more unclaimed badges WITHOUT resetting existing data
     * This simulates earning 3 more perfect scores in each difficulty
     */
    public function addMoreUnclaimedBadges($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            // Get or create player badge record
            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => false,
                    'message' => 'No player badge record found. Create one first using /test-badges/create/{playerId}'
                ], 404);
            }

            // Add 3 more perfect scores to each difficulty
            $playerBadge->increment('easy_badge_count', 3);
            $playerBadge->increment('average_badge_count', 3);
            $playerBadge->increment('difficult_badge_count', 3);
            $playerBadge->refresh();

            // Create new unclaimed badges for each difficulty
            $badges = [];

            foreach (['easy', 'average', 'difficult'] as $difficulty) {
                $officialField = 'official_' . $difficulty . '_count';
                $nextBadgeNumber = ($playerBadge->$officialField ?? 0) + 1;

                // Count existing unclaimed badges for this difficulty
                $unclaimedCount = OfficialBadge::where('player_badge_id', $playerBadge->_id)
                    ->where('difficulty', $difficulty)
                    ->where('claimed', false)
                    ->count();

                // Only create if there isn't already an unclaimed badge
                if ($unclaimedCount == 0) {
                    $badge = OfficialBadge::create([
                        'player_badge_id' => $playerBadge->_id,
                        'difficulty' => $difficulty,
                        'earned_date' => now(),
                        'badge_number' => $nextBadgeNumber,
                        'claimed' => false,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    $badges[$difficulty] = (string)$badge->_id;
                } else {
                    $badges[$difficulty] = 'Already has unclaimed badge';
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Added 3 more perfect scores and created new unclaimed badges! 🎉',
                'data' => [
                    'current_perfect_scores' => [
                        'easy' => $playerBadge->easy_badge_count,
                        'average' => $playerBadge->average_badge_count,
                        'difficult' => $playerBadge->difficult_badge_count,
                    ],
                    'official_badges_claimed' => [
                        'easy' => $playerBadge->official_easy_count ?? 0,
                        'average' => $playerBadge->official_average_count ?? 0,
                        'difficult' => $playerBadge->official_difficult_count ?? 0,
                    ],
                    'new_unclaimed_badges' => $badges,
                    'note' => 'Your previously claimed badges are still there! These are NEW badges ready to claim.'
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error adding more badges: ' . $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    }
}
