<?php

namespace App\Http\Controllers;

use App\Models\GameResult;
use App\Models\GameHistory;
use App\Models\PlayerProfile;
use App\Models\PlayerProgress;
use App\Models\PlayerBadge;
use App\Models\Badge;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use MongoDB\BSON\ObjectId;

class GameController extends Controller
{
    // Save game result after quiz completion
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

        // Calculate accuracy
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

        // 4. Award badge if player won
        $badgeAwarded = null;
        if ($data['result'] === 'won') {
            $badgeAwarded = $this->awardBadge(
                (string)$playerId,
                $data['participation_type'],
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

    private function awardBadge($playerId, $participationType, $difficulty)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            // Get player info for username
            $player = \DB::connection('mongodb')
                ->table('player_info')
                ->where('_id', $playerObjectId)
                ->first();

            if (!$player) {
                return null;
            }

            // Get or create player badge record
            $playerBadge = PlayerBadge::firstOrCreate(
                ['player_info_id' => $playerObjectId],
                [
                    'easy_badge_count' => 0,
                    'average_badge_count' => 0,
                    'difficult_badge_count' => 0,
                ]
            );

            // Create individual badge record
            $badge = Badge::create([
                'player_badge_id' => $playerBadge->_id,
                'badge_username' => $player->username,
                'participates_in' => $participationType,
                'earned_date' => now(),
            ]);

            // Increment appropriate badge count
            $difficultyLower = strtolower($difficulty);
            if ($difficultyLower === 'easy') {
                $playerBadge->increment('easy_badge_count');
            } elseif (in_array($difficultyLower, ['average', 'medium'])) {
                $playerBadge->increment('average_badge_count');
            } elseif (in_array($difficultyLower, ['difficult', 'hard'])) {
                $playerBadge->increment('difficult_badge_count');
            }

            return [
                'badge_id' => (string)$badge->_id,
                'difficulty' => $difficulty,
                'participation_type' => $participationType,
            ];

        } catch (\Exception $e) {
            \Log::error('Error awarding badge: ' . $e->getMessage());
            return null;
        }
    }

    public function getGameHistory($userId)
    {
        try {
            $history = GameResult::where('player_id', new ObjectId($userId))
                ->orderBy('date_completed', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $history
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching game history',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getPlayerStats($userId)
    {
        try {
            $playerObjectId = new ObjectId($userId);

            $profile = PlayerProfile::where('user_id', $playerObjectId)->first();
            $progress = PlayerProgress::where('user_id', $playerObjectId)->get();
            $recentGames = GameHistory::where('player_id', $playerObjectId)
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

    // Add these methods to your GameController.php

    /**
     * Save or update fastest time for Memory Match or Puzzle
     */
    public function saveFastestTime(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'player_id' => 'required|string',
            'game_type' => 'required|string|in:memory_match,puzzle',
            'difficulty' => 'required|string|in:Easy,Average,Difficult',
            'time_seconds' => 'required|integer|min:0',
            'moves' => 'required|integer|min:0',
            'category' => 'nullable|string', // For puzzle only
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $data = $validator->validated();
            $playerObjectId = new ObjectId($data['player_id']);

            // Find existing record
            $record = \DB::connection('mongodb')
                ->collection('fastest_times')
                ->where('player_id', $playerObjectId)
                ->where('game_type', $data['game_type'])
                ->where('difficulty', $data['difficulty'])
                ->where('category', $data['category'] ?? null)
                ->first();

            $isNewRecord = false;

            if ($record) {
                // Update only if new time is faster
                if ($data['time_seconds'] < $record['time_seconds']) {
                    \DB::connection('mongodb')
                        ->collection('fastest_times')
                        ->where('_id', $record['_id'])
                        ->update([
                            'time_seconds' => $data['time_seconds'],
                            'moves' => $data['moves'],
                            'achieved_at' => now(),
                        ]);
                    $isNewRecord = true;
                }
            } else {
                // Create new record
                \DB::connection('mongodb')
                    ->collection('fastest_times')
                    ->insert([
                        'player_id' => $playerObjectId,
                        'game_type' => $data['game_type'],
                        'difficulty' => $data['difficulty'],
                        'category' => $data['category'] ?? null,
                        'time_seconds' => $data['time_seconds'],
                        'moves' => $data['moves'],
                        'achieved_at' => now(),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                $isNewRecord = true;
            }

            return response()->json([
                'success' => true,
                'message' => $isNewRecord ? 'New record set!' : 'Time saved',
                'is_new_record' => $isNewRecord,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error saving fastest time',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get fastest times for a player
     */
    public function getFastestTimes($playerId, $gameType)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $records = \DB::connection('mongodb')
                ->collection('fastest_times')
                ->where('player_id', $playerObjectId)
                ->where('game_type', $gameType)
                ->get();

            return response()->json([
                'success' => true,
                'data' => $records
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching fastest times',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get fastest time for specific difficulty/category
     */
    public function getFastestTime($playerId, $gameType, $difficulty, $category = null)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $query = \DB::connection('mongodb')
                ->collection('fastest_times')
                ->where('player_id', $playerObjectId)
                ->where('game_type', $gameType)
                ->where('difficulty', $difficulty);

            if ($category) {
                $query->where('category', $category);
            }

            $record = $query->first();

            return response()->json([
                'success' => true,
                'data' => $record
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching fastest time',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
