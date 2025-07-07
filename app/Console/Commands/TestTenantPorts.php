<?php

namespace App\Console\Commands;

use App\Helpers\TenantPortHelper;
use Illuminate\Console\Command;

class TestTenantPorts extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'tenant:test-ports {subdomain} {--generate : Générer un nouveau port} {--remove : Supprimer le port du cache}';

    /**
     * The console command description.
     */
    protected $description = 'Teste le système de cache des ports pour les tenants';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $subdomain = $this->argument('subdomain');
        $generate = $this->option('generate');
        $remove = $this->option('remove');

        $this->info("=== Test du système de ports pour le tenant: {$subdomain} ===");

        if ($remove) {
            $this->info("Suppression du port du cache...");
            TenantPortHelper::removePort($subdomain);
            $this->info("✅ Port supprimé du cache");
            return;
        }

        if ($generate) {
            $this->info("Génération d'un nouveau port...");
            try {
                $port = TenantPortHelper::generateAndStorePort($subdomain);
                $this->info("✅ Nouveau port généré: {$port}");
                $this->info("URL complète: " . TenantPortHelper::getTenantUrl($subdomain));
            } catch (\Exception $e) {
                $this->error("❌ Erreur: " . $e->getMessage());
            }
            return;
        }

        // Test de récupération du port
        $this->info("Récupération du port depuis le cache...");
        $port = TenantPortHelper::getPort($subdomain);
        
        if ($port) {
            $this->info("✅ Port trouvé: {$port}");
            $this->info("URL complète: " . TenantPortHelper::getTenantUrl($subdomain));
        } else {
            $this->warn("⚠️  Aucun port trouvé pour ce tenant");
            $this->info("Utilisez --generate pour créer un nouveau port");
        }

        // Test de vérification d'existence
        $this->info("Vérification de l'existence du port...");
        if (TenantPortHelper::hasPort($subdomain)) {
            $this->info("✅ Le port existe dans le cache");
        } else {
            $this->warn("⚠️  Le port n'existe pas dans le cache");
        }
    }
} 