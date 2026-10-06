<?php

namespace App\Http\Controllers;

class CityController extends Controller
{
    public function getByProvince($provinceId)
    {
        // Matched as strings rather than where('province_id', (int) $provinceId) —
        // the stored BSON type of province_id isn't guaranteed to match an int
        // cast, which was silently returning zero rows for valid provinces.
        $cities = \DB::connection('mongodb')
            ->table('city')
            ->get()
            ->filter(fn($city) => (string) ($city->province_id ?? '') === (string) $provinceId)
            ->map(function ($city) {
                return [
                    'id'   => (int) $city->id,
                    'name' => $city->city_name,  // map to 'name'
                ];
            })
            ->values();

        return response()->json($cities);
    }
}