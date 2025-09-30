<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;
use App\Http\Controllers\RegionController;
use App\Http\Controllers\ProvinceController;
use App\Http\Controllers\CityController;


// Auth & User
Route::post('/register', [UserController::class, 'register']);
Route::post('/login', [UserController::class, 'login']);
Route::get('/profile/{id}', [UserController::class, 'profile']);

// Regions / Provinces / Cities
Route::get('/region', [RegionController::class, 'index']);
Route::get('/province/{regionId}', [ProvinceController::class, 'getByRegion']);
Route::get('/city/{provinceId}', [CityController::class, 'getByProvince']);