<?php

namespace App\Http\Controllers;

use App\Models\AdminAuditLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use MongoDB\BSON\ObjectId;

class AdminController extends Controller
{
    // The built-in superadmin account — protected from deletion regardless
    // of who's calling the endpoint or how.
    const SUPERADMIN_USERNAME = 'starbooks_admin';

    // ══════════════════════════════════════════════════════════════════════════
    //  HELPERS
    // ══════════════════════════════════════════════════════════════════════════

    /** Extract Bearer token from Authorization header or ?token= query param */
    private function extractToken(Request $request): ?string
    {
        $header = $request->header('Authorization', '');
        if (str_starts_with($header, 'Bearer ')) return substr($header, 7);
        return $request->get('token');
    }

    /**
     * Convert any form of id (MongoDB ObjectId object, ['$oid'=>...] array,
     * stdClass {$oid:...}, or plain int/string) to a plain string.
     */
    private function normaliseId($raw): string
    {
        if ($raw === null)                                  return '';
        if (is_int($raw))                                   return (string) $raw;
        if (is_string($raw))                                return $raw;
        if ($raw instanceof \MongoDB\BSON\ObjectId)         return (string) $raw;
        if (is_array($raw) && isset($raw['$oid']))          return $raw['$oid'];
        if (is_object($raw)) {
            $arr = json_decode(json_encode($raw), true);
            if (isset($arr['$oid']))                        return $arr['$oid'];
        }
        return (string) $raw;
    }

    /**
     * Validate Bearer token against admin_tokens table.
     * Returns the admin_info row (stdClass) with a normalised string ->id, or null.
     */
    private function authenticate(Request $request)
    {
        $token = $this->extractToken($request);
        if (!$token) return null;

        $tokenRow = DB::table('admin_tokens')->where('token', $token)->first();
        if (!$tokenRow) return null;

        $admin = DB::table('admin_info')->where('id', $tokenRow->admin_id)->first();
        if ($admin) {
            // Always give downstream code a plain string id to compare / log
            $admin->id = $this->normaliseId($admin->id);
        }
        return $admin;
    }

    /** Format a MongoDB question document into a clean array */
    private function formatQuestion($question): array
    {
        $q  = json_decode(json_encode($question), true);
        $id = $q['_id']['$oid'] ?? $q['id']['$oid'] ?? (string)($q['_id'] ?? $q['id'] ?? uniqid());

        return [
            'id'               => $id,
            'question'         => $q['question']         ?? '',
            'question_image'   => $q['question_image']   ?? null,
            'choice_a'         => $q['choice_a']         ?? '',
            'choice_a_image'   => $q['choice_a_image']   ?? null,
            'choice_b'         => $q['choice_b']         ?? '',
            'choice_b_image'   => $q['choice_b_image']   ?? null,
            'choice_c'         => $q['choice_c']         ?? '',
            'choice_c_image'   => $q['choice_c_image']   ?? null,
            'choice_d'         => $q['choice_d']         ?? '',
            'choice_d_image'   => $q['choice_d_image']   ?? null,
            'correct_answer'   => $q['correct_answer']   ?? '',
            'category'         => $q['category']         ?? '',
            'difficulty_level' => $q['difficulty_level'] ?? '',
            'year_level'       => $q['year_level']       ?? '',
            'subcategory'      => $q['subcategory']      ?? null,
            'has_images'       => $q['has_images']       ?? 0,
            'is_active'        => $q['is_active']        ?? 1,
            'date_added'       => $q['date_added']       ?? null,
        ];
    }

    /** Convert a stored image path to a full API URL (routes through /api/ for CORS) */
    /**
     * ✅ FIX: this used to build an absolute URL from config('app.url') with
     * a hardcoded '/api/' prefix — but this app has no '/api/' route prefix
     * anywhere (Flutter calls e.g. '/admin/questions' directly off
     * AppConfig.baseUrl), and APP_URL is a static .env value that won't
     * match whatever host the Flutter app is actually reachable at (a LAN
     * IP during local testing, a different domain in prod, etc.). That
     * mismatch is exactly why images "read" (uploaded fine) but never
     * displayed — the browser tried to load a URL pointing at the wrong
     * host entirely. Returning the bare relative path instead and letting
     * the Flutter side prepend its own dynamically-detected ApiService.baseUrl
     * (which _buildImageCircle in admin_users_admins.dart already does
     * correctly for relative 'uploads/...' paths) fixes this for every
     * environment without needing APP_URL to be right.
     */
    private function imageUrl(?string $path): ?string
    {
        if (!$path) return null;
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }
        return ltrim($path, '/');
    }

    /** Format a MongoDB player document into a clean array */
    private function formatPlayer($player): array
    {
        $p  = json_decode(json_encode($player), true);
        $id = $p['_id']['$oid'] ?? $p['id']['$oid'] ?? (string)($p['_id'] ?? $p['id'] ?? uniqid());

        return [
            'id'               => $id,
            'username'         => $p['username']         ?? '',
            'school'           => $p['school']           ?? '',
            'age'              => $p['age']              ?? '',
            'category'         => $p['category']         ?? '',
            'student_category' => $p['student_category'] ?? null,
            'sex'              => $p['sex']              ?? '',
            'avatar'           => $p['avatar']           ?? '',
            'region'           => $p['region']           ?? null,
            'province'         => $p['province']         ?? null,
            'city'             => $p['city']             ?? null,
            'stars'            => $p['stars']            ?? 0,
            'status'           => $p['status']            ?? 'active',
        ];
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  AUTH
    // ══════════════════════════════════════════════════════════════════════════

    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        // ✅ FIX: TC_ADMIN_LOGIN_010 — admin login had no lockout at all,
        // unlike player login (UserController::login) which already does
        // this correctly. Same pattern: 5 attempts, 5-minute lockout,
        // keyed per-username so it can't be used to lock out someone else.
        $username    = $request->username;
        $attemptKey  = 'admin_login_attempts:' . strtolower($username);
        $lockoutKey  = 'admin_login_lockout:'  . strtolower($username);
        $maxAttempts    = 5;
        $lockoutMinutes = 5;

        if (Cache::has($lockoutKey)) {
            $secondsLeft = Cache::get($lockoutKey) - now()->timestamp;
            $minutesLeft = max(1, (int) ceil($secondsLeft / 60));
            return response()->json([
                'success'      => false,
                'message'      => "Account temporarily locked due to too many failed attempts. Please try again in {$minutesLeft} minute(s).",
                'locked_out'   => true,
                'minutes_left' => $minutesLeft,
            ], 429);
        }

        $admin = DB::table('admin_info')
            ->where('admin_username', $request->username)
            ->first();

        if (!$admin || !Hash::check($request->password, $admin->admin_password_hash)) {
            $attempts  = Cache::get($attemptKey, 0) + 1;
            $remaining = $maxAttempts - $attempts;

            if ($attempts >= $maxAttempts) {
                $unlockAt = now()->addMinutes($lockoutMinutes)->timestamp;
                Cache::put($lockoutKey, $unlockAt, now()->addMinutes($lockoutMinutes));
                Cache::forget($attemptKey);

                return response()->json([
                    'success'      => false,
                    'message'      => "Too many failed attempts. Account locked for {$lockoutMinutes} minutes.",
                    'locked_out'   => true,
                    'minutes_left' => $lockoutMinutes,
                ], 429);
            }

            Cache::put($attemptKey, $attempts, now()->addMinutes($lockoutMinutes));

            return response()->json([
                'success'            => false,
                'message'            => "Invalid username or password. {$remaining} attempt(s) remaining before lockout.",
                'attempts_remaining' => $remaining,
            ], 401);
        }

        // Success — clear any recorded attempts
        Cache::forget($attemptKey);
        Cache::forget($lockoutKey);

        $token   = bin2hex(random_bytes(32));
        $adminId = $this->normaliseId($admin->id);

        // Insert a new token row — supports multiple sessions (different devices)
        DB::table('admin_tokens')->insert([
            'admin_id'   => $adminId,
            'token'      => $token,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Update last_login on admin_info
        DB::table('admin_info')
            ->where('id', $adminId)
            ->update(['last_login' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'token'   => $token,
            'admin'   => [
                'id'       => $adminId,
                'username' => $admin->admin_username,
                'image'    => $this->imageUrl($admin->admin_image ?? null),
                'sex'      => $admin->admin_sex   ?? null,
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $token = $this->extractToken($request);
        if ($token) {
            // Delete only this session's token — other sessions remain active
            DB::table('admin_tokens')->where('token', $token)->delete();
        }
        return response()->json(['success' => true, 'message' => 'Logged out.']);
    }

    public function profile(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        return response()->json([
            'success' => true,
            'admin'   => [
                'id'         => $admin->id, // already normalised by authenticate()
                'username'   => $admin->admin_username,
                'image'      => $this->imageUrl($admin->admin_image ?? null),
                'sex'        => $admin->admin_sex     ?? null,
                'date_added' => $admin->date_added    ?? null,
            ],
        ]);
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  QUESTIONS
    // ══════════════════════════════════════════════════════════════════════════

    public function getQuestions(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $query = DB::connection('mongodb')->table('quiz_questions');

            if ($request->filled('category'))   $query->where('category', ucfirst(strtolower($request->category)));
            if ($request->filled('difficulty'))  $query->where('difficulty_level', ucfirst(strtolower($request->difficulty)));
            if ($request->filled('year_level'))  $query->where('year_level', strtoupper($request->year_level));
            if ($request->filled('status'))      $query->where('is_active', (int) $request->status);

            $all = $query->get()->map(fn($q) => $this->formatQuestion($q));

            if ($request->filled('search')) {
                $search = strtolower($request->search);
                $all = $all->filter(fn($q) => str_contains(strtolower($q['question']), $search));
            }

            $sortCol = $request->get('sort_by', 'id');
            $sortDir = $request->get('sort_dir', 'asc');
            $all = $sortDir === 'desc' ? $all->sortByDesc($sortCol) : $all->sortBy($sortCol);

            $perPage = (int) $request->get('per_page', 10);
            $page    = (int) $request->get('page', 1);
            $total   = $all->count();
            $items   = $all->slice(($page - 1) * $perPage, $perPage)->values();

            return response()->json([
                'success'     => true,
                'total'       => $total,
                'page'        => $page,
                'per_page'    => $perPage,
                'total_pages' => (int) ceil($total / max($perPage, 1)),
                'questions'   => $items,
            ]);

        } catch (\Exception $e) {
            Log::error('Admin getQuestions error', ['msg' => $e->getMessage()]);
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function addQuestion(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $validated = $request->validate([
                'question'         => 'required|string',
                'question_image'   => 'nullable|string',
                'choice_a'         => 'nullable|string',
                'choice_a_image'   => 'nullable|string',
                'choice_b'         => 'nullable|string',
                'choice_b_image'   => 'nullable|string',
                'choice_c'         => 'nullable|string',
                'choice_c_image'   => 'nullable|string',
                'choice_d'         => 'nullable|string',
                'choice_d_image'   => 'nullable|string',
                'correct_answer'   => 'required|string',
                'category'         => 'required|string',
                'difficulty_level' => 'required|string',
                // ✅ FIX: this was 'required|string', but the admin Add
                // Question form has no year_level field at all (only a
                // separate free-text "topic" field) — every submission was
                // guaranteed to fail this validation with "year level field
                // is required", which is why questions couldn't be added.
                // No gameplay path currently filters by year_level either
                // (Whiz Challenge fetches without it), so this is safe to
                // make optional and default to blank ("all year levels").
                'year_level'       => 'nullable|string',
                'topic'            => 'nullable|string',
                'subcategory'      => 'nullable|string',
            ]);

            $validated['year_level'] = $validated['year_level'] ?? '';

            // Each choice needs text OR an image — matches the admin UI's own
            // validation, which lets a picture-only choice through. Was
            // previously enforced as 'required|string' here, which silently
            // rejected picture-only choices that the UI had already accepted.
            foreach (['a', 'b', 'c', 'd'] as $letter) {
                $hasText  = !empty(trim($validated["choice_{$letter}"] ?? ''));
                $hasImage = !empty($validated["choice_{$letter}_image"] ?? '');
                if (!$hasText && !$hasImage) {
                    return response()->json([
                        'success' => false,
                        'message' => "Choice " . strtoupper($letter) . " needs either text or an image.",
                    ], 422);
                }
                // Normalise missing text to '' so downstream code (has_images
                // check, storage) doesn't have to special-case null.
                $validated["choice_{$letter}"] = $validated["choice_{$letter}"] ?? '';
            }

            $hasImages = (!empty($validated['question_image']) ||
                !empty($validated['choice_a_image']) || !empty($validated['choice_b_image']) ||
                !empty($validated['choice_c_image']) || !empty($validated['choice_d_image'])) ? 1 : 0;

            $validated['has_images'] = $hasImages;
            $validated['is_active']  = 1;
            $validated['date_added'] = now()->toISOString();

            $insertedId = DB::connection('mongodb')->table('quiz_questions')->insertGetId($validated);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_ADD_QUESTION,
                targetType:     'question',
                targetId:       (string) $insertedId,
                targetUsername: null,
                changes:        ['before' => ['status' => 'did not exist'], 'after' => [
                    'question'         => $validated['question'],
                    'category'         => $validated['category'],
                    'difficulty_level' => $validated['difficulty_level'],
                    'year_level'       => $validated['year_level'],
                ]],
                details:        ['has_images' => (bool) $hasImages]
            );

            return response()->json(['success' => true, 'message' => 'Question added.', 'id' => (string) $insertedId], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage(), 'errors' => $e->errors()], 422);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function updateQuestion(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            // Fetch before snapshot
            $existing = DB::connection('mongodb')->table('quiz_questions')->where('_id', $id)->first();
            $before   = $existing ? $this->formatQuestion($existing) : [];

            $data = $request->only([
                'question', 'question_image', 'choice_a', 'choice_a_image',
                'choice_b', 'choice_b_image', 'choice_c', 'choice_c_image',
                'choice_d', 'choice_d_image', 'correct_answer', 'category',
                'difficulty_level', 'year_level', 'topic', 'subcategory', 'is_active',
            ]);

            // The question itself needs text OR an image. Fields missing from
            // the request fall back to what is already saved.
            $qText  = array_key_exists('question', $data) ? trim((string) $data['question']) : trim((string) ($before['question'] ?? ''));
            $qImage = array_key_exists('question_image', $data) ? trim((string) $data['question_image']) : trim((string) ($before['question_image'] ?? ''));
            if ($qText === '' && $qImage === '') {
                return response()->json([
                    'success' => false,
                    'message' => 'Question needs either text or an image.',
                ], 422);
            }

            // Same rule as addQuestion(): each choice needs text OR an image.
            // This method previously had no validation at all, so a
            // picture-only choice (or an accidental blank one) could be
            // saved silently on edit even when add correctly rejected it.
            foreach (['a', 'b', 'c', 'd'] as $letter) {
                $hasText  = !empty(trim($data["choice_{$letter}"] ?? ''));
                $hasImage = !empty($data["choice_{$letter}_image"] ?? '');
                if (!$hasText && !$hasImage) {
                    return response()->json([
                        'success' => false,
                        'message' => "Choice " . strtoupper($letter) . " needs either text or an image.",
                    ], 422);
                }
            }

            $data['has_images'] = (!empty($data['question_image']) ||
                !empty($data['choice_a_image']) || !empty($data['choice_b_image']) ||
                !empty($data['choice_c_image']) || !empty($data['choice_d_image'])) ? 1 : 0;

            DB::connection('mongodb')->table('quiz_questions')->where('_id', $id)->update($data);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_UPDATE_QUESTION,
                targetType:     'question',
                targetId:       $id,
                targetUsername: null,
                changes:        AdminAuditLog::diff($before, $data),
                details:        ['question_preview' => substr($before['question'] ?? '', 0, 80)]
            );

            return response()->json(['success' => true, 'message' => 'Question updated.']);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function deleteQuestion(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $existing = DB::connection('mongodb')->table('quiz_questions')->where('_id', $id)->first();
            $preview  = $existing ? (json_decode(json_encode($existing), true)['question'] ?? '') : '';

            DB::connection('mongodb')->table('quiz_questions')->where('_id', $id)->update(['is_active' => 0]);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_DELETE_QUESTION,
                targetType:     'question',
                targetId:       $id,
                targetUsername: null,
                changes:        ['before' => ['is_active' => 1], 'after' => ['is_active' => 0]],
                details:        ['question_preview' => substr($preview, 0, 80)]
            );

            return response()->json(['success' => true, 'message' => 'Question deactivated.']);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function restoreQuestion(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $existing = DB::connection('mongodb')->table('quiz_questions')->where('_id', $id)->first();
            $preview  = $existing ? (json_decode(json_encode($existing), true)['question'] ?? '') : '';

            DB::connection('mongodb')->table('quiz_questions')->where('_id', $id)->update(['is_active' => 1]);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_RESTORE_QUESTION,
                targetType:     'question',
                targetId:       $id,
                targetUsername: null,
                changes:        ['before' => ['is_active' => 0], 'after' => ['is_active' => 1]],
                details:        ['question_preview' => substr($preview, 0, 80)]
            );

            return response()->json(['success' => true, 'message' => 'Question restored.']);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  DIFFICULTY SETTINGS
    // ══════════════════════════════════════════════════════════════════════════

    public function getDifficultySettings(Request $request)
    {
        try {
            $rows   = DB::table('quiz_difficulty_settings')->get();
            $result = [];
            foreach ($rows as $row) {
                $result[$row->difficulty_level] = [
                    'id'            => $row->id,
                    'num_questions' => $row->num_questions,
                    'time_per_qn'   => $row->time_per_qn,
                    // How many active questions exist at this level, so the
                    // admin UI can stop "questions per game" going past it.
                    'available_questions' => $this->countActiveQuestions($row->difficulty_level),
                ];
            }
            return response()->json(['success' => true, 'settings' => $result]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /** Active questions (is_active != 0, missing counts as active) at a difficulty. */
    private function countActiveQuestions(string $level): int
    {
        return (int) DB::connection('mongodb')->table('quiz_questions')
            ->where('difficulty_level', $level)
            ->where('is_active', '!=', 0)
            ->count();
    }

    public function updateDifficultySettings(Request $request, $level)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        $level = ucfirst(strtolower($level));
        if (!in_array($level, ['Easy', 'Average', 'Difficult'])) {
            return response()->json(['success' => false, 'message' => 'Invalid difficulty level.'], 422);
        }

        try {
            $validated = $request->validate([
                'num_questions' => 'required|integer|min:1|max:50',
                'time_per_qn'   => 'required|integer|min:5|max:120',
            ]);

            // Can't ask for more questions per game than actually exist.
            $available = $this->countActiveQuestions($level);
            if ((int) $validated['num_questions'] > $available) {
                $msg = $available === 0
                    ? "There are no active {$level} questions yet. Add questions before setting this."
                    : "Only {$available} active {$level} question" . ($available === 1 ? '' : 's')
                      . " available. Number of Questions cannot be more than {$available}.";
                return response()->json([
                    'success' => false,
                    'message' => $msg,
                    'errors'  => ['num_questions' => [$msg]],
                ], 422);
            }

            // Snapshot before
            $existing = DB::table('quiz_difficulty_settings')->where('difficulty_level', $level)->first();
            $before   = $existing ? [
                'num_questions' => $existing->num_questions,
                'time_per_qn'   => $existing->time_per_qn,
            ] : [];

            DB::table('quiz_difficulty_settings')->where('difficulty_level', $level)->update($validated);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_UPDATE_DIFFICULTY,
                targetType:     'difficulty',
                targetId:       null,
                targetUsername: null,
                changes:        AdminAuditLog::diff($before, $validated),
                details:        ['difficulty_level' => $level]
            );

            return response()->json(['success' => true, 'message' => "$level settings updated."]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage(), 'errors' => $e->errors()], 422);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  PLAYERS
    // ══════════════════════════════════════════════════════════════════════════

    public function getPlayers(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $query = DB::connection('mongodb')->table('player_info');

            // ✅ FIX: "Delete Player" only soft-bans (status → 'banned') so it
            // can be undone via restorePlayer(), but this query never
            // excluded banned players — so after "deleting" someone, the
            // table reload (_refresh()) pulled them right back in, looking
            // like the delete didn't do anything. Default view now excludes
            // banned players; pass ?status=banned to see them (e.g. for a
            // future "view banned players" screen).
            if ($request->filled('status')) {
                $query->where('status', $request->status);
            } else {
                $query->where('status', '!=', 'banned');
            }

            if ($request->filled('category')) $query->where('category', $request->category);
            if ($request->filled('sex'))      $query->where('sex', $request->sex);

            $rawPlayers = $query->get();

            // Resolve location IDs → names.
            // NOTE: matched as strings (not via whereIn + (int) cast) because the
            // id fields in the region/province/city collections aren't guaranteed
            // to be stored as the same BSON type Mongo's whereIn expects — this
            // mirrors UserController::getLocationName(), which already resolves
            // these correctly for the player-side homepage.
            $allRegions   = DB::table('region')->get();
            $allProvinces = DB::table('province')->get();
            $allCities    = DB::table('city')->get();

            $regionMap = [];
            foreach ($allRegions as $r) {
                $regionMap[(string) ($r->id ?? '')] = $r->region_name ?? null;
            }
            $provinceMap = [];
            foreach ($allProvinces as $p) {
                $provinceMap[(string) ($p->id ?? '')] = $p->province_name ?? null;
            }
            // Cities are keyed by province_id + city id together, same as
            // getLocationName()'s city-lookup, since city ids aren't unique
            // across provinces.
            $cityMap = [];
            foreach ($allCities as $c) {
                $cityMap[(string) ($c->province_id ?? '') . '|' . (string) ($c->id ?? '')] = $c->city_name ?? null;
            }

            $all = $rawPlayers->map(function ($p) use ($regionMap, $provinceMap, $cityMap) {
                $formatted = $this->formatPlayer($p);
                $rId = (string) ($formatted['region']   ?? '');
                $pId = (string) ($formatted['province'] ?? '');
                $cId = (string) ($formatted['city']     ?? '');
                $formatted['region_name']   = $rId !== '' && $rId !== '0' ? ($regionMap[$rId] ?? null) : null;
                $formatted['province_name'] = $pId !== '' && $pId !== '0' ? ($provinceMap[$pId] ?? null) : null;
                $formatted['city_name']     = ($pId !== '' && $cId !== '' && $cId !== '0') ? ($cityMap["{$pId}|{$cId}"] ?? null) : null;
                return $formatted;
            });

            if ($request->filled('search')) {
                $search = strtolower($request->search);
                $all = $all->filter(fn($p) =>
                    str_contains(strtolower($p['username']), $search) ||
                    str_contains(strtolower($p['school'] ?? ''), $search)
                );
            }

            $sortCol = $request->get('sort_by', 'username');
            $sortDir = $request->get('sort_dir', 'asc');
            $all = $sortDir === 'desc' ? $all->sortByDesc($sortCol) : $all->sortBy($sortCol);

            $perPage = (int) $request->get('per_page', 10);
            $page    = (int) $request->get('page', 1);
            $total   = $all->count();
            $items   = $all->slice(($page - 1) * $perPage, $perPage)->values();

            return response()->json([
                'success'     => true,
                'total'       => $total,
                'page'        => $page,
                'per_page'    => $perPage,
                'total_pages' => (int) ceil($total / max($perPage, 1)),
                'players'     => $items,
            ]);

        } catch (\Exception $e) {
            Log::error('Admin getPlayers error', ['msg' => $e->getMessage()]);
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  Shared validation — used by addPlayer / updatePlayer / changePlayerPassword
    //  so the rules (and the exact wording of each error) stay identical no
    //  matter which dialog triggered them.
    //
    //  Both trim leading/trailing whitespace automatically instead of
    //  rejecting it — only truly empty/invalid input returns an error.
    //  Each rule is checked separately so the message always names the
    //  SPECIFIC thing that's wrong, not a generic "invalid input".
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * @param string $table  Which collection to check uniqueness against —
     *                        'player_info' (default) or 'admin_info'.
     * @param string $column Which field holds the username in that table —
     *                        'username' for players, 'admin_username' for admins.
     * @return array{value:string}|array{error:string}
     */
    private function validateUsernameInput(
        string $raw,
        ?ObjectId $excludeId = null,
        string $table = 'player_info',
        string $column = 'username'
    ): array {
        $username = trim($raw);

        if ($username === '') {
            return ['error' => 'Username is required.'];
        }
        // ✅ FIX: removed the "must start with a letter" rule (used to be
        // preg_match('/^[A-Za-z]/', ...)). Player-side self-registration
        // never enforced this — only required/non-empty and 3+ chars — so
        // a numeric-only username like "123456" was already a valid player
        // account there. This admin-side check (shared by Add/Edit Player
        // and Add/Edit Admin) was stricter than the player app itself,
        // rejecting usernames the app would otherwise happily create.
        if (!preg_match('/^\S+$/u', $username)) {
            return ['error' => 'Username cannot contain spaces.'];
        }
        if (strlen($username) < 3) {
            return ['error' => 'Username must be at least 3 characters.'];
        }
        if (strlen($username) > 20) {
            return ['error' => 'Username must not exceed 20 characters.'];
        }

        $connection = $table === 'admin_info' ? DB::table($table) : DB::connection('mongodb')->table($table);
        $query = $connection->where($column, $username);
        if ($excludeId) $query->where('_id', '!=', $excludeId);
        if ($query->first()) {
            return ['error' => 'Username is already taken.'];
        }

        return ['value' => $username];
    }

    /**
     * @return array{value:string}|array{error:string}
     */
    private function validatePasswordInput(string $raw, bool $requireSpecial = false): array
    {
        $password = trim($raw);

        if ($password === '') {
            return ['error' => 'Password is required.'];
        }
        if (strlen($password) < 8) {
            return ['error' => 'Password must be at least 8 characters.'];
        }
        if (strlen($password) > 12) {
            return ['error' => 'Password must not exceed 12 characters.'];
        }
        if (!preg_match('/[a-z]/', $password)) {
            return ['error' => 'Password must contain at least one lowercase letter.'];
        }
        if (!preg_match('/[A-Z]/', $password)) {
            return ['error' => 'Password must contain at least one uppercase letter.'];
        }
        if (!preg_match('/\d/', $password)) {
            return ['error' => 'Password must contain at least one number.'];
        }
        // Same special-character set as the player app's own
        // registration / change-password rules (UserController).
        if ($requireSpecial && !preg_match('/[!@#$%^&*(),.?":{}|<>_\-\[\]\/;~`+=]/', $password)) {
            return ['error' => 'Password must contain at least one special character.'];
        }

        return ['value' => $password];
    }

    public function addPlayer(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        // ✅ FIX: username/password now go through the shared helpers above —
        // trims leading/trailing spaces automatically instead of rejecting
        // them, allows hyphens, requires the username to start with a
        // letter, and password is now 8–12 chars with upper+lower+digit
        // (players also need a special character).
        $usernameResult = $this->validateUsernameInput((string) $request->input('username', ''));
        if (isset($usernameResult['error'])) {
            return response()->json(['success' => false, 'message' => $usernameResult['error']], 422);
        }

        $passwordResult = $this->validatePasswordInput((string) $request->input('password', ''), true);
        if (isset($passwordResult['error'])) {
            return response()->json(['success' => false, 'message' => $passwordResult['error']], 422);
        }

        try {
            $validated = $request->validate([
                'school'           => 'required|string|min:2',
                'age'              => 'required|string',
                'avatar'           => 'required|string',
                'category'         => 'required|string|in:Student,Employee,Others',
                'student_category' => 'nullable|string|in:Elementary,Junior High,Senior High,College,Postgraduate',
                // ✅ FIX: "Prefer not to say" was missing here — it's a
                // valid option on the player-facing registration form
                // (see UserController::register/update), so the admin
                // "Add Player" form was rejecting it with a 422 even
                // though the dropdown itself offered it as a choice.
                'sex'              => 'required|in:Male,Female,Prefer not to say',
                'region'           => 'required|integer',
                'province'         => 'required|integer',
                'city'             => 'required|integer',
            ], [
                'school.required'   => 'School is required.',
                'school.min'        => 'School name must be at least 2 characters.',
                'age.required'      => 'Please select an age range.',
                'avatar.required'   => 'Avatar is required.',
                'category.required' => 'Category is required.',
                'sex.required'      => 'Sex is required.',
                'sex.in'            => 'Sex must be Male, Female, or Prefer not to say.',
                'region.required'   => 'Region is required.',
                'region.integer'    => 'Invalid region selected.',
                'province.required' => 'Province is required.',
                'province.integer'  => 'Invalid province selected.',
                'city.required'     => 'City is required.',
                'city.integer'      => 'Invalid city selected.',
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            $errors     = $e->errors();
            $firstError = reset($errors);
            $message    = is_array($firstError) ? $firstError[0] : $firstError;
            return response()->json(['success' => false, 'message' => $message, 'errors' => $errors], 422);
        }

        $validated['username'] = $usernameResult['value'];
        $validated['password'] = $passwordResult['value'];
        $validated['school']   = trim($validated['school']); // leading/trailing spaces accepted silently

        try {
            $insertedId = DB::connection('mongodb')->table('player_info')->insertGetId([
                'username'         => $validated['username'],
                'password'         => Hash::make($validated['password']),
                'school'           => $validated['school'],
                'age'              => $validated['age'],
                'avatar'           => $validated['avatar'],
                'category'         => $validated['category'],
                'student_category' => $validated['student_category'] ?? null,
                'sex'              => $validated['sex'],
                'region'           => (int) $validated['region'],
                'province'         => (int) $validated['province'],
                'city'             => (int) $validated['city'],
                'stars'            => 0,
                'created_at'       => now(),
                'updated_at'       => now(),
            ]);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_ADD_PLAYER,
                targetType:     'player',
                targetId:       (string) $insertedId,
                targetUsername: $validated['username'],
                changes:        ['before' => ['status' => 'did not exist'], 'after' => [
                    'username'         => $validated['username'],
                    'school'           => $validated['school'],
                    'age'              => $validated['age'],
                    'category'         => $validated['category'],
                    'student_category' => $validated['student_category'] ?? null,
                    'sex'              => $validated['sex'],
                    'region'           => (int) $validated['region'],
                    'province'         => (int) $validated['province'],
                    'city'             => (int) $validated['city'],
                ]],
                details: ['avatar' => $validated['avatar']]
            );

            return response()->json(['success' => true, 'message' => 'Player added successfully.'], 201);

        } catch (\Exception $e) {
            Log::error('Admin addPlayer error', ['msg' => $e->getMessage()]);
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function updatePlayer(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $playerObjectId = new ObjectId($id);

            // Snapshot before update
            $existing = DB::connection('mongodb')->table('player_info')->where('_id', $playerObjectId)->first();
            if (!$existing) return response()->json(['success' => false, 'message' => 'Player not found.'], 404);
            $before = $this->formatPlayer($existing);

            // ✅ FIX: now shares validateUsernameInput()/validatePasswordInput()
            // with addPlayer — trims leading/trailing spaces automatically,
            // allows hyphens, requires starting with a letter, still blocks
            // duplicate usernames (excluding this player's own current one).
            if ($request->filled('username')) {
                $usernameResult = $this->validateUsernameInput((string) $request->input('username'), $playerObjectId);
                if (isset($usernameResult['error'])) {
                    return response()->json(['success' => false, 'message' => $usernameResult['error']], 422);
                }
                $request->merge(['username' => $usernameResult['value']]);
            }

            if ($request->filled('password')) {
                $passwordResult = $this->validatePasswordInput((string) $request->input('password'), true);
                if (isset($passwordResult['error'])) {
                    return response()->json(['success' => false, 'message' => $passwordResult['error']], 422);
                }
                $request->merge(['password' => $passwordResult['value']]);
            }

            // ✅ FIX: category/student_category/sex previously went straight
            // from $request->only() into the database with no validation at
            // all — any value the client sent (including a typo or a stale
            // dropdown value) would be saved as-is. Validate the same
            // allow-lists addPlayer() uses, but with "sometimes" since this
            // is a partial update — only fields actually present are checked.
            try {
                $request->validate([
                    'category'         => 'sometimes|string|in:Student,Employee,Others',
                    'student_category' => 'sometimes|nullable|string|in:Elementary,Junior High,Senior High,College,Postgraduate',
                    'sex'              => 'sometimes|in:Male,Female,Prefer not to say',
                ], [
                    'category.in'  => 'Category must be Student, Employee, or Others.',
                    'sex.in'       => 'Sex must be Male, Female, or Prefer not to say.',
                ]);
            } catch (\Illuminate\Validation\ValidationException $e) {
                $errors     = $e->errors();
                $firstError = reset($errors);
                $message    = is_array($firstError) ? $firstError[0] : $firstError;
                return response()->json(['success' => false, 'message' => $message, 'errors' => $errors], 422);
            }

            $data = $request->only([
                'username', 'school', 'age', 'category', 'sex',
                'avatar', 'student_category', 'region', 'province', 'city',
            ]);
            $data = array_filter($data, fn($v) => $v !== null && $v !== '');

            if (isset($data['school'])) {
                $data['school'] = trim($data['school']);
            }

            foreach (['region', 'province', 'city'] as $field) {
                if (isset($data[$field])) $data[$field] = (int) $data[$field];
            }

            if ($request->filled('password')) {
                $data['password'] = Hash::make($request->password);
            }

            $data['updated_at'] = now();

            DB::connection('mongodb')->table('player_info')
                ->where('_id', $playerObjectId)
                ->update($data);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_UPDATE_PLAYER,
                targetType:     'player',
                targetId:       $id,
                targetUsername: $before['username'] ?? null,
                changes:        AdminAuditLog::diff($before, $data),
                details:        ['player_id' => $id]
            );

            return response()->json(['success' => true, 'message' => 'Player updated.']);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function changePlayerPassword(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        $oldPassword = (string) $request->input('old_password', '');
        if (trim($oldPassword) === '') {
            return response()->json(['success' => false, 'message' => 'Current password is required.'], 422);
        }

        // ✅ FIX: shares validatePasswordInput() with addPlayer/updatePlayer —
        // 8–12 chars, upper+lower+digit, leading/trailing spaces trimmed
        // automatically instead of being rejected.
        $newPasswordResult = $this->validatePasswordInput((string) $request->input('new_password', ''), true);
        if (isset($newPasswordResult['error'])) {
            return response()->json(['success' => false, 'message' => $newPasswordResult['error']], 422);
        }
        $newPassword = $newPasswordResult['value'];

        // Confirms new == confirm server-side too (not just in the dialog),
        // if the frontend sends it.
        if ($request->filled('confirm_password')
            && trim((string) $request->input('confirm_password')) !== $newPassword) {
            return response()->json(['success' => false, 'message' => 'New password and confirm password do not match.'], 422);
        }

        try {
            $playerObjectId = new ObjectId($id);
            $existing = DB::connection('mongodb')->table('player_info')->where('_id', $playerObjectId)->first();
            if (!$existing) return response()->json(['success' => false, 'message' => 'Player not found.'], 404);

            if (!Hash::check($oldPassword, $existing->password ?? '')) {
                return response()->json(['success' => false, 'message' => 'Current password is incorrect.'], 400);
            }

            if (Hash::check($newPassword, $existing->password ?? '')) {
                return response()->json(['success' => false, 'message' => 'New password must be different from the current password.'], 400);
            }

            DB::connection('mongodb')->table('player_info')
                ->where('_id', $playerObjectId)
                ->update([
                    'password'   => Hash::make($newPassword),
                    'updated_at' => now(),
                ]);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_UPDATE_PLAYER,
                targetType:     'player',
                targetId:       $id,
                targetUsername: $existing->username ?? 'unknown',
                changes:        ['before' => ['password' => '[hidden]'], 'after' => ['password' => '[hidden — changed]']],
                details:        ['action' => 'password_reset_by_admin']
            );

            return response()->json(['success' => true, 'message' => 'Player password reset successfully.']);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function deletePlayer(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $playerObjectId = new ObjectId($id);

            $existing = DB::connection('mongodb')->table('player_info')->where('_id', $playerObjectId)->first();
            $username = $existing ? ($existing->username ?? 'unknown') : 'unknown';

            if (!$existing) {
                return response()->json(['success' => false, 'message' => 'Player not found.'], 404);
            }

            // Hard delete: remove the player document itself.
            DB::connection('mongodb')->table('player_info')
                ->where('_id', $playerObjectId)
                ->delete();

            // Remove the player's related records too, so no orphaned data is
            // left behind. player_id may be stored as an ObjectId or a string
            // depending on the collection, so both forms are matched.
            foreach (['player_badges', 'player_rewards', 'player_stats', 'player_stars', 'player_feedback'] as $collection) {
                try {
                    DB::connection('mongodb')->table($collection)
                        ->where(function ($q) use ($playerObjectId, $id) {
                            $q->where('player_id', $playerObjectId)
                              ->orWhere('player_id', (string) $id);
                        })
                        ->delete();
                } catch (\Throwable $e) {
                    \Illuminate\Support\Facades\Log::warning("deletePlayer: cleanup failed for {$collection}", ['error' => $e->getMessage()]);
                }
            }

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_DELETE_PLAYER,
                targetType:     'player',
                targetId:       $id,
                targetUsername: $username,
                changes:        ['before' => ['username' => $username, 'status' => 'active'], 'after' => ['status' => 'deleted']],
                details:        ['player_id' => $id, 'deleted_by' => $admin->admin_username]
            );

            return response()->json(['success' => true, 'message' => 'Player deleted.']);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // ── Unban (restore) player ─────────────────────────────────────────────
    public function restorePlayer(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $playerObjectId = new ObjectId($id);

            $existing = DB::connection('mongodb')->table('player_info')->where('_id', $playerObjectId)->first();
            if (!$existing) return response()->json(['success' => false, 'message' => 'Player not found.'], 404);

            DB::connection('mongodb')->table('player_info')
                ->where('_id', $playerObjectId)
                ->update(['status' => 'active', 'updated_at' => now()]);

            AdminAuditLog::record(
                admin: $admin, action: AdminAuditLog::ACTION_UPDATE_PLAYER,
                targetType: 'player', targetId: $id,
                targetUsername: $existing->username ?? 'unknown',
                changes: ['before' => ['status' => 'banned'], 'after' => ['status' => 'active']],
                details: ['restored_by' => $admin->admin_username],
            );

            return response()->json(['success' => true, 'message' => 'Player restored.']);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }
    // ══════════════════════════════════════════════════════════════════════════

    public function awardBadge(Request $request, $playerId)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        $request->validate(['difficulty' => 'required|in:easy,average,difficult']);
        $difficulty = $request->difficulty;

        try {
            $playerObjectId = new ObjectId($playerId);

            // Get player for username in log
            $player   = DB::connection('mongodb')->table('player_info')->where('_id', $playerObjectId)->first();
            $username = $player ? ($player->username ?? 'unknown') : 'unknown';

            // Find rewards eligible to be awarded. ✅ FIX: must require
            // requested === true — the player has to tap "Claim" first.
            // Previously this only excluded claimed rewards, so ANY pending
            // reward could be awarded even if the player never claimed it.
            $unclaimedRewards = DB::connection('mongodb')
                ->table('player_rewards')
                ->where('player_id', $playerObjectId)
                ->where('difficulty', $difficulty)
                ->where('requested', true)
                ->where('claimed', '!=', true)
                ->get();

            if ($unclaimedRewards->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'No claimed rewards pending admin confirmation for this difficulty.',
                ], 404);
            }

            $rewardCount = $unclaimedRewards->count();

            // Mark all as claimed + stamp which admin awarded them
            DB::connection('mongodb')
                ->table('player_rewards')
                ->where('player_id', $playerObjectId)
                ->where('difficulty', $difficulty)
                ->where('requested', true)
                ->where('claimed', '!=', true)
                ->update([
                    'claimed'              => true,
                    'claimed_date'         => now(),
                    'admin_awarded'        => true,
                    'player_notified'      => false, // player app shows a "prize claimed" message, then flips this to true
                    'awarded_date'         => now(),
                    'awarded_by_admin_id'  => $admin->id,
                    'awarded_by_admin_username' => $admin->admin_username,
                    'updated_at'           => now(),
                ]);

            // Update player_badges: increment the official (admin-confirmed)
            // count only.
            //
            // ✅ FIX: this used to also "consume" 3 badges per reward from
            // {$difficulty}_badge_count (max(0, $currentCount - rewardCount*3)).
            // That field is the player's lifetime badge total — it's what
            // BadgeController's calculateProgress() reads for total_earned,
            // and it's exactly what LeaderboardController::getLeaderboard()
            // and getPlayerBadges() sum up to build the leaderboard. Claim
            // eligibility already comes from the player_rewards documents
            // (requested/claimed flags), not from this counter — so nothing
            // relies on it going down. Decrementing it here meant that the
            // moment an admin confirmed a physical prize, the player's
            // leaderboard total silently dropped (often to 0), making
            // players who had clearly earned badges vanish from the
            // rankings. badge_count must stay a monotonically increasing
            // lifetime total; only official_badge tracks admin confirmations.
            $officialField = $difficulty . '_official_badge';

            $playerBadge     = DB::connection('mongodb')->table('player_badges')
                ->where('player_info_id', $playerObjectId)->first();
            $currentOfficial = $playerBadge ? ($playerBadge->$officialField ?? 0) : 0;
            $newOfficial     = $currentOfficial + $rewardCount;

            DB::connection('mongodb')
                ->table('player_badges')
                ->where('player_info_id', $playerObjectId)
                ->update([
                    $officialField => $newOfficial,
                    'updated_at'   => now(),
                ]);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_AWARD_BADGE,
                targetType:     'player',
                targetId:       $playerId,
                targetUsername: $username,
                changes:        [
                    'before' => ['claimed' => false, $officialField => $currentOfficial],
                    'after'  => ['claimed' => true,  $officialField => $newOfficial],
                ],
                details: [
                    'difficulty'      => $difficulty,
                    'rewards_awarded' => $rewardCount,
                ]
            );

            Log::info('Admin awarded badge', [
                'admin'           => $admin->admin_username,
                'player'          => $username,
                'difficulty'      => $difficulty,
                'rewards_awarded' => $rewardCount,
                'new_official'    => $newOfficial,
            ]);

            return response()->json([
                'success' => true,
                'message' => "Reward confirmed! {$difficulty} badge awarded by {$admin->admin_username}.",
                'data'    => [
                    'difficulty'      => $difficulty,
                    'rewards_awarded' => $rewardCount,
                    'official_total'  => $newOfficial,
                    'awarded_by'      => $admin->admin_username,
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('awardBadge error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  ADMINS MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════

    public function getAdmins(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $rows = DB::table('admin_info')->get();

            // ── FIX: use normaliseId() so the id is always a plain hex string ──
            $admins = $rows->map(fn($a) => [
                'id'         => $this->normaliseId($a->id),
                'username'   => $a->admin_username,
                'sex'        => $a->admin_sex    ?? null,
                'avatar'     => $a->admin_avatar ?? $a->avatar ?? null,
                'image'      => $this->imageUrl($a->admin_image ?? null),
                'date_added' => $a->date_added   ?? null,
            ])->values();

            if ($request->filled('search')) {
                $search = strtolower($request->search);
                $admins = $admins->filter(fn($a) =>
                    str_contains(strtolower($a['username']), $search)
                )->values();
            }

            return response()->json(['success' => true, 'admins' => $admins]);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Validates an uploaded/base64 image is an actually-supported format
     * AND under the size limit, before it's written to disk. ✅ FIX: neither
     * addAdmin nor updateAdmin checked format OR size — any file (including
     * non-images, or huge multi-hundred-MB ones) was accepted and saved as-is.
     *
     * @return string|null  An error message if invalid, or null if OK.
     */
    private function validateImageFormat($file, ?string $base64): ?string
    {
        $allowedExt = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        $maxBytes   = 5 * 1024 * 1024; // 5 MB

        if ($file) {
            $ext = strtolower($file->getClientOriginalExtension());
            if (!in_array($ext, $allowedExt, true)) {
                return 'Invalid image format. Allowed: JPG, JPEG, PNG, GIF, WEBP.';
            }
            $mime = $file->getMimeType();
            if (!str_starts_with((string) $mime, 'image/')) {
                return 'Invalid image format. The uploaded file is not an image.';
            }
            if ($file->getSize() > $maxBytes) {
                return 'Image is too large. Maximum size is 5 MB.';
            }
        } elseif ($base64) {
            $data = $base64;
            if (str_contains($data, ',')) {
                // data:image/png;base64,....  — check the declared mime prefix too
                [$meta] = explode(',', $data, 2);
                if (!preg_match('/^data:image\/(jpe?g|png|gif|webp);base64$/i', $meta)) {
                    return 'Invalid image format. Allowed: JPG, JPEG, PNG, GIF, WEBP.';
                }
                $data = explode(',', $data, 2)[1];
            }
            // Reject oversized base64 payloads before even attempting to
            // decode them — base64 is ~33% larger than the raw bytes, so
            // this catches egregiously large uploads cheaply.
            if (strlen($data) > $maxBytes * 1.4) {
                return 'Image is too large. Maximum size is 5 MB.';
            }
            $decoded = base64_decode($data, true);
            if ($decoded === false) {
                return 'Invalid image data.';
            }
            if (strlen($decoded) > $maxBytes) {
                return 'Image is too large. Maximum size is 5 MB.';
            }
            $finfo = new \finfo(FILEINFO_MIME_TYPE);
            $mime  = $finfo->buffer($decoded);
            if (!str_starts_with((string) $mime, 'image/')) {
                return 'Invalid image format. The uploaded file is not an image.';
            }
        }

        return null;
    }

    public function addAdmin(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        // ✅ FIX: username/password now share the same helpers/rules as
        // player management — trims leading/trailing spaces automatically,
        // allows numeric-only usernames, and 8–12 char password with
        // upper+lower+digit+special character.
        // Uniqueness is checked against admin_info, not player_info.
        $usernameResult = $this->validateUsernameInput(
            (string) $request->input('username', ''), null, 'admin_info', 'admin_username'
        );
        if (isset($usernameResult['error'])) {
            return response()->json(['success' => false, 'message' => $usernameResult['error']], 422);
        }

        $passwordResult = $this->validatePasswordInput((string) $request->input('password', ''), true);
        if (isset($passwordResult['error'])) {
            return response()->json(['success' => false, 'message' => $passwordResult['error']], 422);
        }

        try {
            $request->validate([
                'sex' => 'required|in:Male,Female,Prefer not to say',
            ], [
                'sex.required' => 'Sex is required.',
                'sex.in'       => 'Sex must be Male, Female, or Prefer not to say.',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            $errors     = $e->errors();
            $firstError = reset($errors);
            $message    = is_array($firstError) ? $firstError[0] : $firstError;
            return response()->json(['success' => false, 'message' => $message], 422);
        }

        try {
            // ✅ FIX: validate the image format AND size before saving anything.
            $imageError = $this->validateImageFormat(
                $request->hasFile('image') ? $request->file('image') : null,
                $request->filled('image_base64') ? $request->image_base64 : null
            );
            if ($imageError) {
                return response()->json(['success' => false, 'message' => $imageError], 422);
            }

            $username = $usernameResult['value'];
            $password = $passwordResult['value'];

            // ── Handle image upload (multipart) or base64 (Flutter Web) ──────
            $imagePath = null;
            if ($request->hasFile('image')) {
                $file     = $request->file('image');
                $filename = 'admin_' . time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
                $dir      = public_path('uploads/admins');
                if (!is_dir($dir)) mkdir($dir, 0755, true);
                $file->move($dir, $filename);
                $imagePath = 'uploads/admins/' . $filename;
            } elseif ($request->filled('image_base64')) {
                $base64 = $request->image_base64;
                if (str_contains($base64, ',')) $base64 = explode(',', $base64, 2)[1];
                $decoded = base64_decode($base64);
                if ($decoded !== false) {
                    $filename = 'admin_' . time() . '_' . uniqid() . '.jpg';
                    $dir      = public_path('uploads/admins');
                    if (!is_dir($dir)) mkdir($dir, 0755, true);
                    $written  = file_put_contents($dir . '/' . $filename, $decoded);
                    if ($written !== false) {
                        $imagePath = 'uploads/admins/' . $filename;
                    } else {
                        Log::error('Failed to write admin image on addAdmin: ' . $dir . '/' . $filename);
                    }
                }
            }

            DB::table('admin_info')->insert([
                'admin_username'      => $username,
                'admin_password_hash' => Hash::make($password),
                'admin_sex'           => $request->sex,
                'admin_image'         => $imagePath,
                'date_added'          => now()->toDateTimeString(),
            ]);

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_ADD_ADMIN,
                targetType:     'admin',
                targetId:       null,
                targetUsername: $username,
                changes:        ['before' => ['status' => 'did not exist'], 'after' => [
                    'username' => $username,
                    'sex'      => $request->sex,
                ]],
                details: ['created_by' => $admin->admin_username]
            );

            return response()->json(['success' => true, 'message' => 'Admin added.'], 201);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function updateAdmin(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            // ── FIX: convert string id to ObjectId for MongoDB lookup ─────────
            $objectId = new ObjectId($id);
            $target   = DB::table('admin_info')->where('_id', $objectId)->first();
            if (!$target) return response()->json(['success' => false, 'message' => 'Admin not found.'], 404);

            $before = [
                'username' => $target->admin_username,
                'sex'      => $target->admin_sex ?? null,
            ];

            // Sex is required: it must be in the request or already on file.
            // Blocks saving an admin that has no sex set (empty dropdown).
            $sexToSave = trim((string) $request->input('sex', ''));
            if ($sexToSave === '' && trim((string) ($target->admin_sex ?? '')) === '') {
                return response()->json(['success' => false, 'message' => 'Sex is required.'], 422);
            }
            if ($sexToSave !== '' && !in_array($sexToSave, ['Male', 'Female', 'Prefer not to say'], true)) {
                return response()->json(['success' => false, 'message' => 'Sex must be Male, Female, or Prefer not to say.'], 422);
            }

            // ✅ FIX: now shares validateUsernameInput() with player
            // management — trims leading/trailing spaces automatically,
            // allows hyphens, requires starting with a letter, still blocks
            // duplicates (checked against admin_info, excluding this admin).
            if ($request->filled('username')) {
                $usernameResult = $this->validateUsernameInput(
                    (string) $request->input('username'), $objectId, 'admin_info', 'admin_username'
                );
                if (isset($usernameResult['error'])) {
                    return response()->json(['success' => false, 'message' => $usernameResult['error']], 422);
                }
                $request->merge(['username' => $usernameResult['value']]);
            }

            // ✅ FIX: updateAdmin can also change the password (some admin UIs
            // route this through Edit rather than a separate dialog) — same
            // 8–12 char, upper+lower+digit rule as everywhere else.
            if ($request->filled('password')) {
                $passwordResult = $this->validatePasswordInput((string) $request->input('password'), true);
                if (isset($passwordResult['error'])) {
                    return response()->json(['success' => false, 'message' => $passwordResult['error']], 422);
                }
                $request->merge(['password' => $passwordResult['value']]);
            }

            // ✅ FIX: same missing validation as addAdmin() — any file type
            // was accepted and saved without checking it's actually an image,
            // and there was no size limit either.
            $imageError = $this->validateImageFormat(
                $request->hasFile('image') ? $request->file('image') : null,
                $request->filled('image_base64') ? $request->image_base64 : null
            );
            if ($imageError) {
                return response()->json(['success' => false, 'message' => $imageError], 422);
            }

            $data = [];
            if ($request->filled('username')) $data['admin_username'] = $request->username;
            if ($request->filled('sex'))      $data['admin_sex']      = $request->sex;
            if ($request->filled('password')) $data['admin_password_hash'] = Hash::make($request->password);

            // ── Handle real photo upload (multipart) or base64 (Flutter Web) ──
            if ($request->hasFile('image')) {
                $file     = $request->file('image');
                $filename = 'admin_' . $id . '_' . time() . '.' . $file->getClientOriginalExtension();
                $dir      = public_path('uploads/admins');
                if (!is_dir($dir)) mkdir($dir, 0755, true);
                $file->move($dir, $filename);
                $data['admin_image'] = 'uploads/admins/' . $filename;
            } elseif ($request->filled('image_base64')) {
                $base64 = $request->image_base64;
                if (str_contains($base64, ',')) $base64 = explode(',', $base64, 2)[1];
                $decoded = base64_decode($base64);
                if ($decoded !== false) {
                    $filename = 'admin_' . $id . '_' . time() . '.jpg';
                    $dir      = public_path('uploads/admins');
                    if (!is_dir($dir)) mkdir($dir, 0755, true);
                    $written  = file_put_contents($dir . '/' . $filename, $decoded);
                    if ($written !== false) {
                        $data['admin_image'] = 'uploads/admins/' . $filename;
                        Log::info('Admin image saved on update: ' . $dir . '/' . $filename . ' (' . $written . ' bytes)');
                    } else {
                        Log::error('Failed to write admin image on update: ' . $dir . '/' . $filename);
                    }
                }
            }

            if (empty($data)) return response()->json(['success' => false, 'message' => 'Nothing to update.'], 422);

            // ── FIX: use _id + ObjectId for the update query ──────────────────
            DB::table('admin_info')->where('_id', $objectId)->update($data);

            $after = [
                'username' => $request->filled('username') ? $request->username : $target->admin_username,
                'sex'      => $request->filled('sex')      ? $request->sex      : ($target->admin_sex ?? null),
            ];

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_UPDATE_ADMIN,
                targetType:     'admin',
                targetId:       $id,
                targetUsername: $target->admin_username,
                changes:        AdminAuditLog::diff($before, $after),
                details:        ['admin_id' => $id]
            );

            return response()->json([
                'success' => true,
                'message' => 'Admin updated.',
                'admin'   => [
                    'id'       => $id,
                    'username' => $after['username'],
                    'sex'      => $after['sex'],
                    'image'    => isset($data['admin_image']) ? $this->imageUrl($data['admin_image']) : $this->imageUrl($target->admin_image ?? null),
                ],
            ]);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function deleteAdmin(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        // Prevent deleting your own account
        if ((string)$admin->id === (string)$id) {
            return response()->json(['success' => false, 'message' => 'Cannot delete your own account.'], 403);
        }

        try {
            // ── FIX: convert string id to ObjectId for MongoDB lookup ─────────
            $objectId = new ObjectId($id);
            $target   = DB::table('admin_info')->where('_id', $objectId)->first();

            if (!$target) {
                return response()->json(['success' => false, 'message' => 'Admin not found.'], 404);
            }

            $username = $target->admin_username;

            // The superadmin account can never be deleted, no matter who is asking.
            if (strcasecmp($username, self::SUPERADMIN_USERNAME) === 0) {
                return response()->json(['success' => false, 'message' => 'The superadmin account cannot be deleted.'], 403);
            }

            // Delete all active sessions for this admin first
            DB::table('admin_tokens')->where('admin_id', $id)->delete();

            // ── FIX: use _id + ObjectId for the delete query ──────────────────
            $deleted = DB::table('admin_info')->where('_id', $objectId)->delete();

            if ($deleted === 0) {
                return response()->json(['success' => false, 'message' => 'Delete failed — no rows affected.'], 500);
            }

            // ── AUDIT LOG ────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_DELETE_ADMIN,
                targetType:     'admin',
                targetId:       $id,
                targetUsername: $username,
                changes:        ['before' => ['username' => $username, 'status' => 'active'], 'after' => ['status' => 'deleted']],
                details:        ['admin_id' => $id, 'deleted_by' => $admin->admin_username]
            );

            return response()->json(['success' => true, 'message' => 'Admin deleted.', 'deleted_id' => $id]);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function changeAdminPassword(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        $oldPassword = (string) $request->input('old_password', '');
        if (trim($oldPassword) === '') {
            return response()->json(['success' => false, 'message' => 'Current password is required.'], 422);
        }

        // ✅ FIX: shares validatePasswordInput() with player management —
        // 8–12 chars, upper+lower+digit, leading/trailing spaces trimmed
        // automatically instead of being rejected.
        $newPasswordResult = $this->validatePasswordInput((string) $request->input('new_password', ''), true);
        if (isset($newPasswordResult['error'])) {
            return response()->json(['success' => false, 'message' => $newPasswordResult['error']], 422);
        }
        $newPassword = $newPasswordResult['value'];

        if ($request->filled('confirm_password')
            && trim((string) $request->input('confirm_password')) !== $newPassword) {
            return response()->json(['success' => false, 'message' => 'New password and confirm password do not match.'], 422);
        }

        // ── FIX: convert string id to ObjectId for MongoDB lookup ─────────────
        $objectId = new ObjectId($id);
        $target   = DB::table('admin_info')->where('_id', $objectId)->first();
        if (!$target) return response()->json(['success' => false, 'message' => 'Admin not found.'], 404);

        if (!Hash::check($oldPassword, $target->admin_password_hash)) {
            return response()->json(['success' => false, 'message' => 'Current password is incorrect.'], 400);
        }

        // ✅ FIX: nothing stopped the new password from being identical to
        // the current one — TC_ADMIN_CHANGE_PWD_015 expected this rejected.
        if (Hash::check($newPassword, $target->admin_password_hash)) {
            return response()->json(['success' => false, 'message' => 'New password must be different from the current password.'], 400);
        }

        // ── FIX: use _id + ObjectId for the update query ──────────────────────
        DB::table('admin_info')->where('_id', $objectId)->update([
            'admin_password_hash' => Hash::make($newPassword),
        ]);

        // ── AUDIT LOG ────────────────────────────────────────────────────────
        AdminAuditLog::record(
            admin:          $admin,
            action:         AdminAuditLog::ACTION_CHANGE_ADMIN_PW,
            targetType:     'admin',
            targetId:       $id,
            targetUsername: $target->admin_username,
            changes:        ['before' => ['password' => '[hidden]'], 'after' => ['password' => '[hidden — changed]']],
            details:        ['admin_id' => $id, 'changed_by' => $admin->admin_username]
        );

        return response()->json(['success' => true, 'message' => 'Password changed.']);
    }

    public function permanentDeleteQuestion(Request $request, $id)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            // FIX: this was DB::table('questions') — two bugs in one line.
            //  1. DB::table() uses the DEFAULT connection, not 'mongodb', so the
            //     query never reached Mongo at all.
            //  2. The collection is 'quiz_questions', not 'questions'. Every
            //     other method in this controller uses
            //     DB::connection('mongodb')->table('quiz_questions').
            // The result was an exception (or a silent 0 rows), which the app
            // reported as "Question not found" / "Delete failed" every time.
            $collection = DB::connection('mongodb')->table('quiz_questions');

            // Ids come off the wire as plain 24-char hex strings. Match on both
            // the ObjectId and the raw string so documents written either way
            // are still found.
            $objectId = null;
            if (preg_match('/^[a-f0-9]{24}$/i', (string) $id)) {
                try { $objectId = new ObjectId($id); } catch (\Throwable $e) { $objectId = null; }
            }

            $existing = $objectId
                ? $collection->where('_id', $objectId)->first()
                : $collection->where('_id', $id)->first();

            if (!$existing) {
                // Fall back to the string form in case the document was stored
                // with a string _id.
                $existing = DB::connection('mongodb')->table('quiz_questions')->where('_id', (string) $id)->first();
            }

            if (!$existing) {
                return response()->json([
                    'success' => false,
                    'message' => 'Question not found. It may already have been deleted.',
                ], 404);
            }

            $row     = json_decode(json_encode($existing), true);
            $preview = $row['question'] ?? '';

            $deleted = $objectId
                ? DB::connection('mongodb')->table('quiz_questions')->where('_id', $objectId)->delete()
                : DB::connection('mongodb')->table('quiz_questions')->where('_id', (string) $id)->delete();

            if ($deleted === 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'The question was found but could not be removed. Check the database user has delete permission.',
                ], 500);
            }

            // AUDIT LOG — permanent deletes were not being logged at all.
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_DELETE_QUESTION,
                targetType:     'question',
                targetId:       (string) $id,
                targetUsername: null,
                changes:        ['before' => ['status' => 'existed'], 'after' => ['status' => 'permanently deleted']],
                details:        [
                    'permanent'        => true,
                    'question_preview' => substr($preview, 0, 80),
                ]
            );

            return response()->json(['success' => true, 'message' => 'Question permanently deleted.']);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  ANALYTICS
    // ══════════════════════════════════════════════════════════════════════════

    // ══════════════════════════════════════════════════════════════════════════
    //  ANALYTICS HELPERS
    //  Shared by getAnalytics() so player_info and player_stats are always
    //  compared the same way, whatever BSON shape the driver hands back.
    // ══════════════════════════════════════════════════════════════════════════

    /** ObjectId | ['$oid' => '...'] | 'hex string' | null  →  plain hex string */
    private function normaliseAnalyticsId($raw): string
    {
        if ($raw === null) return '';

        // ✅ HARDENED: previously returned early on is_string()/is_array()
        // without ever passing through the lowercase+trim normalisation
        // below, so a value that was even slightly different in casing,
        // whitespace, or wrapper shape from the two sides being compared
        // (player_info._id vs player_stats.player_id / player_badges.
        // player_info_id) would silently fail array_key_exists() even
        // though both "looked like" the same id. Every branch now funnels
        // through one exit point that trims + lowercases, so a mismatch
        // can only happen if the underlying 24-char hex is genuinely
        // different — never because of formatting.
        $out = null;

        if (is_string($raw)) {
            $out = $raw;
        } elseif ($raw instanceof \MongoDB\BSON\ObjectId) {
            $out = (string) $raw;
        } elseif (is_array($raw)) {
            $out = $raw['$oid'] ?? ((string) reset($raw));
        } elseif ($raw instanceof \MongoDB\BSON\Type) {
            // Any other BSON wrapper type (BSONDocument, Decimal128, etc.)
            // — extended-JSON round trip is the reliable way to unwrap it.
            $arr = json_decode(json_encode($raw), true);
            $out = is_array($arr) ? ($arr['$oid'] ?? reset($arr)) : (string) $raw;
        } elseif (is_object($raw)) {
            $arr = json_decode(json_encode($raw), true);
            $out = is_array($arr) ? ($arr['$oid'] ?? null) : null;
        }

        if ($out === null || $out === '') {
            $out = (string) $raw;
        }

        return strtolower(trim((string) $out));
    }

    /** 'Male' | 'male ' | 'M' → 'male';  'Prefer not to say' → 'other' */
    private function normaliseSex($raw): string
    {
        $s = strtolower(trim((string) $raw));
        if ($s === '') return 'other';
        if ($s === 'm' || str_starts_with($s, 'male'))   return 'male';
        if ($s === 'f' || str_starts_with($s, 'female')) return 'female';
        return 'other';
    }

    /**
     * Map a stored age value onto one of the analytics buckets.
     * Accepts the exact bucket string ('13-17') and also a bare number ('14'),
     * which older/imported records sometimes hold.
     */
    private function normaliseAgeRange($raw, array $ranges): ?string
    {
        $a = trim((string) $raw);
        if ($a === '') return null;
        if (in_array($a, $ranges, true)) return $a;

        if (is_numeric($a)) {
            $n = (int) $a;
            if ($n <= 12) return '0-12';
            if ($n <= 17) return '13-17';
            if ($n <= 22) return '18-22';
            if ($n <= 29) return '23-29';
            if ($n <= 39) return '30-39';
            return '40+';
        }
        return null;
    }

    /**
     * Sum a *_stats field, which is {category: {difficulty: count}}.
     * Tolerates arrays, stdClass and BSONDocument, and ignores non-numeric
     * leaves so one odd value can't blow up the whole chart.
     */
    private function sumModeStats($field): int
    {
        if ($field === null) return 0;

        $categories = is_object($field) ? get_object_vars($field) : (array) $field;
        $total = 0;

        foreach ($categories as $catStats) {
            $byDifficulty = is_object($catStats) ? get_object_vars($catStats) : (array) $catStats;
            foreach ($byDifficulty as $count) {
                if (is_numeric($count)) $total += (int) $count;
            }
        }

        return $total;
    }

    public function getAnalytics(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            // ── Total registered players ─────────────────────────────────────
            $totalPlayers = DB::connection('mongodb')->table('player_info')->count();

            // ── Average player rating (avg 1-5 satisfaction rating from the
            //    in-app "Rate Our Game!" dialog, stored in player_feedback) ────
            $feedbackRatingRows = DB::connection('mongodb')->table('player_feedback')->get();
            $avgRating = $feedbackRatingRows->count() > 0
                ? round($feedbackRatingRows->avg('rating'), 1)
                : 0;

            // ── Gender distribution ───────────────────────────────────────────
            $players = DB::connection('mongodb')->table('player_info')->get();

            $male   = $players->where('sex', 'Male')->count();
            $female = $players->where('sex', 'Female')->count();
            $other  = $players->count() - $male - $female;

            $genderDistribution = [
                ['label' => 'Male',   'count' => $male],
                ['label' => 'Female', 'count' => $female],
            ];
            if ($other > 0) {
                $genderDistribution[] = ['label' => 'Other', 'count' => $other];
            }

            // ── Age distribution ──────────────────────────────────────────────
            $ageBuckets = ['0-12' => 0, '13-17' => 0, '18-22' => 0, '23-29' => 0, '30-39' => 0, '40+' => 0];
            foreach ($players as $p) {
                $age = $p->age ?? '';
                if (isset($ageBuckets[$age])) {
                    $ageBuckets[$age]++;
                }
            }
            $ageDistribution = array_map(
                fn($range, $count) => ['range' => $range, 'count' => $count],
                array_keys($ageBuckets),
                array_values($ageBuckets)
            );

            // ── Players by region ─────────────────────────────────────────────
            // FIX: was using whereIn('id', [...int ids]), which doesn't
            // reliably match MongoDB's stored id BSON type — same pitfall
            // documented above in getPlayers(). Fetch all regions and match
            // by string instead, so real names resolve instead of falling
            // back to "Region $id" for every row.
            $allRegionsForAnalytics = DB::table('region')->get();
            $regionNameByStringId = [];
            foreach ($allRegionsForAnalytics as $r) {
                $regionNameByStringId[(string) ($r->id ?? '')] = $r->region_name ?? null;
            }

            $regionCounts = [];
            foreach ($players as $p) {
                $rIdStr = (string) ($p->region ?? '');
                $rName  = $rIdStr !== '' && $rIdStr !== '0'
                    ? ($regionNameByStringId[$rIdStr] ?? "Region $rIdStr")
                    : 'Unknown';
                $regionCounts[$rName] = ($regionCounts[$rName] ?? 0) + 1;
            }
            arsort($regionCounts);
            $playersByRegion = array_map(
                fn($region, $count) => ['region' => $region, 'count' => $count],
                array_keys($regionCounts),
                array_values($regionCounts)
            );

            // ── Gender by game mode — from player_stats ───────────────────────
            // Each *_stats field is {category: {difficulty: count}}; summed
            // across every category + difficulty to get total plays per mode.
            //
            // FIX: the id/sex matching here was strict enough to silently drop
            // real plays. player_stats.player_id and player_info._id can come
            // back as an ObjectId, an extended-JSON ['$oid' => ...] array, or a
            // plain hex string depending on driver/typeMap, and sex could be
            // stored with different casing or padding. Both sides now go
            // through normaliseAnalyticsId()/normaliseSex(), and anything that
            // still fails to match is logged instead of vanishing.
            $allStats = DB::connection('mongodb')->table('player_stats')->get();

            // Build player_id → sex and player_id → age maps (one pass).
            $playerIdToSex = [];
            $pidToAge      = [];
            foreach ($players as $p) {
                // ✅ REAL FIX: this whole time $p->_id was silently null — our
                // Mongo driver/query-builder version hands the primary key
                // back as $p->id, not $p->_id, on plain DB::table() rows
                // (formatPlayer() elsewhere already knew this and checked
                // both keys; this map-building loop never did). That made
                // $playerIdToSex/$pidToAge/$playerObjIdToSex empty on every
                // single request, so every player_stats/player_badges row
                // failed to match regardless of how well player_id/
                // player_info_id were normalised — those were never the
                // problem. Falling back to $p->id fixes it at the source.
                $pid = $this->normaliseAnalyticsId($p->_id ?? $p->id ?? null);
                if ($pid === '') continue;
                $playerIdToSex[$pid] = $p->sex ?? '';
                $pidToAge[$pid]      = trim((string) ($p->age ?? ''));
            }

            $modeFieldMap = [
                'Memory Match' => 'memory_match_stats',
                'Challenge'    => 'challenge_stats',
                'Battle'       => 'battle_stats',
                'Puzzle'       => 'puzzle_stats',
            ];
            $modes = array_keys($modeFieldMap);
            $genderByMode = array_fill_keys($modes, ['male' => 0, 'female' => 0]);

            $unmatchedStats = [];   // stats docs whose player_id matched no player
            $unknownSexPlays = 0;   // plays by players who are neither Male nor Female

            foreach ($allStats as $stat) {
                // ✅ FIX: same json_encode/decode pitfall already fixed for
                // $players above — reading $stat->player_id directly (it's
                // already a MongoDB\BSON\ObjectId) skips the round-trip that
                // silently breaks whenever ANY field on that stats document
                // isn't valid UTF-8, which was making every single row in
                // this loop fail to match (pid always '') and the Male vs
                // Female / game-mode charts always show empty.
                $pid = $this->normaliseAnalyticsId($stat->player_id ?? null);

                // A player_stats row with no matching player_info document is
                // orphaned data (e.g. a stale/removed player_id) rather than
                // an id-matching bug — GameController now rejects unknown
                // player_ids before writing, so this should stay empty for
                // any new plays. Skip it here; there's no player to
                // attribute the play to.
                if ($pid === '' || !array_key_exists($pid, $playerIdToSex)) {
                    $unmatchedStats[] = $pid;
                    continue;
                }

                $sex = $this->normaliseSex($playerIdToSex[$pid]);

                foreach ($modeFieldMap as $modeLabel => $field) {
                    $modeTotal = $this->sumModeStats($stat->$field ?? null);
                    if ($modeTotal === 0) continue;

                    if ($sex === 'male' || $sex === 'female') {
                        $genderByMode[$modeLabel][$sex] += $modeTotal;
                    } else {
                        $unknownSexPlays += $modeTotal;
                    }
                }
            }

            if (!empty($unmatchedStats) || $unknownSexPlays > 0) {
                Log::warning('Admin analytics: some player_stats rows were skipped', [
                    'orphaned_stats_rows'              => count($unmatchedStats),
                    'plays_by_players_with_no_sex_set' => $unknownSexPlays,
                    'hint' => 'Orphaned rows have no matching player_info document (stale player_id) and cannot be attributed to a gender. A player whose sex is "Prefer not to say" also will not appear in a Male vs Female chart.',
                ]);
            }


            $genderByGameMode = array_map(
                fn($mode, $counts) => ['mode' => $mode, 'male' => $counts['male'], 'female' => $counts['female']],
                array_keys($genderByMode),
                array_values($genderByMode)
            );

            // ── Badges by gender and level — from player_badges + player_info ─
            $allBadges = DB::connection('mongodb')->table('player_badges')->get();

            // Build player_info_id → sex map
            $playerObjIdToSex = [];
            foreach ($players as $p) {
                // FIX: same json_encode/decode pitfall as the map built above —
                // read _id directly instead of round-tripping through JSON.
                $pid = $this->normaliseAnalyticsId($p->_id ?? $p->id ?? null);
                $playerObjIdToSex[$pid] = $p->sex ?? 'Other';
            }

            $badgeLevels = ['Easy' => ['male' => 0, 'female' => 0], 'Average' => ['male' => 0, 'female' => 0], 'Difficult' => ['male' => 0, 'female' => 0]];
            foreach ($allBadges as $badge) {
                // ✅ FIX: same pitfall — read player_info_id directly instead
                // of round-tripping through json_encode/decode.
                $pid = $this->normaliseAnalyticsId($badge->player_info_id ?? null);
                $sex = strtolower($playerObjIdToSex[$pid] ?? 'other');

                $easyCount = (int)($badge->easy_badge_count ?? 0);
                $avgCount  = (int)($badge->average_badge_count ?? 0);
                $diffCount = (int)($badge->difficult_badge_count ?? 0);

                if ($sex === 'male') {
                    $badgeLevels['Easy']['male']      += $easyCount;
                    $badgeLevels['Average']['male']   += $avgCount;
                    $badgeLevels['Difficult']['male'] += $diffCount;
                } elseif ($sex === 'female') {
                    $badgeLevels['Easy']['female']      += $easyCount;
                    $badgeLevels['Average']['female']   += $avgCount;
                    $badgeLevels['Difficult']['female'] += $diffCount;
                }
            }

            $badgesByGenderLevel = array_map(
                fn($level, $counts) => ['level' => $level, 'male' => $counts['male'], 'female' => $counts['female']],
                array_keys($badgeLevels),
                array_values($badgeLevels)
            );

            // ── Game mode by age — cross player_info + player_stats ───────────
            // Uses the same normalised id map built above, so a row that counts
            // in the gender chart also counts here.
            $ageRanges = ['0-12', '13-17', '18-22', '23-29', '30-39', '40+'];
            $gameModeByAge = array_fill_keys($ageRanges, [
                'memory_match' => 0, 'challenge' => 0, 'battle' => 0, 'puzzle' => 0,
            ]);

            $ageModeFieldMap = [
                'memory_match' => 'memory_match_stats',
                'challenge'    => 'challenge_stats',
                'battle'       => 'battle_stats',
                'puzzle'       => 'puzzle_stats',
            ];

            $playsWithNoAgeBucket = 0;

            foreach ($allStats as $stat) {
                // ✅ FIX: same pitfall — read player_id directly instead of
                // round-tripping through json_encode/decode.
                $pid = $this->normaliseAnalyticsId($stat->player_id ?? null);
                $age = $this->normaliseAgeRange($pidToAge[$pid] ?? '', $ageRanges);

                foreach ($ageModeFieldMap as $modeKey => $field) {
                    $modeTotal = $this->sumModeStats($stat->$field ?? null);
                    if ($modeTotal === 0) continue;

                    if ($age !== null) {
                        $gameModeByAge[$age][$modeKey] += $modeTotal;
                    } else {
                        $playsWithNoAgeBucket += $modeTotal;
                    }
                }
            }

            if ($playsWithNoAgeBucket > 0) {
                Log::warning('Admin analytics: plays skipped because the player age did not map to a bucket', [
                    'plays'   => $playsWithNoAgeBucket,
                    'buckets' => $ageRanges,
                ]);
            }

            $gameModeByAgeFormatted = array_map(
                fn($range, $counts) => array_merge(['age_range' => $range], $counts),
                array_keys($gameModeByAge),
                array_values($gameModeByAge)
            );

            // ── Player comments (from the in-app rating dialog) ───────────────
            // Only include entries that actually left a comment (rating-only
            // submissions with no text aren't useful to show in this list).
            $feedbackRows = DB::connection('mongodb')
                ->table('player_feedback')
                ->orderBy('created_at', 'desc')
                ->limit(30)
                ->get();

            $playerComments = $feedbackRows
                ->filter(fn($f) => trim($f->comment ?? '') !== '')
                ->map(function ($f) {
                    $createdAt = $f->created_at ?? null;
                    $dateStr = '';
                    if ($createdAt) {
                        try {
                            $dateStr = method_exists($createdAt, 'toDateTime')
                                ? $createdAt->toDateTime()->format('M d, Y')
                                : (string) $createdAt;
                        } catch (\Exception $e) {
                            $dateStr = '';
                        }
                    }
                    return [
                        'player_name' => $f->username ?? 'Player',
                        'comment'     => $f->comment ?? '',
                        'rating'      => (int) ($f->rating ?? 0),
                        'created_at'  => $dateStr,
                    ];
                })
                ->values();

            return response()->json([
                'success' => true,
                'data'    => [
                    'total_players'          => $totalPlayers,
                    'average_rating'         => $avgRating,
                    'gender_distribution'    => $genderDistribution,
                    'age_distribution'       => array_values($ageDistribution),
                    'players_by_region'      => array_values($playersByRegion),
                    'gender_by_game_mode'    => array_values($genderByGameMode),
                    'badges_by_gender_level' => array_values($badgesByGenderLevel),
                    'game_mode_by_age'       => array_values($gameModeByAgeFormatted),
                    'player_comments'        => $playerComments,
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Admin getAnalytics error', ['msg' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  ADMIN LEADERBOARD
    // ══════════════════════════════════════════════════════════════════════════

    public function getChallengeLeaderboard(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $allStats = DB::connection('mongodb')->table('player_stats')->get();

            // Build player_id → player_info map
            // FIX: same json_encode/json_decode round-trip pitfall as
            // getAnalytics() — reading _id/player_id directly (they're already
            // MongoDB\BSON\ObjectId) skips the round-trip that silently broke
            // whenever a document had a non-UTF8-safe field.
            $playerIds = $allStats->map(function ($stat) {
                return (string) ($stat->player_id ?? '');
            })->filter()->unique()->values()->toArray();

            $playerInfoMap = [];
            $players = DB::connection('mongodb')->table('player_info')->get();
            foreach ($players as $p) {
                $pid = (string) ($p->_id ?? $p->id ?? '');
                if ($pid === '') continue;
                $playerInfoMap[$pid] = $p;
            }

            $leaderboard = $allStats->map(function ($stat) use ($playerInfoMap) {
                $pid = (string) ($stat->player_id ?? '');

                $challengeStats = (array)($stat->challenge_stats ?? []);
                $easy = $average = $difficult = 0;
                foreach ($challengeStats as $catStats) {
                    $c = (array)$catStats;
                    $easy      += (int)($c['easy'] ?? 0);
                    $average   += (int)($c['average'] ?? 0);
                    $difficult += (int)($c['difficult'] ?? 0);
                }
                $total = $easy + $average + $difficult;
                if ($total === 0) return null;

                $player = $playerInfoMap[$pid] ?? null;
                return [
                    'player_id'       => $pid,
                    'username'        => $stat->username ?? ($player->username ?? 'Unknown'),
                    'avatar'          => $stat->avatar   ?? ($player->avatar   ?? ''),
                    'easy_badges'     => $easy,
                    'average_badges'  => $average,
                    'difficult_badges'=> $difficult,
                    'total_badges'    => $total,
                ];
            })
            ->filter()
            ->sortByDesc('total_badges')
            ->values()
            ->map(fn($row, $i) => array_merge($row, ['rank' => $i + 1]));

            return response()->json(['success' => true, 'mode' => 'challenge', 'data' => $leaderboard]);

        } catch (\Exception $e) {
            Log::error('getChallengeLeaderboard error', ['msg' => $e->getMessage()]);
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function getBattleLeaderboard(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $allStats = DB::connection('mongodb')->table('player_stats')->get();

            // Build player_info map
            // FIX: same json_encode/json_decode round-trip pitfall as above —
            // read _id/player_id directly instead.
            $players = DB::connection('mongodb')->table('player_info')->get();
            $playerInfoMap = [];
            foreach ($players as $p) {
                $pid = (string) ($p->_id ?? $p->id ?? '');
                if ($pid === '') continue;
                $playerInfoMap[$pid] = $p;
            }

            // For score totals, pull from battle collection
            $battleRecords = DB::connection('mongodb')->table('battle')->get();
            $scoreByPlayer = [];
            $lastPlayedByPlayer = [];
            foreach ($battleRecords as $b) {
                $pid = (string) ($b->player_id ?? '');
                $scoreByPlayer[$pid]    = ($scoreByPlayer[$pid] ?? 0) + (int)($b->player_score ?? 0);
                $lastPlayedByPlayer[$pid] = $b->created_at ?? null;
            }

            $leaderboard = $allStats->map(function ($stat) use ($playerInfoMap, $scoreByPlayer, $lastPlayedByPlayer) {
                $pid = (string) ($stat->player_id ?? '');

                $battleStats = (array)($stat->battle_stats ?? []);
                $easy = $average = $difficult = 0;
                foreach ($battleStats as $catStats) {
                    $c = (array)$catStats;
                    $easy      += (int)($c['easy'] ?? 0);
                    $average   += (int)($c['average'] ?? 0);
                    $difficult += (int)($c['difficult'] ?? 0);
                }

                $totalScore = $scoreByPlayer[$pid] ?? 0;
                $totalWins  = $easy + $average + $difficult;
                if ($totalScore === 0 && $totalWins === 0) return null;

                $player = $playerInfoMap[$pid] ?? null;
                return [
                    'player_id'       => $pid,
                    'username'        => $stat->username ?? ($player->username ?? 'Unknown'),
                    'avatar'          => $stat->avatar   ?? ($player->avatar   ?? ''),
                    'total_score'     => $totalScore,
                    'easy_wins'       => $easy,
                    'average_wins'    => $average,
                    'difficult_wins'  => $difficult,
                    'last_played'     => $lastPlayedByPlayer[$pid] ?? null,
                ];
            })
            ->filter()
            ->sortByDesc('total_score')
            ->values()
            ->map(fn($row, $i) => array_merge($row, ['rank' => $i + 1]));

            return response()->json(['success' => true, 'mode' => 'battle', 'data' => $leaderboard]);

        } catch (\Exception $e) {
            Log::error('getBattleLeaderboard error', ['msg' => $e->getMessage()]);
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  QUESTION CSV IMPORT
    // ══════════════════════════════════════════════════════════════════════════

    public function importQuestions(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $request->validate(['csv_file' => 'required|file|mimes:csv,txt|max:10240']);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['success' => false, 'message' => 'Invalid file. Please upload a CSV file.'], 422);
        }

        try {
            $file    = $request->file('csv_file');
            $handle  = fopen($file->getRealPath(), 'r');
            $headers = fgetcsv($handle); // first row

            if (!$headers) {
                return response()->json(['success' => false, 'message' => 'CSV file is empty or invalid.'], 422);
            }

            // Normalize header names (trim + lowercase)
            $headers = array_map(fn($h) => strtolower(trim($h)), $headers);

            $requiredCols = ['question', 'choice_a', 'choice_b', 'choice_c', 'choice_d', 'correct_answer', 'difficulty_level', 'category', 'year_level'];
            $missingCols  = array_diff($requiredCols, $headers);
            if (!empty($missingCols)) {
                fclose($handle);
                return response()->json([
                    'success' => false,
                    'message' => 'CSV is missing required columns: ' . implode(', ', $missingCols),
                ], 422);
            }

            $imported = 0;
            $errors   = [];
            $rowNum   = 1;

            // Pre-load existing question texts for duplicate check (lowercased)
            $existingTexts = DB::connection('mongodb')
                ->table('quiz_questions')
                ->get()
                ->map(fn($q) => strtolower(trim($q->question ?? '')))
                ->flip()
                ->toArray();

            while (($row = fgetcsv($handle)) !== false) {
                $rowNum++;
                if (count($row) < count($headers)) {
                    $errors[] = ['row' => $rowNum, 'reason' => 'Incomplete row — too few columns'];
                    continue;
                }

                $data = array_combine($headers, array_map('trim', $row));

                // ── Empty cell check ──────────────────────────────────────────
                $emptyFields = [];
                foreach ($requiredCols as $col) {
                    if (!isset($data[$col]) || $data[$col] === '') {
                        $emptyFields[] = $col;
                    }
                }
                if (!empty($emptyFields)) {
                    $errors[] = ['row' => $rowNum, 'reason' => 'Empty required field(s): ' . implode(', ', $emptyFields)];
                    continue;
                }

                // ── Difficulty / category / year_level validation ─────────────
                $difficulty = ucfirst(strtolower($data['difficulty_level']));
                $category   = ucfirst(strtolower($data['category']));
                $yearLevel  = strtoupper($data['year_level']);

                if (!in_array($difficulty, ['Easy', 'Average', 'Difficult'])) {
                    $errors[] = ['row' => $rowNum, 'reason' => "Invalid difficulty_level: '{$data['difficulty_level']}'. Use Easy, Average, or Difficult."];
                    continue;
                }
                if (!in_array($category, ['Math', 'Science'])) {
                    $errors[] = ['row' => $rowNum, 'reason' => "Invalid category: '{$data['category']}'. Use Math or Science."];
                    continue;
                }
                if (!in_array($yearLevel, ['ELEMENTARY', 'JUNIOR', 'SENIOR'])) {
                    $errors[] = ['row' => $rowNum, 'reason' => "Invalid year_level: '{$data['year_level']}'. Use ELEMENTARY, JUNIOR, or SENIOR."];
                    continue;
                }

                // ── Correct answer validation ─────────────────────────────────
                $correctAnswer = strtolower($data['correct_answer']);
                if (!in_array($correctAnswer, ['a', 'b', 'c', 'd'])) {
                    $errors[] = ['row' => $rowNum, 'reason' => "Invalid correct_answer: '{$data['correct_answer']}'. Use A, B, C, or D."];
                    continue;
                }

                // ── Duplicate check ───────────────────────────────────────────
                $questionKey = strtolower($data['question']);
                if (isset($existingTexts[$questionKey])) {
                    $errors[] = ['row' => $rowNum, 'reason' => 'Duplicate question text'];
                    continue;
                }

                // ── Insert ────────────────────────────────────────────────────
                $hasImages = !empty($data['question_image'] ?? '') ||
                             !empty($data['choice_a_image'] ?? '') ||
                             !empty($data['choice_b_image'] ?? '') ||
                             !empty($data['choice_c_image'] ?? '') ||
                             !empty($data['choice_d_image'] ?? '');

                DB::connection('mongodb')->table('quiz_questions')->insert([
                    'question'         => $data['question'],
                    'question_image'   => $data['question_image'] ?? null,
                    'choice_a'         => $data['choice_a'],
                    'choice_a_image'   => $data['choice_a_image'] ?? null,
                    'choice_b'         => $data['choice_b'],
                    'choice_b_image'   => $data['choice_b_image'] ?? null,
                    'choice_c'         => $data['choice_c'],
                    'choice_c_image'   => $data['choice_c_image'] ?? null,
                    'choice_d'         => $data['choice_d'],
                    'choice_d_image'   => $data['choice_d_image'] ?? null,
                    'correct_answer'   => $correctAnswer,
                    'category'         => $category,
                    'difficulty_level' => $difficulty,
                    'year_level'       => $yearLevel,
                    'subcategory'      => $data['subcategory'] ?? null,
                    'has_images'       => $hasImages ? 1 : 0,
                    'is_active'        => 1,
                    'date_added'       => now()->toISOString(),
                    'created_at'       => now(),
                    'updated_at'       => now(),
                ]);

                // Add to local cache to catch duplicates within the same import
                $existingTexts[$questionKey] = true;
                $imported++;
            }

            fclose($handle);

            // ── AUDIT LOG ─────────────────────────────────────────────────────
            AdminAuditLog::record(
                admin:          $admin,
                action:         AdminAuditLog::ACTION_ADD_QUESTION,
                targetType:     'question',
                targetId:       null,
                targetUsername: null,
                changes:        ['before' => [], 'after' => ['imported' => $imported, 'skipped' => count($errors)]],
                details:        ['source' => 'csv_import', 'errors' => $errors]
            );

            return response()->json([
                'success'  => true,
                'imported' => $imported,
                'skipped'  => count($errors),
                'errors'   => $errors,
                'message'  => "Import complete: {$imported} imported, " . count($errors) . ' skipped.',
            ]);

        } catch (\Exception $e) {
            Log::error('importQuestions error', ['msg' => $e->getMessage()]);
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  QUESTION IMAGE UPLOAD
    // ══════════════════════════════════════════════════════════════════════════

    public function uploadQuestionImage(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            // Accept either multipart file OR base64 string (Flutter Web)
            if ($request->hasFile('image')) {
                $request->validate(['image' => 'required|image|mimes:jpg,jpeg,png,gif,webp|max:5120']);
                $file     = $request->file('image');
                $filename = 'qimg_' . time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
                $dir      = public_path('uploads/questions');
                if (!is_dir($dir)) mkdir($dir, 0755, true);
                $file->move($dir, $filename);
                $imagePath = 'uploads/questions/' . $filename;

            } elseif ($request->filled('image_base64')) {
                $base64 = $request->image_base64;
                if (str_contains($base64, ',')) $base64 = explode(',', $base64, 2)[1];
                $decoded = base64_decode($base64);
                if ($decoded === false) {
                    return response()->json(['success' => false, 'message' => 'Invalid base64 image data.'], 422);
                }
                $filename = 'qimg_' . time() . '_' . uniqid() . '.jpg';
                $dir      = public_path('uploads/questions');
                if (!is_dir($dir)) mkdir($dir, 0755, true);
                file_put_contents($dir . '/' . $filename, $decoded);
                $imagePath = 'uploads/questions/' . $filename;

            } else {
                return response()->json(['success' => false, 'message' => 'No image provided. Send image file or image_base64.'], 422);
            }

            return response()->json([
                'success' => true,
                'url'     => $this->imageUrl($imagePath),
                'path'    => $imagePath,
            ]);

        } catch (\Exception $e) {
            Log::error('uploadQuestionImage error', ['msg' => $e->getMessage()]);
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  AUDIT LOG VIEWER
    // ══════════════════════════════════════════════════════════════════════════

    public function getAuditLogs(Request $request)
    {
        $admin = $this->authenticate($request);
        if (!$admin) return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);

        try {
            $query = DB::connection('mongodb')->table('admin_audit_logs');

            if ($request->filled('admin_id'))    $query->where('admin_id', $request->admin_id);
            if ($request->filled('target_type')) $query->where('target_type', $request->target_type);
            if ($request->filled('action'))      $query->where('action', $request->action);

            $perPage = (int) $request->get('per_page', 20);
            $page    = (int) $request->get('page', 1);
            $total   = $query->count();

            $logs = $query->orderBy('created_at', 'desc')
                ->skip(($page - 1) * $perPage)
                ->limit($perPage)
                ->get();

            return response()->json([
                'success'     => true,
                'total'       => $total,
                'page'        => $page,
                'per_page'    => $perPage,
                'total_pages' => (int) ceil($total / max($perPage, 1)),
                'logs'        => $logs,
            ]);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }
}