<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class GameResult extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'game_result';

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
        'score' => 'integer',
        'questions_answered' => 'integer',
        'correct_answers' => 'integer',
        'incorrect_answers' => 'integer',
        'game_duration_seconds' => 'integer',
        'rewards_earned' => 'integer',
        'date_completed' => 'datetime',
    ];

    public function player()
    {
        return $this->belongsTo(User::class, 'player_id', '_id');
    }
}
