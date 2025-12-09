<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\PlayerBadge;
use App\Models\Badge;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use MongoDB\BSON\ObjectId;

class PlayerBadgeController extends Controller
{
    /**
     * Get player's badge summary
     */
    public function getPlayerBadge($playerId)
    {
        $playerBadge = PlayerBadge::with(['player', 'badges'])
            ->where('player_info_id', $playerId)
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
    }

    /**
     * Create initial badge record for a player
     */
    public function createPlayerBadge(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'player_info_id' => 'required|exists:mongodb.player_info,_id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Check if player badge already exists
        $existing = PlayerBadge::where('player_info_id', $request->player_info_id)->first();
        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Player badge record already exists'
            ], 409);
        }

        $playerBadge = PlayerBadge::create([
            'player_info_id' => $request->player_info_id,
            'easy_badge_count' => 0,
            'average_badge_count' => 0,
            'difficult_badge_count' => 0,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Player badge record created successfully',
            'data' => $playerBadge
        ], 201);
    }

    /**
     * Award a badge to a player
     */
    public function awardBadge(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'player_info_id' => 'required|exists:mongodb.player_info,_id',
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

        // Get or create player badge record
        $playerBadge = PlayerBadge::firstOrCreate(
            ['player_info_id' => $request->player_info_id],
            [
                'easy_badge_count' => 0,
                'average_badge_count' => 0,
                'difficult_badge_count' => 0,
            ]
        );

        // Create individual badge record
        $badge = Badge::create([
            'player_badge_id' => $playerBadge->_id,
            'badge_username' => $request->badge_username,
            'participates_in' => $request->participates_in,
        ]);

        // Increment the appropriate badge count
        $playerBadge->incrementBadge($request->difficulty);

        return response()->json([
            'success' => true,
            'message' => 'Badge awarded successfully',
            'data' => [
                'badge' => $badge,
                'player_badge' => $playerBadge->fresh()
            ]
        ], 201);
    }

    /**
     * Get all badges earned by a player
     */
    public function getPlayerBadges($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            // Get or create player badge record
            $playerBadge = PlayerBadge::firstOrCreate(
                ['player_info_id' => $playerObjectId],
                [
                    'easy_badge_count' => 0,
                    'average_badge_count' => 0,
                    'difficult_badge_count' => 0,
                ]
            );

            $badges = Badge::where('player_badge_id', $playerBadge->_id)
                ->orderBy('earned_date', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'summary' => [
                        'easy_badge_count' => $playerBadge->easy_badge_count ?? 0,
                        'average_badge_count' => $playerBadge->average_badge_count ?? 0,
                        'difficult_badge_count' => $playerBadge->difficult_badge_count ?? 0,
                        'total_badges' => ($playerBadge->easy_badge_count ?? 0) +
                                         ($playerBadge->average_badge_count ?? 0) +
                                         ($playerBadge->difficult_badge_count ?? 0),
                    ],
                    'badges' => $badges
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player badges',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get badges by participation type
     */
    public function getBadgesByParticipation($playerId, $participationType)
    {
        $playerBadge = PlayerBadge::where('player_info_id', $playerId)->first();

        if (!$playerBadge) {
            return response()->json([
                'success' => false,
                'message' => 'Player badge record not found'
            ], 404);
        }

        $badges = Badge::where('player_badge_id', $playerBadge->_id)
            ->byParticipation($participationType)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $badges
        ]);
    }

    /**
     * Get recent badges
     */
    public function getRecentBadges($playerId, $limit = 10)
    {
        $playerBadge = PlayerBadge::where('player_info_id', $playerId)->first();

        if (!$playerBadge) {
            return response()->json([
                'success' => false,
                'message' => 'Player badge record not found'
            ], 404);
        }

        $badges = Badge::where('player_badge_id', $playerBadge->_id)
            ->recent($limit)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $badges
        ]);
    }

    /**
     * Update badge counts manually (admin function)
     */
    public function updateBadgeCounts(Request $request, $playerId)
    {
        $validator = Validator::make($request->all(), [
            'easy_badge_count' => 'sometimes|integer|min:0',
            'average_badge_count' => 'sometimes|integer|min:0',
            'difficult_badge_count' => 'sometimes|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $playerBadge = PlayerBadge::where('player_info_id', $playerId)->first();

        if (!$playerBadge) {
            return response()->json([
                'success' => false,
                'message' => 'Player badge record not found'
            ], 404);
        }

        $playerBadge->update($request->only([
            'easy_badge_count',
            'average_badge_count',
            'difficult_badge_count'
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Badge counts updated successfully',
            'data' => $playerBadge
        ]);
    }

    /**
     * Delete a specific badge
     */
    public function deleteBadge($badgeId)
    {
        $badge = Badge::find($badgeId);

        if (!$badge) {
            return response()->json([
                'success' => false,
                'message' => 'Badge not found'
            ], 404);
        }

        $badge->delete();

        return response()->json([
            'success' => true,
            'message' => 'Badge deleted successfully'
        ]);
    }

    /**
     * Get badge statistics for a player
     */
    public function getBadgeStatistics($playerId)
    {
        $playerBadge = PlayerBadge::where('player_info_id', $playerId)->first();

        if (!$playerBadge) {
            return response()->json([
                'success' => false,
                'message' => 'Player badge record not found'
            ], 404);
        }

        $totalBadges = $playerBadge->total_badges;

        $statistics = [
            'total_badges' => $totalBadges,
            'easy_badge_count' => $playerBadge->easy_badge_count,
            'average_badge_count' => $playerBadge->average_badge_count,
            'difficult_badge_count' => $playerBadge->difficult_badge_count,
            'easy_percentage' => $totalBadges > 0 ? round(($playerBadge->easy_badge_count / $totalBadges) * 100, 2) : 0,
            'average_percentage' => $totalBadges > 0 ? round(($playerBadge->average_badge_count / $totalBadges) * 100, 2) : 0,
            'difficult_percentage' => $totalBadges > 0 ? round(($playerBadge->difficult_badge_count / $totalBadges) * 100, 2) : 0,
        ];

        return response()->json([
            'success' => true,
            'data' => $statistics
        ]);
    }
}
