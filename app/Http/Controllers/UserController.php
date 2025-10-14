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
            'school' => 'required',
            'age' => 'required',
            'avatar' => 'nullable',
            'category' => 'required',
            'sex' => 'required',
            'region' => 'required|integer',
            'province' => 'required|integer',
            'city' => 'required|integer',
        ]);

        $user = User::create([
            'username' => $validated['username'],
            'password' => Hash::make($validated['password']),
            'school' => $validated['school'],
            'age' => $validated['age'],
            'avatar' => $validated['avatar'] ?? null,
            'category' => $validated['category'],
            'sex' => $validated['sex'],
            'region' => (int) $validated['region'],
            'province' => (int) $validated['province'],
            'city' => (int) $validated['city'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Registration successful',
            'user' => $user,
        ], 201);
    }

    /**
     * User login
     */
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('username', $request->username)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        if (!Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid password',
            ], 401);
        }

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'user' => $user,
        ]);
    }

    /**
     * Get user profile by MongoDB _id
     */
    public function profile($id)
    {
        try {
            $user = User::find(new ObjectId($id));
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid user ID format',
            ], 400);
        }

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'user' => $user,
        ]);
    }

    /**
     * Helper: Get location name from collection
     */
    private function getLocationName($collection, $id, $provinceId = null)
    {
        $items = \DB::connection('mongodb')->table($collection)->get();

        if ($collection === 'city' && $provinceId !== null) {
            $item = $items->first(function ($c) use ($id, $provinceId) {
                return (string)($c->id ?? '') === (string)$id
                    && (string)($c->province_id ?? '') === (string)$provinceId;
            });
        } else {
            $item = $items->first(function ($c) use ($id) {
                return (string)($c->id ?? '') === (string)$id;
            });
        }

        return $item ? ($collection === 'region' ? $item->region_name : ($collection === 'province' ? $item->province_name : $item->city_name)) : 'Unknown';
    }

    /**
     * Homepage — returns user with readable region/province/city names
     */
    public function homepage($id)
    {
        try {
            $user = \DB::connection('mongodb')
                ->table('player_info')
                ->where('_id', new \MongoDB\BSON\ObjectId($id))
                ->first();

            if (!$user) {
                return response()->json(['success' => false, 'message' => 'User not found'], 404);
            }

            $regionName = $this->getLocationName('region', $user->region);
            $provinceName = $this->getLocationName('province', $user->province);
            $cityName = $this->getLocationName('city', $user->city, $user->province);

            return response()->json([
                'success' => true,
                'user' => [
                    'username' => $user->username ?? '',
                    'region' => $regionName,
                    'province' => $provinceName,
                    'city' => $cityName,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => 'Error fetching homepage data',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update user by _id (MongoDB) with validation
     */
    public function update(Request $request, $id)
    {
        try {
            $user = User::find(new ObjectId($id));
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => 'Invalid ID format'
            ], 400);
        }

        if (!$user) {
            return response()->json([
                'success' => false,
                'error' => 'User not found'
            ], 404);
        }

        // Validate the incoming request data
        $validated = $request->validate([
            'username' => 'sometimes|string|max:255',
            'school' => 'sometimes|string|max:255',
            'age' => 'sometimes|string',
            'category' => 'sometimes|string|in:Student,Government Employee,Private Employee,Self-Employed,Not Employed,Others',
            'sex' => 'sometimes|string|in:Male,Female',
            'avatar' => 'sometimes|string',
            'region' => 'sometimes|integer',
            'province' => 'sometimes|integer',
            'city' => 'sometimes|integer',
        ]);

        // Ensure integers are properly cast for location fields
        if (isset($validated['region'])) {
            $validated['region'] = (int) $validated['region'];
        }
        if (isset($validated['province'])) {
            $validated['province'] = (int) $validated['province'];
        }
        if (isset($validated['city'])) {
            $validated['city'] = (int) $validated['city'];
        }

        // Update the user with validated data
        $user->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'User updated successfully',
            'user' => $user
        ]);
    }

    /**
     * Fix user location IDs in database
     */
    public function fixUserLocationIds()
    {
        try {
            $users = \DB::connection('mongodb')->table('player_info')->get();
            $fixedUsers = [];

            foreach ($users as $user) {
                // Extract MongoDB _id safely
                $mongoId = isset($user->_id) ? (string)$user->_id : (isset($user->id) ? (string)$user->id : null);
                if (!$mongoId) continue;

                $regionId = $user->region ?? 0;
                $provinceId = $user->province ?? 0;
                $cityId = $user->city ?? 0;

                // Use helper to find names
                $regionName = $this->getLocationName('region', $regionId);
                $provinceName = $this->getLocationName('province', $provinceId);
                $cityName = $this->getLocationName('city', $cityId, $provinceId);

                // Update MongoDB document
                \DB::connection('mongodb')
                    ->table('player_info')
                    ->where('_id', new \MongoDB\BSON\ObjectId($mongoId))
                    ->update([
                        'region' => (int) $regionId,
                        'province' => (int) $provinceId,
                        'city' => (int) $cityId,
                    ]);

                $fixedUsers[] = [
                    'username' => $user->username ?? 'Unknown',
                    'region' => $regionName,
                    'province' => $provinceName,
                    'city' => $cityName,
                ];
            }

            return response()->json([
                'success' => true,
                'message' => 'All user location IDs synced successfully.',
                'fixed_users' => $fixedUsers,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Change user password
     */
    
    public function changePassword(Request $request, $id)
    {
        try {
            $user = User::find(new ObjectId($id));
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid user ID format',
            ], 400);
        }
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        // Validate request
        $validated = $request->validate([
            'old_password' => 'required|string',
            'new_password' => 'required|string|min:6',
            'new_password_confirmation' => 'required|string|same:new_password',
        ]);
        
        // Verify old password
        if (!Hash::check($validated['old_password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current password is incorrect',
            ], 401);
        }

        // Update password
        $user->password = Hash::make($validated['new_password']);
        $user->save();
        
        return response()->json([
            'success' => true,
            'message' => 'Password updated successfully',
        ]);
    }
}