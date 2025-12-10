<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Badge extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'badge';
    protected $table = 'badge';

    protected $fillable = [
        'player_badge_id',
        'badge_username',
        'participates_in',
        'earned_date',
    ];

    protected $casts = [
        'earned_date' => 'datetime',
    ];

    /**
     * Boot method to set earned_date automatically
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($badge) {
            if (!$badge->earned_date) {
                $badge->earned_date = now();
            }
        });
    }

    /**
     * Get the player badge record this badge belongs to
     */
    public function playerBadge()
    {
        return $this->belongsTo(PlayerBadge::class, 'player_badge_id', '_id');
    }

    /**
     * Scope to get badges by participation type
     */
    public function scopeByParticipation($query, $participationType)
    {
        return $query->where('participates_in', $participationType);
    }

    /**
     * Scope to get recent badges
     */
    public function scopeRecent($query, $limit = 10)
    {
        return $query->orderBy('earned_date', 'desc')->limit($limit);
    }
}
