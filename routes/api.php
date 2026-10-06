<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\UserController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\GameController;
use App\Http\Controllers\QuizController;
use App\Http\Controllers\BadgeController;
use App\Http\Controllers\StarsController;
use App\Http\Controllers\FeedbackController;
use App\Http\Controllers\LeaderboardController;
use App\Http\Controllers\FastestTimeController;
use App\Http\Controllers\RegionController;
use App\Http\Controllers\ProvinceController;
use App\Http\Controllers\CityController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
| Reconstructed from every controller method + every endpoint the Flutter
| app (AppConfig.baseUrl + path) actually calls. No "/api" prefix here —
| the Flutter app hits these paths directly off AppConfig.baseUrl, so
| bootstrap/app.php's ->withRouting(...) must have apiPrefix set to ''
| (empty string), not the Laravel default 'api'. Double-check that first
| or every one of these routes will 404 with a phantom /api/ in front.
*/

// ─────────────────────────────────────────────────────────────────────────
//  LOCATION (Region / Province / City)
// ─────────────────────────────────────────────────────────────────────────
Route::get('/region', [RegionController::class, 'index']);
Route::get('/province/{regionId}', [ProvinceController::class, 'getByRegion']);
Route::get('/city/{provinceId}', [CityController::class, 'getByProvince']);

// ─────────────────────────────────────────────────────────────────────────
//  PLAYER AUTH / ACCOUNT
// ─────────────────────────────────────────────────────────────────────────
Route::post('/login', [UserController::class, 'login']);           // login.dart hits this exact top-level path
Route::post('/user/register', [UserController::class, 'register']);
Route::post('/user/logout', [UserController::class, 'logout']);
Route::get('/user/profile/{id}', [UserController::class, 'profile']);
Route::get('/homepage/{id}', [UserController::class, 'homepage']);
Route::put('/user/update/{id}', [UserController::class, 'update']);
Route::put('/user/change-password/{id}', [UserController::class, 'changePassword']);
Route::get('/user/fix-location-ids', [UserController::class, 'fixUserLocationIds']);

// Tutorials
Route::get('/user/{id}/tutorial-status', [UserController::class, 'getTutorialStatus']);
Route::get('/user/{id}/game-tutorial-status', [UserController::class, 'getGameTutorialStatus']);
Route::post('/user/mark-game-tutorial-complete', [UserController::class, 'markGameTutorialComplete']);

// ─────────────────────────────────────────────────────────────────────────
//  QUIZ QUESTIONS (player-facing)
// ─────────────────────────────────────────────────────────────────────────
Route::get('/quiz/questions/{category}/{difficulty}/{yearLevel}', [QuizController::class, 'getQuestions']);
Route::get('/quiz/questions/{category}/{difficulty}', [QuizController::class, 'getQuestionsWithoutYearLevel']);
Route::post('/quiz/questions', [QuizController::class, 'addQuestion']);
Route::get('/quiz/debug', [QuizController::class, 'debug']);
Route::get('/quiz/statistics', [QuizController::class, 'getStatistics']);

// ─────────────────────────────────────────────────────────────────────────
//  GAME RESULTS (Challenge / Battle)
// ─────────────────────────────────────────────────────────────────────────
Route::post('/game/save-challenge-result', [GameController::class, 'saveChallengeResult']);
Route::post('/game/save-battle-result', [GameController::class, 'saveBattleResult']);
// NOTE: quiz_api.dart has a getPlayerStats() calling GET /game/stats/{userId}, but it's
// never actually called anywhere in the app, and no controller method returns that shape
// of data. Left out — add a route + controller method if you start using it.

// ─────────────────────────────────────────────────────────────────────────
//  FASTEST TIME (Memory Match / Puzzle)
//  NOTE: literal "all-categories" MUST be registered before the {category}
//  wildcard below it, or Laravel will swallow it as a category value.
// ─────────────────────────────────────────────────────────────────────────
Route::post('/game/fastest-time', [FastestTimeController::class, 'saveFastestTime']);
Route::get('/game/fastest-times/leaderboard', [FastestTimeController::class, 'getGlobalLeaderboard']);
Route::get('/game/fastest-time/{playerId}/all', [FastestTimeController::class, 'getPlayerAllRecords']);
Route::get('/game/fastest-time/{playerId}/rank', [FastestTimeController::class, 'getPlayerRank']);
Route::get('/game/fastest-time/{playerId}/puzzle/{difficulty}/all-categories', [FastestTimeController::class, 'getPlayerPuzzleRecordsByDifficulty']);
Route::get('/game/fastest-time/{playerId}/puzzle/{difficulty}/{category}', [FastestTimeController::class, 'getPlayerPuzzleFastestTimeByCategory']);
Route::get('/game/fastest-time/{playerId}/{gameType}/{difficulty}', [FastestTimeController::class, 'getPlayerFastestTime']);

// ─────────────────────────────────────────────────────────────────────────
//  STARS
// ─────────────────────────────────────────────────────────────────────────
Route::post('/players/{playerId}/stars', [StarsController::class, 'awardStars']);
Route::get('/players/{playerId}/stars', [StarsController::class, 'getPlayerStars']);
Route::get('/players/{playerId}/stars/rank', [StarsController::class, 'getPlayerStarsRank']);
Route::get('/players/{playerId}/milestones', [StarsController::class, 'getMilestoneHistory']);
Route::get('/stars/leaderboard', [StarsController::class, 'getStarsLeaderboard']);

// ─────────────────────────────────────────────────────────────────────────
//  BADGES (player-facing claim flow)
// ─────────────────────────────────────────────────────────────────────────
Route::get('/badges/player/{playerId}/summary', [BadgeController::class, 'getPlayerSummary']);
Route::get('/badges/player/{playerId}/rewards', [BadgeController::class, 'getPlayerRewards']);
Route::get('/badges/player/{playerId}/unclaimed', [BadgeController::class, 'getUnclaimedRewards']);
Route::post('/badges/player/{playerId}/claim', [BadgeController::class, 'claimBadge']);
Route::post('/badges/player/{playerId}/claim-all', [BadgeController::class, 'claimAllByDifficulty']);
Route::get('/badges/player/{playerId}/prize-notifications', [BadgeController::class, 'getPrizeNotifications']);
Route::post('/badges/player/{playerId}/prize-notifications/ack', [BadgeController::class, 'ackPrizeNotifications']);

// ─────────────────────────────────────────────────────────────────────────
//  LEADERBOARD (cumulative badges + per-player rank)
// ─────────────────────────────────────────────────────────────────────────
Route::get('/leaderboard', [LeaderboardController::class, 'getLeaderboard']);
Route::get('/players/{playerId}/rank', [LeaderboardController::class, 'getPlayerRank']);
Route::get('/players/{playerId}/badges', [LeaderboardController::class, 'getPlayerBadges']);

// ─────────────────────────────────────────────────────────────────────────
//  FEEDBACK ("Rate Our Game!" dialog)
// ─────────────────────────────────────────────────────────────────────────
Route::post('/players/{playerId}/feedback', [FeedbackController::class, 'submit']);
Route::get('/players/{playerId}/feedback', [FeedbackController::class, 'index']);

// ─────────────────────────────────────────────────────────────────────────
//  ADMIN — Auth
// ─────────────────────────────────────────────────────────────────────────
Route::post('/admin/login', [AdminController::class, 'login']);
Route::post('/admin/logout', [AdminController::class, 'logout']);
Route::get('/admin/profile', [AdminController::class, 'profile']);

// ─────────────────────────────────────────────────────────────────────────
//  ADMIN — Questions
// ─────────────────────────────────────────────────────────────────────────
Route::get('/admin/questions', [AdminController::class, 'getQuestions']);
Route::post('/admin/questions', [AdminController::class, 'addQuestion']);
Route::post('/admin/questions/import', [AdminController::class, 'importQuestions']);
Route::post('/admin/questions/upload-image', [AdminController::class, 'uploadQuestionImage']);
Route::put('/admin/questions/{id}', [AdminController::class, 'updateQuestion']);
Route::delete('/admin/questions/{id}/permanent', [AdminController::class, 'permanentDeleteQuestion']); // must sit above the plain {id} delete below
Route::delete('/admin/questions/{id}', [AdminController::class, 'deleteQuestion']);
Route::patch('/admin/questions/{id}/restore', [AdminController::class, 'restoreQuestion']);

// ─────────────────────────────────────────────────────────────────────────
//  ADMIN — Difficulty settings
// ─────────────────────────────────────────────────────────────────────────
Route::get('/admin/difficulty-settings', [AdminController::class, 'getDifficultySettings']);
Route::put('/admin/difficulty-settings/{level}', [AdminController::class, 'updateDifficultySettings']);

// ─────────────────────────────────────────────────────────────────────────
//  ADMIN — Players
// ─────────────────────────────────────────────────────────────────────────
Route::get('/admin/players', [AdminController::class, 'getPlayers']);
Route::post('/admin/players', [AdminController::class, 'addPlayer']);
Route::post('/admin/players/{id}/change-password', [AdminController::class, 'changePlayerPassword']);
Route::post('/admin/players/{playerId}/award-badge', [AdminController::class, 'awardBadge']);
Route::put('/admin/players/{id}', [AdminController::class, 'updatePlayer']);
Route::delete('/admin/players/{id}', [AdminController::class, 'deletePlayer']);

// ─────────────────────────────────────────────────────────────────────────
//  ADMIN — Admins management
// ─────────────────────────────────────────────────────────────────────────
Route::get('/admin/admins', [AdminController::class, 'getAdmins']);
Route::post('/admin/admins', [AdminController::class, 'addAdmin']);
Route::post('/admin/admins/{id}/change-password', [AdminController::class, 'changeAdminPassword']);
Route::put('/admin/admins/{id}', [AdminController::class, 'updateAdmin']);
Route::delete('/admin/admins/{id}', [AdminController::class, 'deleteAdmin']);

// ─────────────────────────────────────────────────────────────────────────
//  ADMIN — Analytics / Leaderboard / Audit log
// ─────────────────────────────────────────────────────────────────────────
Route::get('/admin/analytics', [AdminController::class, 'getAnalytics']);
Route::get('/admin/leaderboard/challenge', [AdminController::class, 'getChallengeLeaderboard']);
Route::get('/admin/leaderboard/battle', [AdminController::class, 'getBattleLeaderboard']);
Route::get('/admin/audit-logs', [AdminController::class, 'getAuditLogs']);
