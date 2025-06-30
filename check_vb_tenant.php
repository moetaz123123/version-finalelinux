<?php

require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\Tenant;
use Illuminate\Support\Facades\DB;

// Vérifier le tenant vb
$tenant = Tenant::where('subdomain', 'vb')->first();

if ($tenant) {
    echo "✅ Tenant 'vb' trouvé:\n";
    echo "- ID: {$tenant->id}\n";
    echo "- Nom: {$tenant->name}\n";
    echo "- Base de données: {$tenant->database}\n";
    echo "- Actif: " . ($tenant->is_active ? 'Oui' : 'Non') . "\n";
    
    // Vérifier la base de données
    $tables = DB::select("SHOW TABLES FROM `{$tenant->database}`");
    echo "\n📋 Tables dans {$tenant->database}:\n";
    if (empty($tables)) {
        echo "❌ Aucune table trouvée - les migrations n'ont pas été exécutées\n";
    } else {
        foreach ($tables as $table) {
            $tableName = array_values((array)$table)[0];
            echo "- $tableName\n";
        }
    }
} else {
    echo "❌ Tenant 'vb' non trouvé dans la base de données principale\n";
} 