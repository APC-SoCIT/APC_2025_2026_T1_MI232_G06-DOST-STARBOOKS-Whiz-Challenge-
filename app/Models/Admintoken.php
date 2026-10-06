<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Represents a row in `admin_tokens` — one active login session for an admin.
 *
 * This is the token itself (used by AdminAuth middleware + AdminController's
 * authenticate() to check "is this Bearer token valid"). It is NOT the
 * action history log — that's AdminAuditLog.php (admin_audit_logs in Mongo),
 * which is separate and untouched.
 */
class AdminToken extends Model
{
    protected $table = 'admin_tokens';

    protected $fillable = ['admin_id', 'token'];

    // Never let the raw token leak out if this model is ever json()'d somewhere.
    protected $hidden = ['token'];

    public $timestamps = true;

    // ── Helpers ──────────────────────────────────────────────────────────────
    // AdminController/AdminAuth currently use raw DB::table('admin_tokens')
    // calls — that still works fine and I left it as-is. These are here if
    // you want to swap to the model later; same behavior either way.

    /** Generate a new token, store it, and return the plaintext string. */
    public static function issue(string $adminId): string
    {
        $token = bin2hex(random_bytes(32));

        self::create([
            'admin_id' => $adminId,
            'token'    => $token,
        ]);

        return $token;
    }

    /** Look up the token row for a raw Bearer token string. */
    public static function findByToken(string $token): ?self
    {
        return self::where('token', $token)->first();
    }

    /** Revoke a single session (used on logout). */
    public static function revoke(string $token): int
    {
        return self::where('token', $token)->delete();
    }

    /** Revoke every session for one admin (used on delete-admin, or a future "log out everywhere"). */
    public static function revokeAllForAdmin(string $adminId): int
    {
        return self::where('admin_id', $adminId)->delete();
    }
}