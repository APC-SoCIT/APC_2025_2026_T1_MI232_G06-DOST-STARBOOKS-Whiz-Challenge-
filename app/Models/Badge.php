<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Badge extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'badge';

    protected $fillable = [
        'player_badge_id',
        'badge_username',
        'participates_in',
        'earned_date',
    ];

    protected $casts = [
        'earned_date' => 'datetime',
    ];

    protected $attributes = [
        'earned_date' => null,
    ];

    public function playerBadge()
    {
        return $this->belongsTo(PlayerBadge::class, 'player_badge_id', '_id');
    }

    // Scope for filtering by participation type
    public function scopeByParticipation($query, $type)
    {
        return $query->where('participates_in', $type);
    }

    // Scope for recent badges
    public function scopeRecent($query, $limit = 10)
    {
        return $query->orderBy('earned_date', 'desc')->limit($limit);
    }
}
