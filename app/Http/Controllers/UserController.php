<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use MongoDB\BSON\ObjectId;

class UserController extends Controller
{
    /**
     * Register new user
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'username' => 'required|unique:player_info,username',
            'password' => 'required|min:6',
            'school'   => 'required',
            'age'      => 'required|integer',
            'avatar'   => 'nullable',
            'category' => 'required',
            'sex'      => 'required',
            'region'   => 'required|integer',   // must be Int32
            'province' => 'required|integer',   // must be Int32
            'city'     => 'required|integer',   // must be Int32
        ]);

        $user = User::create([
            'username' => $validated['username'],
            'password' => Hash::make($validated['password']),
            'school'   => $validated['school'],
            'age'      => (int) $validated['age'],
            'avatar'   => $validated['avatar'] ?? null,
            'category' => $validated['category'],
            'sex'      => $validated['sex'],
            'region'   => (int) $validated['region'],    // Int32 foreign key
            'province' => (int) $validated['province'],  // Int32 foreign key
            'city'     => (int) $validated['city'],      // Int32 foreign key
        ]);

        return response()->json([
            'success' => true,
            'user' => $user,
        ], 201);
    }

    /**
     * User login
     */
    public function login(Request $request)
    {
        $credentials = $request->only('username', 'password');

        $user = User::where('username', $credentials['username'])->first();

        if (!$user || !Hash::check($credentials['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid username or password'
            ], 401);
        }

        return response()->json([
            'success' => true,
            'user' => $user,
        ]);
    }

    /**
     * Get user profile (using Mongo _id)
     */
    public function profile($id)
    {
        try {
            $user = User::find(new ObjectId($id));
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid user ID format'
            ], 400);
        }

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'user' => $user,
        ]);
    }
}
