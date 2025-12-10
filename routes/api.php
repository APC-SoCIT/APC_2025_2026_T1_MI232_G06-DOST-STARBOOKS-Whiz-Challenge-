<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;
use App\Http\Controllers\RegionController;
use App\Http\Controllers\ProvinceController;
use App\Http\Controllers\CityController;
use App\Http\Controllers\PlayerBadgeController;
use App\Http\Controllers\LeaderboardController;
use App\Http\Controllers\QuizController;
use App\Http\Controllers\GameController;
use App\Http\Controllers\FastestTimeController;

// Auth & User
Route::post('/register', [UserController::class, 'register']);
Route::post('/login', [UserController::class, 'login']);
Route::get('/user/profile/{id}', [UserController::class, 'profile']);
Route::put('/user/update/{id}', [UserController::class, 'update']);
Route::get('/homepage/{id}', [UserController::class, 'homepage']);
Route::put('/user/change-password/{id}', [UserController::class, 'changePassword']);

// Location
Route::get('/region', [RegionController::class, 'index']);
Route::get('/province/{regionId}', [ProvinceController::class, 'getByRegion']);
Route::get('/city/{provinceId}', [CityController::class, 'getByProvince']);

// Quiz
Route::get('/quiz/questions/{category}/{difficulty}', [QuizController::class, 'getQuestions']);
Route::get('/quiz/statistics', [QuizController::class, 'getStatistics']);
Route::get('/quiz/debug', [QuizController::class, 'debug']);

// Game Results
Route::post('/game/save-result', [GameController::class, 'saveGameResult']);
Route::get('/game/history/{userId}', [GameController::class, 'getGameHistory']);
Route::get('/game/stats/{userId}', [GameController::class, 'getPlayerStats']);

Route::prefix('badges')->group(function () {

    // Award a badge (automatically creates official badge if milestone reached)
    Route::post('/award', [PlayerBadgeController::class, 'awardBadge']);

    // Get player badge summary (overview of everything)
    Route::get('/player/{playerId}/summary', [PlayerBadgeController::class, 'getPlayerBadgeSummary']);

    // Get badge progress towards next milestone
    Route::get('/player/{playerId}/progress', [PlayerBadgeController::class, 'getBadgeProgress']);

    // Official badge endpoints
    Route::prefix('official')->group(function () {
        // Get all official badges for a player
        Route::get('/player/{playerId}', [PlayerBadgeController::class, 'getAllOfficialBadges']);

        // Get unclaimed official badges
        Route::get('/player/{playerId}/unclaimed', [PlayerBadgeController::class, 'getUnclaimedOfficialBadges']);

        // Claim a specific official badge
        Route::post('/{badgeId}/claim', [PlayerBadgeController::class, 'claimOfficialBadge']);

        // Claim all unclaimed badges at once
        Route::post('/player/{playerId}/claim-all', [PlayerBadgeController::class, 'claimAllOfficialBadges']);
    });

    // Get badge statistics
    Route::get('/player/{playerId}/statistics', [PlayerBadgeController::class, 'getBadgeStatistics']);

    // Get player badge record
    Route::get('/player/{playerId}', [PlayerBadgeController::class, 'getPlayerBadge']);
});

// Leaderboard
Route::get('/leaderboard', [LeaderboardController::class, 'getLeaderboard']);
Route::get('/leaderboard/player/{playerId}', [LeaderboardController::class, 'getPlayerRank']);

// Utility (remove in production)
Route::get('/fix-user-locations', [UserController::class, 'fixUserLocationIds']);

// Fastest Time Records (Memory Match & Puzzle)
Route::post('/game/fastest-time', [FastestTimeController::class, 'saveFastestTime']);
Route::get('/game/fastest-time/{playerId}/{gameType}/{difficulty}/{category?}', [FastestTimeController::class, 'getPlayerFastestTime']);
Route::get('/game/fastest-times/leaderboard', [FastestTimeController::class, 'getGlobalLeaderboard']);
Route::get('/game/fastest-times/player/{playerId}/all', [FastestTimeController::class, 'getPlayerAllRecords']);
Route::get('/game/fastest-times/player/{playerId}/rank', [FastestTimeController::class, 'getPlayerRank']);
