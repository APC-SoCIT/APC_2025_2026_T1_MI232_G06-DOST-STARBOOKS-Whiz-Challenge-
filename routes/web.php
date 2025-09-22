<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TestController;

Route::get('/post', function() {
    DB::connection('mongodb')->getClient()->selectDatabase('starbooksQuiz')->selectCollection('pingTest')->insertOne(['hello' => 'world']);
    return 'test';
});



