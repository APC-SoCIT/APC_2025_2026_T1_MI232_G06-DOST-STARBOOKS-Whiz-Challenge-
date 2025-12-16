<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;
use App\Http\Controllers\RegionController;
use App\Http\Controllers\ProvinceController;
use App\Http\Controllers\CityController;
use App\Http\Controllers\LeaderboardController;
use App\Http\Controllers\QuizController;
use App\Http\Controllers\GameController;
use App\Http\Controllers\FastestTimeController;
use App\Http\Controllers\PlayerBadgeController;
use App\Http\Controllers\OfficialBadgeController; // THIS IS CRITICAL!
use App\Http\Controllers\TestBadgeController; // FOR TESTING ONLY

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

// UPDATED BADGE SYSTEM - Official Badges with Claim Feature
Route::prefix('badges')->group(function () {
    // NEW: Get player's badge summary (progress + official badges count)
    Route::get('/player/{playerId}/summary', [OfficialBadgeController::class, 'getPlayerSummary']);

    // NEW: Get unclaimed official badges for a player
    Route::get('/official/player/{playerId}/unclaimed', [OfficialBadgeController::class, 'getUnclaimedBadges']);

    // NEW: Claim a specific official badge
    Route::post('/official/{badgeId}/claim', [OfficialBadgeController::class, 'claimBadge']);

    // OLD routes (can keep for backward compatibility or remove if not used)
    Route::post('/record-perfect-quiz', [PlayerBadgeController::class, 'recordPerfectQuiz']);
    Route::get('/player/{playerId}', [PlayerBadgeController::class, 'getPlayerBadges']);
    Route::post('/claim', [PlayerBadgeController::class, 'claimBadge']);
});

// ===== TEST ROUTES - REMOVE IN PRODUCTION =====
Route::prefix('test-badges')->group(function () {
    Route::get('/create/{playerId}', [TestBadgeController::class, 'createTestBadges']);
    Route::get('/create-all/{playerId}', [TestBadgeController::class, 'createAllClaimableBadges']);
    Route::get('/reset/{playerId}', [TestBadgeController::class, 'resetBadges']);
    Route::get('/status/{playerId}', [TestBadgeController::class, 'viewBadgeStatus']);
    Route::get('/add-more/{playerId}', [TestBadgeController::class, 'addMoreUnclaimedBadges']);
});
// ===== END TEST ROUTES =====
