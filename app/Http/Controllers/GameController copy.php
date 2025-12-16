<?php

namespace App\Http\Controllers;

use App\Models\GameResult;
use App\Models\PlayerProfile;
use App\Models\PlayerProgress;
use App\Models\PlayerBadge;
use App\Models\OfficialBadge;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use MongoDB\BSON\ObjectId;

class GameController extends Controller
{
    public function saveGameResult(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'player_id' => 'required|string',
            'participation_type' => 'required|string|in:Whiz Challenge,Whiz Battle',
            'category' => 'required|string',
            'difficulty_level' => 'required|string|in:Easy,Average,Difficult',
            'score' => 'required|integer|min:0',
            'questions_answered' => 'required|integer|min:0',
            'correct_answers' => 'required|integer|min:0',
            'game_duration_seconds' => 'required|integer|min:0',
            'result' => 'required|in:won,lost,draw',
            'rewards_earned' => 'integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $validator->validated();
        $incorrect = $data['questions_answered'] - $data['correct_answers'];
        $playerId = new ObjectId($data['player_id']);

        // 1. Save game result
        $gameResult = GameResult::create([
            'player_id' => $playerId,
            'participation_type' => $data['participation_type'],
            'difficulty_level' => $data['difficulty_level'],
            'score' => $data['score'],
            'questions_answered' => $data['questions_answered'],
            'correct_answers' => $data['correct_answers'],
            'incorrect_answers' => $incorrect,
            'game_duration_seconds' => $data['game_duration_seconds'],
            'result' => $data['result'],
            'rewards_earned' => $data['rewards_earned'] ?? 0,
            'date_completed' => now(),
        ]);

        // 2. Update player profile stats
        $profile = PlayerProfile::firstOrCreate(
            ['user_id' => $playerId],
            [
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
            ]
        );

        $profile->increment('games_played');
        $profile->increment('total_score', $data['score']);
        $profile->increment('total_playtime_minutes', ceil($data['game_duration_seconds'] / 60));

        if ($data['result'] === 'won') {
            $profile->increment('games_won');
            $profile->increment('current_streak');

            if ($profile->current_streak > $profile->highest_streak) {
                $profile->highest_streak = $profile->current_streak;
            }
        } else {
            $profile->increment('games_lost');
            $profile->current_streak = 0;
        }

        $totalCorrect = GameResult::where('player_id', $playerId)->sum('correct_answers');
        $totalQuestions = GameResult::where('player_id', $playerId)->sum('questions_answered');
        $profile->accuracy_percentage = $totalQuestions > 0 ? round(($totalCorrect / $totalQuestions) * 100, 2) : 0;
        $profile->save();

        // 3. Update category progress
        $progress = PlayerProgress::firstOrCreate(
            [
                'user_id' => $playerId,
                'category' => $data['category'],
                'difficulty' => $data['difficulty_level'],
            ],
            [
                'questions_answered' => 0,
                'correct_answers' => 0,
                'incorrect_answers' => 0,
                'category_score' => 0,
            ]
        );

        $progress->increment('questions_answered', $data['questions_answered']);
        $progress->increment('correct_answers', $data['correct_answers']);
        $progress->increment('incorrect_answers', $incorrect);
        $progress->increment('category_score', $data['score']);
        $progress->last_played = now();
        $progress->save();

        // 4. Handle perfect score badge logic
        $badgeAwarded = null;
        $isPerfectScore = ($data['correct_answers'] === $data['questions_answered']) && $data['result'] === 'won';

        if ($isPerfectScore) {
            $badgeAwarded = $this->recordPerfectScore(
                (string)$playerId,
                $data['difficulty_level']
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Game result saved successfully',
            'data' => [
                'game_result' => $gameResult,
                'updated_profile' => $profile,
                'category_progress' => $progress,
                'badge_awarded' => $badgeAwarded,
            ]
        ], 201);
    }

    /**
     * Record a perfect score and create official badge if milestone reached
     */
    private function recordPerfectScore($playerId, $difficulty)
    {
        try {
            $playerObjectId = new ObjectId($playerId);
            $difficultyLower = strtolower($difficulty);

            // Get or create player badge record
            $playerBadge = PlayerBadge::firstOrCreate(
                ['player_info_id' => $playerObjectId],
                [
                    'easy_badge_count' => 0,
                    'average_badge_count' => 0,
                    'difficult_badge_count' => 0,
                    'official_easy_count' => 0,
                    'official_average_count' => 0,
                    'official_difficult_count' => 0,
                ]
            );

            // Increment the badge count
            $field = $difficultyLower . '_badge_count';
            $playerBadge->increment($field);
            $playerBadge->refresh();

            $currentCount = $playerBadge->$field;

            // Check if milestone reached (every 3 perfect scores)
            if ($currentCount % 3 === 0) {
                // Create unclaimed official badge
                $officialField = 'official_' . $difficultyLower . '_count';
                $badgeNumber = ($playerBadge->$officialField ?? 0) + 1;

                OfficialBadge::create([
                    'player_badge_id' => $playerBadge->_id,
                    'difficulty' => $difficultyLower,
                    'earned_date' => now(),
                    'badge_number' => $badgeNumber,
                    'claimed' => false,
                ]);

                return [
                    'difficulty' => $difficulty,
                    'badge_unlocked' => true,
                    'message' => 'Official badge unlocked! Visit the badge screen to claim it.',
                ];
            }

            return [
                'difficulty' => $difficulty,
                'progress' => $currentCount % 3,
                'remaining' => 3 - ($currentCount % 3),
                'message' => sprintf('%d more perfect score%s needed for next official badge',
                    3 - ($currentCount % 3),
                    (3 - ($currentCount % 3)) === 1 ? '' : 's'
                ),
            ];

        } catch (\Exception $e) {
            \Log::error('Error recording perfect score: ' . $e->getMessage());
            return null;
        }
    }

    public function getPlayerStats($userId)
    {
        try {
            $playerObjectId = new ObjectId($userId);

            $profile = PlayerProfile::where('user_id', $playerObjectId)->first();
            $progress = PlayerProgress::where('user_id', $playerObjectId)->get();
            $recentGames = GameResult::where('player_id', $playerObjectId)
                ->orderBy('date_completed', 'desc')
                ->limit(10)
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'profile' => $profile,
                    'category_progress' => $progress,
                    'recent_games' => $recentGames
                ]
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player stats',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
