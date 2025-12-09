<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class PlayerProfile extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'player_profiles';

    protected $fillable = [
        'user_id',
        'total_score',
        'games_played',
        'games_won',
        'games_lost',
        'current_streak',
        'highest_streak',
        'total_playtime_minutes',
        'level',
        'experience_points',
        'accuracy_percentage',
    ];

    protected $casts = [
        'total_score' => 'integer',
        'games_played' => 'integer',
        'games_won' => 'integer',
        'games_lost' => 'integer',
        'current_streak' => 'integer',
        'highest_streak' => 'integer',
        'total_playtime_minutes' => 'integer',
        'level' => 'integer',
        'experience_points' => 'integer',
        'accuracy_percentage' => 'float',
    ];

    protected $attributes = [
        'total_score' => 0,
        'games_played' => 0,
        'games_won' => 0,
        'games_lost' => 0,
        'current_streak' => 0,
        'highest_streak' => 0,
        'total_playtime_minutes' => 0,
        'level' => 1,
        'experience_points' => 0,
        'accuracy_percentage' => 0.0,
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', '_id');
    }
}
