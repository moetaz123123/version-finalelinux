<?php

namespace App\Http\Controllers;

use App\Helpers\TenantPortHelper;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class TenantPortController extends Controller
{
    /**
     * Récupère le port d'un tenant
     */
    public function getPort(Request $request, $subdomain): JsonResponse
    {
        $port = TenantPortHelper::getPort($subdomain);
        
        if ($port) {
            return response()->json([
                'success' => true,
                'subdomain' => $subdomain,
                'port' => $port,
                'url' => TenantPortHelper::getTenantUrl($subdomain)
            ]);
        }
        
        return response()->json([
            'success' => false,
            'message' => 'Port non trouvé pour ce tenant',
            'subdomain' => $subdomain
        ], 404);
    }

    /**
     * Génère et stocke un nouveau port pour un tenant
     */
    public function generatePort(Request $request, $subdomain): JsonResponse
    {
        try {
            $port = TenantPortHelper::generateAndStorePort($subdomain);
            
            return response()->json([
                'success' => true,
                'subdomain' => $subdomain,
                'port' => $port,
                'url' => TenantPortHelper::getTenantUrl($subdomain)
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération du port: ' . $e->getMessage(),
                'subdomain' => $subdomain
            ], 500);
        }
    }

    /**
     * Supprime le port d'un tenant du cache
     */
    public function removePort(Request $request, $subdomain): JsonResponse
    {
        TenantPortHelper::removePort($subdomain);
        
        return response()->json([
            'success' => true,
            'message' => 'Port supprimé du cache',
            'subdomain' => $subdomain
        ]);
    }

    /**
     * Liste tous les ports en cache
     */
    public function listPorts(): JsonResponse
    {
        // Note: Cette méthode nécessiterait une implémentation plus complexe
        // pour lister tous les ports en cache, car Laravel Cache ne fournit pas
        // de méthode native pour lister toutes les clés
        
        return response()->json([
            'success' => true,
            'message' => 'Fonctionnalité à implémenter',
            'note' => 'Lister tous les ports nécessite une implémentation personnalisée'
        ]);
    }
} 