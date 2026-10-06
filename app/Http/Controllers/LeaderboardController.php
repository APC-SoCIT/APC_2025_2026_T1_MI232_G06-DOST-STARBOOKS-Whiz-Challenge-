<?php

namespace App\Http\Controllers;

use App\Models\PlayerBadge;
use App\Models\PlayerStats;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use MongoDB\BSON\ObjectId;

/**
 * LeaderboardController
 *
 * Handles simplified leaderboard with:
 * - Top 20 players by total badges
 * - Filtering by mode (challenge/battle)
 * - Filtering by category (Math/Science)
 * - Returns easy_count, average_count, difficult_count
 */
class LeaderboardController extends Controller
{
    /**
     * Normalize any Mongo id representation (BSON ObjectId object, plain
     * hex string, or an extended-JSON-style ['$oid' => ...] array/object)
     * down to a plain hex string.
     *
     * ✅ FIX: $playerInfoById is built from a *raw* query builder result
     * (DB::table('player_info')->get()), while badge/stat rows come from
     * an *Eloquent* model — the two don't necessarily stringify an
     * ObjectId identically. A silent mismatch here makes every
     * isset($playerInfoById[$pid]) check fail, filtering out every row
     * even when totals are nonzero — exactly the "no rankings" symptom
     * even though the underlying data is fine. Routing every id through
     * this one helper guarantees both sides compare the same format.
     */
    private static function normalizeId($value): string
    {
        if ($value instanceof \MongoDB\BSON\ObjectId) return (string) $value;
        if (is_array($value) && isset($value['$oid'])) return (string) $value['$oid'];
        if (is_object($value) && isset($value->{'$oid'})) return (string) $value->{'$oid'};
        return (string) ($value ?? '');
    }

    /**
     * Get leaderboard ranked by earned badges (top N players).
     *
     * ✅ FIX (2nd pass): the previous version(s) of this method read from
     * `player_stats` (challenge_stats / battle_stats category arrays).
     * Checking the actual database showed that collection isn't where
     * badge data lives at all — `player_badges` is, with a much simpler
     * flat schema (easy_badge_count / average_badge_count /
     * difficult_badge_count, keyed by player_info_id), and that's the
     * exact same collection + model (PlayerBadge) that BadgeController
     * already reads successfully elsewhere in the app. Rewritten to match
     * that real schema instead of the unused player_stats one.
     *
     * `?mode=challenge|battle` is still accepted (existing callers, e.g.
     * the admin dashboard, pass it) but is now a no-op — player_badges
     * tracks one running total per player, not split by game mode.
     */
    public function getLeaderboard(Request $request)
    {
        try {
            $limit = (int) $request->query('limit', 20);

            // player_info_id => [username, avatar] for display
            //
            // ✅ FIX: this used to read player_info via the raw query builder
            // (DB::connection('mongodb')->table('player_info')->get()), which
            // was silently coming back with zero rows on this environment —
            // even though the collection has real data and this exact same
            // raw-query pattern works elsewhere in the app. Rather than chase
            // that connection/driver quirk further, this now goes through the
            // App\Models\User Eloquent model instead — the same model
            // FastestTimeController already uses successfully to look up a
            // player by _id — since Eloquent models are consistently working
            // (PlayerBadge::all() below has never had this problem).
            $playerInfoById = [];
            foreach (User::all() as $p) {
                $pid = self::normalizeId($p->_id ?? null);
                if ($pid === '') continue;
                $playerInfoById[$pid] = [
                    'username' => $p->username ?? 'Player',
                    'avatar'   => $p->avatar ?? 'assets/images-avatars/Adventurer.png',
                ];
            }

            $allBadges = PlayerBadge::all();

            $leaderboard = $allBadges->map(function ($badge) use ($playerInfoById) {
                $pid = self::normalizeId($badge->player_info_id ?? null);

                // Skip badge rows whose player no longer exists
                if ($pid === '' || !isset($playerInfoById[$pid])) return null;

                $easy      = (int) ($badge->easy_badge_count      ?? 0);
                $average   = (int) ($badge->average_badge_count   ?? 0);
                $difficult = (int) ($badge->difficult_badge_count ?? 0);

                $total = $easy + $average + $difficult;
                if ($total === 0) return null;

                $info = $playerInfoById[$pid];

                return [
                    'player_id'       => $pid,
                    'username'        => $info['username'],
                    'avatar'          => $info['avatar'],
                    'easy_count'      => $easy,
                    'average_count'   => $average,
                    'difficult_count' => $difficult,
                    'total_badges'    => $total,
                ];
            })
            ->filter()
            ->sortByDesc('total_badges')
            ->take($limit)
            ->values()
            ->map(function ($player, $index) {
                $player['rank'] = $index + 1;
                return $player;
            });

            return response()->json([
                'success'       => true,
                'users'         => $leaderboard,
                'total_players' => $leaderboard->count(),
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Error fetching leaderboard: ' . $e->getMessage());
            \Log::error('Stack trace: ' . $e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Error fetching leaderboard',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get player's rank in leaderboard for a specific mode
     * Uses cumulative totals across all categories
     */
    public function getPlayerRank($playerId, Request $request)
    {
        try {
            $mode = $request->query('mode', 'challenge');

            $playerObjectId = new ObjectId($playerId);
            $playerStats = PlayerStats::where('player_id', $playerObjectId)->first();

            if (!$playerStats) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player stats not found'
                ], 404);
            }

            $statsField = $mode . '_stats';
            $stats = $playerStats->$statsField ?? [];

            // Sum across all categories
            $playerEasy = 0;
            $playerAverage = 0;
            $playerDifficult = 0;

            foreach ($stats as $categoryKey => $categoryStats) {
                $playerEasy += $categoryStats['easy'] ?? 0;
                $playerAverage += $categoryStats['average'] ?? 0;
                $playerDifficult += $categoryStats['difficult'] ?? 0;
            }

            $playerTotal = $playerEasy + $playerAverage + $playerDifficult;

            // Count how many players have more badges
            $allPlayers = PlayerStats::all();
            $rank = 1;

            foreach ($allPlayers as $player) {
                if ((string)$player->player_id === $playerId) continue;

                $otherStats = $player->$statsField ?? [];
                $otherTotal = 0;

                foreach ($otherStats as $categoryKey => $categoryStats) {
                    $otherTotal += ($categoryStats['easy'] ?? 0) +
                                  ($categoryStats['average'] ?? 0) +
                                  ($categoryStats['difficult'] ?? 0);
                }

                if ($otherTotal > $playerTotal) {
                    $rank++;
                }
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'rank' => $rank,
                    'mode' => $mode,
                    'easy_count' => $playerEasy,
                    'average_count' => $playerAverage,
                    'difficult_count' => $playerDifficult,
                    'total_badges' => $playerTotal,
                ]
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Error fetching player rank: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player rank'
            ], 500);
        }
    }

    /**
     * Get player badge counts for leaderboard display
     * This is for the badge section in the user stats panel
     *
     * ✅ FIX: same schema correction as getLeaderboard() — reads
     * player_badges (via PlayerBadge, joined on player_info_id) instead
     * of the unused player_stats challenge_stats/battle_stats shape.
     */
    public function getPlayerBadges($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => true,
                    'easy_count' => 0,
                    'average_count' => 0,
                    'difficult_count' => 0,
                ]);
            }

            $easyCount      = (int) ($playerBadge->easy_badge_count      ?? 0);
            $averageCount   = (int) ($playerBadge->average_badge_count   ?? 0);
            $difficultCount = (int) ($playerBadge->difficult_badge_count ?? 0);

            return response()->json([
                'success' => true,
                'easy_count' => $easyCount,
                'average_count' => $averageCount,
                'difficult_count' => $difficultCount,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error fetching player badges: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player badges'
            ], 500);
        }
    }
}