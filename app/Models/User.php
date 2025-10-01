<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Auth\Authenticatable as AuthenticatableTrait;

class User extends Model implements Authenticatable
{
    use AuthenticatableTrait;

    protected $connection = 'mongodb';
    protected $collection = 'player_info';
    protected $table = 'player_info'; 

    protected $fillable = [
        'username',
        'password',
        'school',
        'age',
        'category',
        'sex',
        'region',
        'province',
        'city',
        'avatar',
    ];

    protected $hidden = [
        'password',
    ];
}
