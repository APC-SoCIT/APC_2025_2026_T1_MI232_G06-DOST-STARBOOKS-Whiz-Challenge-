<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminAuth
{
    /** Extract Bearer token from Authorization header or ?token= query param */
    private function extractToken(Request $request): ?string
    {
        $header = $request->header('Authorization', '');
        if (str_starts_with($header, 'Bearer ')) return substr($header, 7);
        return $request->get('token');
    }

    /** Same id-normalising logic as AdminController::normaliseId() */
    private function normaliseId($raw): string
    {
        if ($raw === null)                          return '';
        if (is_int($raw))                            return (string) $raw;
        if (is_string($raw))                          return $raw;
        if ($raw instanceof \MongoDB\BSON\ObjectId)   return (string) $raw;
        if (is_array($raw) && isset($raw['$oid']))    return $raw['$oid'];
        if (is_object($raw)) {
            $arr = json_decode(json_encode($raw), true);
            if (isset($arr['$oid']))                  return $arr['$oid'];
        }
        return (string) $raw;
    }

    public function handle(Request $request, Closure $next)
    {
        $token = $this->extractToken($request);
        if (!$token) {
            return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);
        }

        $tokenRow = DB::table('admin_tokens')->where('token', $token)->first();
        if (!$tokenRow) {
            return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);
        }

        $admin = DB::table('admin_info')->where('id', $tokenRow->admin_id)->first();
        if (!$admin) {
            return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);
        }

        $admin->id = $this->normaliseId($admin->id);

        // Stash the resolved admin on the request so controllers can grab it
        // without re-querying — AdminController's own authenticate() call
        // still works fine too, this is just available if you want it.
        $request->attributes->set('admin', $admin);

        return $next($request);
    }
}