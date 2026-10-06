<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class PlayerStats extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'player_stats';

    protected $fillable = [
        'player_id',
        'username',
        'avatar',
        'challenge_stats',
        'battle_stats',
        'memory_match_stats',
        'puzzle_stats',
    ];

    protected $casts = [
        'player_id' => 'string',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the player
     */
    public function player()
    {
        return $this->belongsTo(User::class, 'player_id', '_id');
    }

    /**
     * Update player stats for any game type.
     *
     * ✅ FIX: previously did "check if a player_stats doc exists → create
     * one, else update the existing one" as two separate steps. Two
     * near-simultaneous requests could both see "doesn't exist yet" and
     * both create a doc — that's why you had duplicate player_stats rows
     * per player in Compass, each holding a partial count. A single
     * $inc + upsert is atomic: Mongo either creates the doc or increments
     * the existing one in ONE operation, so this can't happen anymore.
     */
    public static function updateStats($playerId, $gameType, $category, $difficulty, $result, $score = 0)
    {
        try {
            $playerObjectId = new \MongoDB\BSON\ObjectId($playerId);
            $categoryKey    = $category ? strtolower($category) : 'general';
            $difficultyKey  = strtolower($difficulty);

            $shouldIncrement = in_array($gameType, ['challenge', 'battle'])
                ? ($result === 'won')
                : true;

            if (!$shouldIncrement) {
                \Illuminate\Support\Facades\Log::info('Skipping player_stats increment - no win to record', [
                    'player_id' => $playerId,
                    'game_type' => $gameType,
                    'result'    => $result,
                ]);
                return true;
            }

            $statsField = $gameType . '_stats';
            $incPath    = "{$statsField}.{$categoryKey}.{$difficultyKey}";

            // Only needed if this upsert ends up CREATING a new doc.
            $player = \Illuminate\Support\Facades\DB::connection('mongodb')
                ->table('player_info')
                ->where('_id', $playerObjectId)
                ->first();

            // ✅ FIX: previously fell back to 'Unknown'/default avatar and
            // wrote the increment anyway when $player was null — producing a
            // player_stats row with no matching player_info document. Admin
            // analytics (gender/age by game mode) then has nothing to
            // attribute that play to and has to skip it. Callers
            // (GameController) now check the player exists before calling
            // this, but bail here too as a second line of defense so this
            // method can never create an orphaned row on its own.
            if (!$player) {
                \Illuminate\Support\Facades\Log::warning('Skipping player_stats update - no matching player_info document', [
                    'player_id' => $playerId,
                    'game_type' => $gameType,
                ]);
                return false;
            }

            self::raw(function ($collection) use ($playerObjectId, $player, $incPath) {
                return $collection->updateOne(
                    ['player_id' => $playerObjectId],
                    [
                        '$inc'         => [$incPath => 1],
                        '$setOnInsert' => [
                            'player_id' => $playerObjectId,
                            'username'  => $player->username ?? 'Unknown',
                            'avatar'    => $player->avatar ?? 'assets/images-avatars/Adventurer.png',
                        ],
                    ],
                    ['upsert' => true]
                );
            });

            \Illuminate\Support\Facades\Log::info('✅ Player stats incremented (atomic upsert)', [
                'player_id' => $playerId,
                'path'      => $incPath,
            ]);

            return true;
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Error updating player stats: ' . $e->getMessage());
            \Illuminate\Support\Facades\Log::error($e->getTraceAsString());
            return false;
        }
    }

    /**
     * Get total wins for a specific mode
     */
    public function getTotalWins($mode)
    {
        $statsField = $mode . '_stats';
        $stats = $this->$statsField ?? [];

        $total = 0;
        foreach ($stats as $categoryStats) {
            if (is_array($categoryStats)) {
                foreach ($categoryStats as $count) {
                    $total += $count;
                }
            }
        }

        return $total;
    }

    /**
     * Get wins by difficulty for a mode
     */
    public function getWinsByDifficulty($mode, $difficulty)
    {
        $statsField = $mode . '_stats';
        $stats = $this->$statsField ?? [];

        $total = 0;
        foreach ($stats as $categoryStats) {
            if (is_array($categoryStats) && isset($categoryStats[$difficulty])) {
                $total += $categoryStats[$difficulty];
            }
        }

        return $total;
    }

    /**
     * Get wins by category for a mode
     */
    public function getWinsByCategory($mode, $category)
    {
        $statsField = $mode . '_stats';
        $stats = $this->$statsField ?? [];

        $categoryKey = strtolower($category);
        $categoryStats = $stats[$categoryKey] ?? [];

        $total = 0;
        if (is_array($categoryStats)) {
            foreach ($categoryStats as $count) {
                $total += $count;
            }
        }

        return $total;
    }
}