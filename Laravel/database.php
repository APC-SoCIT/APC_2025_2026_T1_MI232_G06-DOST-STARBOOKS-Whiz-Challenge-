'mongodb' => [
            'driver' => 'mongodb',
            'host' => env('DB_HOST', 'mongodb'),
            'port' => env('DB_PORT', 27017),
            'database' => env('DB_DATABASE', 'starbooksWhizbee'),
            'username' => env('DB_USERNAME'),
            'password' => env('DB_PASSWORD'),
            'options' => [
            'database' => env('DB_AUTHENTICATION_DATABASE', 'admin'),
],

# Old/Laragon setup
'mongodb' => [
            'driver' => 'mongodb',
            'dsn' => env('MONGODB_URI', 'mongodb://localhost:27017'),
            'database' => 'starbooksWhizbee',
],