<?php

namespace App\Helpers;

use Illuminate\Support\Facades\Cache;

class TenantPortHelper
{
    /**
     * Récupère le port d'un tenant depuis le cache
     */
    public static function getPort($subdomain)
    {
        return Cache::get("tenant_port_{$subdomain}");
    }

    /**
     * Stocke le port d'un tenant dans le cache
     */
    public static function storePort($subdomain, $port, $hours = 2)
    {
        Cache::put("tenant_port_{$subdomain}", $port, now()->addHours($hours));
    }

    /**
     * Vérifie si un tenant a un port en cache
     */
    public static function hasPort($subdomain)
    {
        return Cache::has("tenant_port_{$subdomain}");
    }

    /**
     * Supprime le port d'un tenant du cache
     */
    public static function removePort($subdomain)
    {
        Cache::forget("tenant_port_{$subdomain}");
    }

    /**
     * Récupère l'URL complète d'un tenant avec son port
     */
    public static function getTenantUrl($subdomain, $protocol = 'http')
    {
        $port = self::getPort($subdomain);
        if ($port) {
            return "{$protocol}://www.{$subdomain}.localhost:{$port}";
        }
        return null;
    }

    /**
     * Génère un port aléatoire libre et le stocke pour un tenant
     */
    public static function generateAndStorePort($subdomain, $min = 1025, $max = 65535, $tries = 20)
    {
        for ($i = 0; $i < $tries; $i++) {
            $port = rand($min, $max);
            $connection = @fsockopen('127.0.0.1', $port);
            if (is_resource($connection)) {
                fclose($connection);
            } else {
                self::storePort($subdomain, $port);
                return $port;
            }
        }
        throw new \Exception("Aucun port libre trouvé après $tries essais");
    }
} 