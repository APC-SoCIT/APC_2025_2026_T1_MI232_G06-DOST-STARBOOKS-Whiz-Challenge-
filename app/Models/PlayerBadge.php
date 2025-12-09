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
    ];

    protected $casts = [
        'easy_badge_count' => 'integer',
        'average_badge_count' => 'integer',
        'difficult_badge_count' => 'integer',
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
     * Get total badge count across all difficulties
     */
    public function getTotalBadgesAttribute()
    {
        return $this->easy_badge_count +
               $this->average_badge_count +
               $this->difficult_badge_count;
    }

    /**
     * Increment a specific badge type
     *
     * @param string $type - 'easy', 'average', 'difficult', or 'official'
     */
    public function incrementBadge($type)
    {
        $field = $type . '_badge_count';
        if (in_array($field, $this->fillable)) {
            $this->increment($field);
        }
    }
}
