<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use MongoDB\BSON\ObjectId;

class UserController extends Controller
{
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
     * Update user by _id (MongoDB)
     */
    public function update(Request $request, $id)
    {
        try {
            $user = User::find(new ObjectId($id));
        } catch (\Exception $e) {
            return response()->json(['error' => 'Invalid ID format'], 400);
        }

        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }

        $user->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'User updated successfully',
            'user' => $user
        ]);
    }

    
    public function fixUserLocationIds()
    {
        try {
            $users = \DB::connection('mongodb')->table('player_info')->get();
            $fixedUsers = [];

            foreach ($users as $user) {
                $mongoId = isset($user->_id) ? (string)$user->_id : (isset($user->id) ? (string)$user->id : null);
                if (!$mongoId) continue;

                $regionId = $user->region ?? 0;
                $provinceId = $user->province ?? 0;
                $cityId = $user->city ?? 0;

                $regionName = $this->getLocationName('region', $regionId);
                $provinceName = $this->getLocationName('province', $provinceId);
                $cityName = $this->getLocationName('city', $cityId, $provinceId);

                \DB::connection('mongodb')
                    ->table('player_info')
                    ->where('_id', new \MongoDB\BSON\ObjectId($mongoId))
                    ->update([
                        'region' => $regionId,
                        'province' => $provinceId,
                        'city' => $cityId,
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

    public function changePassword(Request $request, $id)
    {
        $request->validate([
            'old_password' => 'required',
            'new_password' => 'required|min:6',
            'new_password_confirmation' => 'required|same:new_password',
        ]);

        try {
            $user = User::find(new \MongoDB\BSON\ObjectId($id));
        
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found'
                ], 404);
            }

            if (!Hash::check($request->old_password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Old password is incorrect'
                ], 400);
            }

            $user->password = Hash::make($request->new_password);
            $user->save();

            return response()->json([
                'success' => true,
                'message' => 'Password updated successfully'
            ], 200);
        
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error updating password'
            ], 500);
        }
    }
}
