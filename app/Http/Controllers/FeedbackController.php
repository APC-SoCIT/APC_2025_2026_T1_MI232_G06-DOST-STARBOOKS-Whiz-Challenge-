<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use MongoDB\BSON\ObjectId;

/**
 * Stores the in-app "Rate Our Game!" feedback in the `player_feedback`
 * MongoDB collection (the same collection the admin dashboard already reads
 * for the average rating and the Player Comments list).
 *
 * One player can submit as many feedback entries as they like: every submit
 * INSERTS a new document, it never updates or replaces an earlier one.
 *
 * Document shape:
 *   player_id   ObjectId  (links to player_info._id)
 *   username    string    (copied from player_info at submit time)
 *   rating      int       (1-5)
 *   comment     string    (may be empty)
 *   created_at  date
 *   updated_at  date
 */
class FeedbackController extends Controller
{
    /** POST /players/{playerId}/feedback  body: { rating: 1-5, comment?: string } */
    public function submit(Request $request, $playerId)
    {
        try {
            $validated = $request->validate([
                'rating'  => 'required|integer|min:1|max:5',
                'comment' => 'nullable|string|max:1000',
            ]);

            try {
                $playerObjectId = new ObjectId($playerId);
            } catch (\Exception $e) {
                return response()->json(['success' => false, 'message' => 'Invalid player ID.'], 400);
            }

            $player = DB::connection('mongodb')->table('player_info')
                ->where('_id', $playerObjectId)
                ->first();

            if (!$player) {
                return response()->json(['success' => false, 'message' => 'Player not found.'], 404);
            }

            DB::connection('mongodb')->table('player_feedback')->insert([
                'player_id'  => $playerObjectId,
                'username'   => $player->username ?? 'Player',
                'rating'     => (int) $validated['rating'],
                'comment'    => trim($validated['comment'] ?? ''),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Thank you for your feedback!',
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => collect($e->errors())->flatten()->first() ?? 'Invalid feedback.',
                'errors'  => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error saving feedback: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Error saving feedback.'], 500);
        }
    }

    /** GET /players/{playerId}/feedback  -> that player's past feedback, newest first */
    public function index($playerId)
    {
        try {
            try {
                $playerObjectId = new ObjectId($playerId);
            } catch (\Exception $e) {
                return response()->json(['success' => false, 'message' => 'Invalid player ID.'], 400);
            }

            $rows = DB::connection('mongodb')->table('player_feedback')
                ->where('player_id', $playerObjectId)
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($f) {
                    $created = $f->created_at ?? null;
                    try {
                        $created = ($created && method_exists($created, 'toDateTime'))
                            ? $created->toDateTime()->format('c')
                            : (string) $created;
                    } catch (\Exception $e) {
                        $created = '';
                    }
                    return [
                        'id'         => (string) ($f->_id ?? ''),
                        'rating'     => (int) ($f->rating ?? 0),
                        'comment'    => $f->comment ?? '',
                        'created_at' => $created,
                    ];
                })
                ->values();

            return response()->json(['success' => true, 'data' => $rows, 'total' => $rows->count()]);

        } catch (\Exception $e) {
            Log::error('Error fetching feedback: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Error fetching feedback.'], 500);
        }
    }
}
