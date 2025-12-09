<?php

namespace App\Http\Controllers;

use App\Models\FastestTime;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use MongoDB\BSON\ObjectId;

class FastestTimeController extends Controller
{
    /**
     * Save or update fastest time record
     */
    public function saveFastestTime(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'player_id' => 'required|string',
            'game_type' => 'required|in:memory_match,puzzle',
            'difficulty' => 'required|in:EASY,AVERAGE,DIFFICULT',
            'category' => 'nullable|string', // For puzzle only
            'time_seconds' => 'required|integer|min:1',
            'moves' => 'required|integer|min:0',
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

            // Get player username
            $player = User::find($playerObjectId);
            if (!$player) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player not found'
                ], 404);
            }

            // Build query to find existing record
            $query = [
                'player_id' => $playerObjectId,
                'game_type' => $data['game_type'],
                'difficulty' => $data['difficulty'],
            ];

            // Add category for puzzle
            if ($data['game_type'] === 'puzzle' && isset($data['category'])) {
                $query['category'] = $data['category'];
            }

            // Find existing record
            $existing = FastestTime::where($query)->first();

            $isNewRecord = false;
            $isFasterTime = false;

            if ($existing) {
                // Check if new time is faster
                if ($data['time_seconds'] < $existing->time_seconds) {
                    $existing->update([
                        'time_seconds' => $data['time_seconds'],
                        'moves' => $data['moves'],
                        'achieved_at' => now(),
                    ]);
                    $isNewRecord = true;
                    $isFasterTime = true;
                    $record = $existing;
                } else {
                    $record = $existing;
                }
            } else {
                // Create new record
                $record = FastestTime::create([
                    'player_id' => $playerObjectId,
                    'player_username' => $player->username,
                    'game_type' => $data['game_type'],
                    'difficulty' => $data['difficulty'],
                    'category' => $data['category'] ?? null,
                    'time_seconds' => $data['time_seconds'],
                    'moves' => $data['moves'],
                    'achieved_at' => now(),
                ]);
                $isNewRecord = true;
            }

            return response()->json([
                'success' => true,
                'is_new_record' => $isNewRecord,
                'is_faster_time' => $isFasterTime,
                'data' => $record,
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
     * Get player's fastest time
     */
    public function getPlayerFastestTime($playerId, $gameType, $difficulty, $category = null)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $query = [
                'player_id' => $playerObjectId,
                'game_type' => $gameType,
                'difficulty' => $difficulty,
            ];

            if ($gameType === 'puzzle' && $category) {
                $query['category'] = $category;
            }

            $record = FastestTime::where($query)->first();

            return response()->json([
                'success' => true,
                'data' => $record,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching fastest time',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get global leaderboard (top 10 fastest times)
     */
    public function getGlobalLeaderboard(Request $request)
    {
        try {
            $gameType = $request->query('game_type', 'memory_match');
            $difficulty = $request->query('difficulty', 'EASY');
            $category = $request->query('category'); // For puzzle
            $limit = $request->query('limit', 10);

            $query = FastestTime::byGameType($gameType)
                ->byDifficulty($difficulty);

            if ($gameType === 'puzzle' && $category) {
                $query = $query->byCategory($category);
            }

            $leaderboard = $query->topFastest($limit)->get();

            return response()->json([
                'success' => true,
                'game_type' => $gameType,
                'difficulty' => $difficulty,
                'category' => $category,
                'data' => $leaderboard,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching leaderboard',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get all fastest times for a player
     */
    public function getPlayerAllRecords($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $records = FastestTime::where('player_id', $playerObjectId)
                ->orderBy('achieved_at', 'desc')
                ->get()
                ->groupBy('game_type');

            return response()->json([
                'success' => true,
                'data' => $records,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player records',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get player's rank in global leaderboard
     */
    public function getPlayerRank(Request $request, $playerId)
    {
        try {
            $gameType = $request->query('game_type', 'memory_match');
            $difficulty = $request->query('difficulty', 'EASY');
            $category = $request->query('category');

            $playerObjectId = new ObjectId($playerId);

            // Get all times for this game/difficulty/category
            $query = FastestTime::byGameType($gameType)
                ->byDifficulty($difficulty);

            if ($gameType === 'puzzle' && $category) {
                $query = $query->byCategory($category);
            }

            $allTimes = $query->orderBy('time_seconds', 'asc')->get();

            // Find player's rank
            $rank = null;
            $playerRecord = null;

            foreach ($allTimes as $index => $record) {
                if ((string)$record->player_id === (string)$playerObjectId) {
                    $rank = $index + 1;
                    $playerRecord = $record;
                    break;
                }
            }

            return response()->json([
                'success' => true,
                'rank' => $rank,
                'total_players' => $allTimes->count(),
                'player_record' => $playerRecord,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player rank',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
