<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class GameHistory extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'game_history'; // or whatever your collection name is

    protected $fillable = [
        'player_id',
        'participation_type',
        'difficulty_level',
        'score',
        'questions_answered',
        'correct_answers',
        'incorrect_answers',
        'game_duration_seconds',
        'result',
        'rewards_earned',
        'date_completed',
    ];

    protected $casts = [
        'date_completed' => 'datetime',
    ];
}
