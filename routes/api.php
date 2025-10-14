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
Route::get('/user/profile/{id}', [UserController::class, 'profile']);
Route::put('/user/update/{id}', [UserController::class, 'update']);
Route::get('/homepage/{id}', [UserController::class, 'homepage']);
Route::get('/fix-user-locations', [UserController::class, 'fixUserLocationIds']);
Route::put('/user/change-password/{id}', [UserController::class, 'changePassword']);

// Regions / Provinces / Cities
Route::get('/region', [RegionController::class, 'index']);
Route::get('/province/{regionId}', [ProvinceController::class, 'getByRegion']);
Route::get('/city/{provinceId}', [CityController::class, 'getByProvince']);