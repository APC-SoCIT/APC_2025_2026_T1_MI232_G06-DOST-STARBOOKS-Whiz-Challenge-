<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class PlayerBadge extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'player_badge';
    protected $table = 'player_badge';

    protected $fillable = [
        'player_info_id',
        'easy_badge_count',
        'average_badge_count',
        'difficult_badge_count',
        'official_easy_count',
        'official_average_count',
        'official_difficult_count',
    ];

    protected $casts = [
        'easy_badge_count' => 'integer',
        'average_badge_count' => 'integer',
        'difficult_badge_count' => 'integer',
        'official_easy_count' => 'integer',
        'official_average_count' => 'integer',
        'official_difficult_count' => 'integer',
    ];

    /**
     * Get the player that owns this badge record
     */
    public function player()
    {
        return $this->belongsTo(User::class, 'player_info_id', '_id');
    }

    /**
     * Get all individual badges earned (earns relationship)
     */
    public function badges()
    {
        return $this->hasMany(Badge::class, 'player_badge_id', '_id');
    }

    /**
     * Get all official badges earned
     */
    public function officialBadges()
    {
        return $this->hasMany(OfficialBadge::class, 'player_badge_id', '_id');
    }

    /**
     * Get total badge count across all difficulties
     */
    public function getTotalBadgesAttribute()
    {
        return ($this->easy_badge_count ?? 0) +
               ($this->average_badge_count ?? 0) +
               ($this->difficult_badge_count ?? 0);
    }

    /**
     * Get total official badges count
     */
    public function getTotalOfficialBadgesAttribute()
    {
        return ($this->official_easy_count ?? 0) +
               ($this->official_average_count ?? 0) +
               ($this->official_difficult_count ?? 0);
    }

    /**
     * Increment a specific badge type and check for official badge eligibility
     *
     * @param string $difficulty - 'easy', 'average', or 'difficult'
     * @return array|null - Returns official badge info if earned, null otherwise
     */
    public function incrementBadge($difficulty)
    {
        $field = $difficulty . '_badge_count';

        if (!in_array($field, $this->fillable)) {
            return null;
        }

        $this->increment($field);
        $this->refresh();

        // Check if player is eligible for an official badge (every 3 badges)
        $currentCount = $this->$field ?? 0;

        if ($currentCount % 3 === 0 && $currentCount > 0) {
            // Increment official badge count
            $officialField = 'official_' . $difficulty . '_count';
            $this->increment($officialField);
            $this->refresh();

            return [
                'difficulty' => $difficulty,
                'earned_at_count' => $currentCount,
                'official_count' => $this->$officialField ?? 1
            ];
        }

        return null;
    }

    /**
     * Check if player can claim an official badge
     *
     * @param string $difficulty
     * @return bool
     */
    public function canClaimOfficialBadge($difficulty)
    {
        $field = $difficulty . '_badge_count';
        $currentCount = $this->$field ?? 0;

        // Calculate how many official badges should exist
        $shouldHaveOfficial = floor($currentCount / 3);

        // Get actual official badges
        $officialField = 'official_' . $difficulty . '_count';
        $actualOfficial = $this->$officialField ?? 0;

        return $shouldHaveOfficial > $actualOfficial;
    }

    /**
     * Get next badge milestone
     *
     * @param string $difficulty
     * @return array
     */
    public function getNextMilestone($difficulty)
    {
        $field = $difficulty . '_badge_count';
        $currentCount = $this->$field ?? 0;

        $nextMilestone = ceil($currentCount / 3) * 3;
        if ($nextMilestone == 0) $nextMilestone = 3;
        $remaining = $nextMilestone - $currentCount;

        return [
            'current_count' => $currentCount,
            'next_milestone' => $nextMilestone,
            'badges_remaining' => $remaining
        ];
    }
}
