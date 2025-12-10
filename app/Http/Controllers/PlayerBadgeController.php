<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\PlayerBadge;
use App\Models\Badge;
use App\Models\OfficialBadge;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use MongoDB\BSON\ObjectId;

class PlayerBadgeController extends Controller
{
    /**
     * Award a badge to a player and automatically create official badge if milestone reached
     */
    public function awardBadge(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'player_info_id' => 'required|string',
            'badge_username' => 'required|string',
            'participates_in' => 'required|string',
            'difficulty' => 'required|in:easy,average,difficult',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Convert to ObjectId if it's a string
        $playerId = is_string($request->player_info_id)
            ? new ObjectId($request->player_info_id)
            : $request->player_info_id;

        // Get or create player badge record
        $playerBadge = PlayerBadge::firstOrCreate(
            ['player_info_id' => $playerId],
            [
                'easy_badge_count' => 0,
                'average_badge_count' => 0,
                'difficult_badge_count' => 0,
                'official_easy_count' => 0,
                'official_average_count' => 0,
                'official_difficult_count' => 0,
            ]
        );

        // Create individual badge record
        $badge = Badge::create([
            'player_badge_id' => $playerBadge->_id,
            'badge_username' => $request->badge_username,
            'participates_in' => $request->participates_in,
        ]);

        // Increment the appropriate badge count and check for official badge
        $officialBadgeInfo = $playerBadge->incrementBadge($request->difficulty);

        $response = [
            'success' => true,
            'message' => 'Badge awarded successfully',
            'data' => [
                'badge' => $badge,
                'player_badge' => $playerBadge->fresh()
            ]
        ];

        // If official badge was earned, create it and add to response
        if ($officialBadgeInfo) {
            $officialBadge = OfficialBadge::create([
                'player_badge_id' => $playerBadge->_id,
                'difficulty' => $officialBadgeInfo['difficulty'],
                'earned_date' => now(),
                'badge_number' => $officialBadgeInfo['official_count'],
                'claimed' => false,
            ]);

            $response['official_badge_earned'] = true;
            $response['official_badge'] = $officialBadge;
            $response['message'] = 'Badge awarded! You earned an official ' . ucfirst($officialBadgeInfo['difficulty']) . ' badge!';
        }

        return response()->json($response, 201);
    }

    /**
     * Get all unclaimed official badges for a player
     */
    public function getUnclaimedOfficialBadges($playerId)
    {
        try {
            // Convert string ID to ObjectId
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                // Return empty result instead of 404 for better UX
                return response()->json([
                    'success' => true,
                    'data' => [
                        'unclaimed_count' => 0,
                        'badges' => []
                    ]
                ]);
            }

            $unclaimedBadges = OfficialBadge::where('player_badge_id', $playerBadge->_id)
                ->where('claimed', false)
                ->orderBy('earned_date', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'unclaimed_count' => $unclaimedBadges->count(),
                    'badges' => $unclaimedBadges
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching unclaimed badges',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Claim an official badge
     */
    public function claimOfficialBadge($badgeId)
    {
        try {
            $badgeObjectId = new ObjectId($badgeId);
            $officialBadge = OfficialBadge::where('_id', $badgeObjectId)->first();

            if (!$officialBadge) {
                return response()->json([
                    'success' => false,
                    'message' => 'Official badge not found'
                ], 404);
            }

            if ($officialBadge->claimed) {
                return response()->json([
                    'success' => false,
                    'message' => 'This badge has already been claimed'
                ], 400);
            }

            $officialBadge->claimed = true;
            $officialBadge->save();

            return response()->json([
                'success' => true,
                'message' => 'Official badge claimed successfully!',
                'data' => $officialBadge->fresh()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error claiming badge',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Claim all unclaimed official badges for a player
     */
    public function claimAllOfficialBadges($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player badge record not found'
                ], 404);
            }

            $unclaimedBadges = OfficialBadge::where('player_badge_id', $playerBadge->_id)
                ->where('claimed', false)
                ->get();

            if ($unclaimedBadges->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'No unclaimed badges available'
                ], 404);
            }

            foreach ($unclaimedBadges as $badge) {
                $badge->claimed = true;
                $badge->save();
            }

            return response()->json([
                'success' => true,
                'message' => 'All official badges claimed successfully!',
                'claimed_count' => $unclaimedBadges->count(),
                'data' => $unclaimedBadges
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error claiming badges',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get badge progress towards next official badge
     */
    public function getBadgeProgress($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                // Return default progress instead of 404
                return response()->json([
                    'success' => true,
                    'data' => [
                        'easy' => ['current_count' => 0, 'next_milestone' => 3, 'badges_remaining' => 3],
                        'average' => ['current_count' => 0, 'next_milestone' => 3, 'badges_remaining' => 3],
                        'difficult' => ['current_count' => 0, 'next_milestone' => 3, 'badges_remaining' => 3],
                    ]
                ]);
            }

            $progress = [
                'easy' => $this->calculateProgress($playerBadge->easy_badge_count ?? 0),
                'average' => $this->calculateProgress($playerBadge->average_badge_count ?? 0),
                'difficult' => $this->calculateProgress($playerBadge->difficult_badge_count ?? 0),
            ];

            return response()->json([
                'success' => true,
                'data' => $progress
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching badge progress',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Helper to calculate progress
     */
    private function calculateProgress($currentCount)
    {
        $nextMilestone = ceil($currentCount / 3) * 3;
        if ($nextMilestone == 0) $nextMilestone = 3;
        $remaining = $nextMilestone - $currentCount;

        return [
            'current_count' => $currentCount,
            'next_milestone' => $nextMilestone,
            'badges_remaining' => $remaining
        ];
    }

    /**
     * Get all official badges (claimed and unclaimed) for a player
     */
    public function getAllOfficialBadges($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'total_official_badges' => 0,
                        'total_claimed' => 0,
                        'total_unclaimed' => 0,
                        'by_difficulty' => [
                            'easy' => [],
                            'average' => [],
                            'difficult' => [],
                        ],
                        'all_badges' => []
                    ]
                ]);
            }

            $allBadges = OfficialBadge::where('player_badge_id', $playerBadge->_id)
                ->orderBy('earned_date', 'desc')
                ->get();

            $grouped = $allBadges->groupBy('difficulty');

            return response()->json([
                'success' => true,
                'data' => [
                    'total_official_badges' => $allBadges->count(),
                    'total_claimed' => $allBadges->where('claimed', true)->count(),
                    'total_unclaimed' => $allBadges->where('claimed', false)->count(),
                    'by_difficulty' => [
                        'easy' => $grouped->get('easy', collect()),
                        'average' => $grouped->get('average', collect()),
                        'difficult' => $grouped->get('difficult', collect()),
                    ],
                    'all_badges' => $allBadges
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching official badges',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get complete player badge summary including regular and official badges
     */
    public function getPlayerBadgeSummary($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            // If no badge record exists, return defaults
            if (!$playerBadge) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'regular_badges' => [
                            'easy' => 0,
                            'average' => 0,
                            'difficult' => 0,
                            'total' => 0,
                        ],
                        'official_badges' => [
                            'easy' => 0,
                            'average' => 0,
                            'difficult' => 0,
                            'total' => 0,
                            'unclaimed' => 0,
                        ],
                        'progress' => [
                            'easy' => ['current_count' => 0, 'next_milestone' => 3, 'badges_remaining' => 3],
                            'average' => ['current_count' => 0, 'next_milestone' => 3, 'badges_remaining' => 3],
                            'difficult' => ['current_count' => 0, 'next_milestone' => 3, 'badges_remaining' => 3],
                        ],
                        'recent_badges' => [],
                        'recent_official_badges' => [],
                    ]
                ]);
            }

            // Count unclaimed badges
            $unclaimedCount = OfficialBadge::where('player_badge_id', $playerBadge->_id)
                ->where('claimed', false)
                ->count();

            // Get recent badges
            $recentBadges = Badge::where('player_badge_id', $playerBadge->_id)
                ->orderBy('earned_date', 'desc')
                ->limit(5)
                ->get();

            $recentOfficialBadges = OfficialBadge::where('player_badge_id', $playerBadge->_id)
                ->orderBy('earned_date', 'desc')
                ->limit(5)
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'regular_badges' => [
                        'easy' => $playerBadge->easy_badge_count ?? 0,
                        'average' => $playerBadge->average_badge_count ?? 0,
                        'difficult' => $playerBadge->difficult_badge_count ?? 0,
                        'total' => ($playerBadge->easy_badge_count ?? 0) +
                                   ($playerBadge->average_badge_count ?? 0) +
                                   ($playerBadge->difficult_badge_count ?? 0),
                    ],
                    'official_badges' => [
                        'easy' => $playerBadge->official_easy_count ?? 0,
                        'average' => $playerBadge->official_average_count ?? 0,
                        'difficult' => $playerBadge->official_difficult_count ?? 0,
                        'total' => ($playerBadge->official_easy_count ?? 0) +
                                   ($playerBadge->official_average_count ?? 0) +
                                   ($playerBadge->official_difficult_count ?? 0),
                        'unclaimed' => $unclaimedCount,
                    ],
                    'progress' => [
                        'easy' => $this->calculateProgress($playerBadge->easy_badge_count ?? 0),
                        'average' => $this->calculateProgress($playerBadge->average_badge_count ?? 0),
                        'difficult' => $this->calculateProgress($playerBadge->difficult_badge_count ?? 0),
                    ],
                    'recent_badges' => $recentBadges,
                    'recent_official_badges' => $recentOfficialBadges,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player badge summary',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getPlayerBadge($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);
            $playerBadge = PlayerBadge::with(['player', 'badges', 'officialBadges'])
                ->where('player_info_id', $playerObjectId)
                ->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player badge record not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $playerBadge
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player badge',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getBadgeStatistics($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);
            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player badge record not found'
                ], 404);
            }

            $totalBadges = ($playerBadge->easy_badge_count ?? 0) +
                           ($playerBadge->average_badge_count ?? 0) +
                           ($playerBadge->difficult_badge_count ?? 0);

            $totalOfficial = ($playerBadge->official_easy_count ?? 0) +
                             ($playerBadge->official_average_count ?? 0) +
                             ($playerBadge->official_difficult_count ?? 0);

            $statistics = [
                'regular_badges' => [
                    'total' => $totalBadges,
                    'easy' => $playerBadge->easy_badge_count ?? 0,
                    'average' => $playerBadge->average_badge_count ?? 0,
                    'difficult' => $playerBadge->difficult_badge_count ?? 0,
                    'easy_percentage' => $totalBadges > 0 ? round((($playerBadge->easy_badge_count ?? 0) / $totalBadges) * 100, 2) : 0,
                    'average_percentage' => $totalBadges > 0 ? round((($playerBadge->average_badge_count ?? 0) / $totalBadges) * 100, 2) : 0,
                    'difficult_percentage' => $totalBadges > 0 ? round((($playerBadge->difficult_badge_count ?? 0) / $totalBadges) * 100, 2) : 0,
                ],
                'official_badges' => [
                    'total' => $totalOfficial,
                    'easy' => $playerBadge->official_easy_count ?? 0,
                    'average' => $playerBadge->official_average_count ?? 0,
                    'difficult' => $playerBadge->official_difficult_count ?? 0,
                ]
            ];

            return response()->json([
                'success' => true,
                'data' => $statistics
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching badge statistics',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
