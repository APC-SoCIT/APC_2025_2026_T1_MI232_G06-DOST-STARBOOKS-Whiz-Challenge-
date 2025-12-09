<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class PlayerProgress extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'player_progress';

    protected $fillable = [
        'user_id',
        'category',
        'difficulty',
        'questions_answered',
        'correct_answers',
        'incorrect_answers',
        'category_score',
        'last_played',
    ];

    protected $casts = [
        'questions_answered' => 'integer',
        'correct_answers' => 'integer',
        'incorrect_answers' => 'integer',
        'category_score' => 'integer',
        'last_played' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', '_id');
    }
}
