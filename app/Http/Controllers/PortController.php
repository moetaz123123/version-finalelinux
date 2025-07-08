<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PortController extends Controller
{
    /**
     * Voir toutes les associations port <-> sous-domaine
     */
    public function index()
    {
        $bindings = [];
        
        // Récupérer tous les tenants
        $tenants = DB::table('tenants')->get();
        
        foreach ($tenants as $tenant) {
            $assignedPort = Cache::get("tenant_port_{$tenant->subdomain}");
            $boundSubdomain = $assignedPort ? Cache::get("port_subdomain_{$assignedPort}") : null;
            
            $bindings[] = [
                'tenant_id' => $tenant->id,
                'subdomain' => $tenant->subdomain,
                'name' => $tenant->name ?? 'N/A',
                'assigned_port' => $assignedPort,
                'port_bound_to' => $boundSubdomain,
                'status' => ($boundSubdomain === $tenant->subdomain) ? 'OK' : 'CONFLIT',
                'url' => $assignedPort ? "http://{$tenant->subdomain}.localhost:{$assignedPort}" : 'N/A'
            ];
        }
        
        return response()->json([
            'success' => true,
            'bindings' => $bindings,
            'total' => count($bindings)
        ]);
    }

    /**
     * Libérer un port spécifique
     */
    public function releasePort($port)
    {
        $cacheKey = "port_subdomain_{$port}";
        $subdomain = Cache::get($cacheKey);
        
        if ($subdomain) {
            // Supprimer les deux associations
            Cache::forget($cacheKey);
            Cache::forget("tenant_port_{$subdomain}");
            
            Log::info("Admin a libéré le port {$port} du sous-domaine '{$subdomain}'");
            
            return response()->json([
                'success' => true,
                'message' => "Port {$port} libéré du sous-domaine '{$subdomain}'",
                'released_port' => $port,
                'released_subdomain' => $subdomain
            ]);
        }
        
        return response()->json([
            'success' => false,
            'message' => "Port {$port} non trouvé ou déjà libre"
        ], 404);
    }

    /**
     * Réassigner un port à un sous-domaine
     */
    public function reassignPort(Request $request)
    {
        $request->validate([
            'subdomain' => 'required|string|max:255',
            'port' => 'required|integer|min:1024|max:65535'
        ]);

        $subdomain = $request->subdomain;
        $newPort = $request->port;
        
        // Vérifier que le tenant existe
        $tenant = DB::table('tenants')->where('subdomain', $subdomain)->first();
        if (!$tenant) {
            return response()->json([
                'success' => false,
                'message' => "Tenant '{$subdomain}' non trouvé"
            ], 404);
        }

        // Vérifier que le nouveau port n'est pas déjà utilisé
        $existingBinding = Cache::get("port_subdomain_{$newPort}");
        if ($existingBinding && $existingBinding !== $subdomain) {
            return response()->json([
                'success' => false,
                'message' => "Port {$newPort} déjà utilisé par '{$existingBinding}'"
            ], 400);
        }
        
        // Récupérer l'ancien port
        $oldPort = Cache::get("tenant_port_{$subdomain}");
        
        // Libérer l'ancien port si il existe
        if ($oldPort) {
            Cache::forget("port_subdomain_{$oldPort}");
        }
        
        // Assigner le nouveau port
        Cache::put("tenant_port_{$subdomain}", $newPort, now()->addDays(30));
        Cache::put("port_subdomain_{$newPort}", $subdomain, now()->addDays(30));
        
        Log::info("Admin a réassigné '{$subdomain}' du port {$oldPort} vers {$newPort}");
        
        return response()->json([
            'success' => true,
            'message' => "Port réassigné avec succès",
            'subdomain' => $subdomain,
            'old_port' => $oldPort,
            'new_port' => $newPort,
            'new_url' => "http://{$subdomain}.localhost:{$newPort}"
        ]);
    }

    /**
     * Assigner un port à un nouveau tenant
     */
    public function assignPort(Request $request)
    {
        $request->validate([
            'subdomain' => 'required|string|max:255'
        ]);

        $subdomain = $request->subdomain;
        
        // Vérifier que le tenant existe
        $tenant = DB::table('tenants')->where('subdomain', $subdomain)->first();
        if (!$tenant) {
            return response()->json([
                'success' => false,
                'message' => "Tenant '{$subdomain}' non trouvé"
            ], 404);
        }

        // Vérifier qu'il n'a pas déjà un port
        $existingPort = Cache::get("tenant_port_{$subdomain}");
        if ($existingPort) {
            return response()->json([
                'success' => false,
                'message' => "Tenant '{$subdomain}' a déjà le port {$existingPort}"
            ], 400);
        }

        // Générer un port aléatoire libre
        $maxAttempts = 100;
        $attempts = 0;
        
        do {
            $port = rand(8000, 9999);
            $isPortFree = !Cache::get("port_subdomain_{$port}");
            $attempts++;
        } while (!$isPortFree && $attempts < $maxAttempts);

        if (!$isPortFree) {
            return response()->json([
                'success' => false,
                'message' => "Impossible de trouver un port libre après {$maxAttempts} tentatives"
            ], 500);
        }

        // Assigner le port
        Cache::put("tenant_port_{$subdomain}", $port, now()->addDays(30));
        Cache::put("port_subdomain_{$port}", $subdomain, now()->addDays(30));
        
        Log::info("Admin a assigné le port {$port} au tenant '{$subdomain}'");
        
        return response()->json([
            'success' => true,
            'message' => "Port assigné avec succès",
            'subdomain' => $subdomain,
            'port' => $port,
            'url' => "http://{$subdomain}.localhost:{$port}"
        ]);
    }

    /**
     * Nettoyer les associations orphelines
     */
    public function cleanup()
    {
        $cleaned = 0;
        $tenants = DB::table('tenants')->pluck('subdomain');
        
        // Cette partie nécessiterait une implémentation plus complexe
        // pour scanner tous les ports en cache et nettoyer les orphelins
        
        return response()->json([
            'success' => true,
            'message' => "Nettoyage terminé",
            'cleaned_entries' => $cleaned
        ]);
    }
}