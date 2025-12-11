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
    Route::post('/award', [PlayerBadgeController::class, 'awardBadge']);
    Route::get('/player/{playerId}/summary', [PlayerBadgeController::class, 'getPlayerBadgeSummary']);
    Route::get('/player/{playerId}/progress', [PlayerBadgeController::class, 'getBadgeProgress']);
    Route::prefix('official')->group(function () {
        Route::get('/player/{playerId}', [PlayerBadgeController::class, 'getAllOfficialBadges']);
        Route::get('/player/{playerId}/unclaimed', [PlayerBadgeController::class, 'getUnclaimedOfficialBadges']);
        Route::post('/{badgeId}/claim', [PlayerBadgeController::class, 'claimOfficialBadge']);
           Route::post('/player/{playerId}/claim-all', [PlayerBadgeController::class, 'claimAllOfficialBadges']);
    });
    Route::get('/player/{playerId}/statistics', [PlayerBadgeController::class, 'getBadgeStatistics']);
    Route::get('/player/{playerId}', [PlayerBadgeController::class, 'getPlayerBadge']);
});

// Leaderboard
Route::get('/leaderboard', [LeaderboardController::class, 'getLeaderboard']);
Route::get('/leaderboard/player/{playerId}', [LeaderboardController::class, 'getPlayerRank']);

// Utility (remove in production)
Route::get('/fix-user-locations', [UserController::class, 'fixUserLocationIds']);

// Fastest Time Records (Memory Match & Puzzle)
Route::prefix('game')->group(function () {
    Route::post('/fastest-time', [FastestTimeController::class, 'saveFastestTime']);
    Route::get('/fastest-time/{playerId}/{gameType}/{difficulty}', [FastestTimeController::class, 'getPlayerFastestTime']);
    Route::get('/fastest-time/{playerId}/all', [FastestTimeController::class, 'getPlayerAllRecords']);
    Route::get('/fastest-time/{playerId}/rank', [FastestTimeController::class, 'getPlayerRank']);
    Route::get('/fastest-time/{playerId}/puzzle/{difficulty}/all-categories', [FastestTimeController::class, 'getPlayerPuzzleRecordsByDifficulty']);
    Route::get('/fastest-times/leaderboard', [FastestTimeController::class, 'getGlobalLeaderboard']);
});
