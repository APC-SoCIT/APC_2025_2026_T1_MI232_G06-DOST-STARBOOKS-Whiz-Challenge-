<?php

namespace App\Http\Controllers;

class ProvinceController extends Controller
{
    public function getByRegion($regionId)
    {
        // Matched as strings rather than where('region_id', (int) $regionId) —
        // the stored BSON type of region_id isn't guaranteed to match an int
        // cast, which was silently returning zero rows for valid regions.
        $provinces = \DB::connection('mongodb')
            ->table('province')
            ->get()
            ->filter(fn($province) => (string) ($province->region_id ?? '') === (string) $regionId)
            ->map(function ($province) {
                return [
                    'id'   => (int) $province->id,
                    'name' => $province->province_name,  // map to 'name'
                ];
            })
            ->values();

        return response()->json($provinces);
    }
}