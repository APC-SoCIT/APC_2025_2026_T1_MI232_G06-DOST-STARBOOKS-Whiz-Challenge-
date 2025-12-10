<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class OfficialBadge extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'official_badges';
    protected $table = 'official_badges';

    protected $fillable = [
        'player_badge_id',
        'difficulty',
        'earned_date',
        'badge_number', // Which official badge is this (1st, 2nd, 3rd, etc.)
        'claimed',
    ];

    protected $casts = [
        'earned_date' => 'datetime',
        'badge_number' => 'integer',
        'claimed' => 'boolean',
    ];

    /**
     * Get the player badge record this official badge belongs to
     */
    public function playerBadge()
    {
        return $this->belongsTo(PlayerBadge::class, 'player_badge_id', '_id');
    }

    /**
     * Scope to get unclaimed badges
     */
    public function scopeUnclaimed($query)
    {
        return $query->where('claimed', false);
    }

    /**
     * Scope to get claimed badges
     */
    public function scopeClaimed($query)
    {
        return $query->where('claimed', true);
    }

    /**
     * Scope to get badges by difficulty
     */
    public function scopeByDifficulty($query, $difficulty)
    {
        return $query->where('difficulty', $difficulty);
    }

    /**
     * Mark badge as claimed
     */
    public function markAsClaimed()
    {
        $this->claimed = true;
        $this->save();
    }
}
