<?php

namespace App\Http\Controllers;

use App\Models\Tenant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Illuminate\Support\Facades\File;
use App\Models\Project;
use Illuminate\Support\Facades\Log;
use App\Mail\CustomVerifyEmail;
use Illuminate\Support\Facades\Mail;
use Illuminate\Auth\Events\Registered;
use Illuminate\Support\Facades\URL;

class TenantRegistrationController extends Controller
{
    public function showRegistrationForm()
    {
        $projects = Project::all();
        return view('auth.tenant-register', compact('projects'));
    }

    public function showSuccessPage(Request $request)
    {
        // Assurez-vous que les données sont bien passées en session flash
        if (!session('tenant_name') || !session('tenant_base_url') || !session('admin_email')) {
            return redirect()->route('tenant.register');
        }

        return view('auth.tenant-success', [
            'tenant_name' => session('tenant_name'),
            'subdomain' => session('subdomain'),
            'admin_email' => session('admin_email'),
            'path' => session('path'),
            'tenant_base_url' => session('tenant_base_url'),
        ]);
    }

    private function findRandomFreePort($min = 1025, $max = 65535, $tries = 20)
    {
        for ($i = 0; $i < $tries; $i++) {
            $port = rand($min, $max);
            $connection = @fsockopen('127.0.0.1', $port);
            if (is_resource($connection)) {
                fclose($connection);
            } else {
                return $port;
            }
        }
        throw new \Exception("Aucun port libre trouvé après $tries essais");
    }

    /**
     * Récupère le port d'un tenant depuis le cache
     */
    private function getTenantPort($subdomain)
    {
        return Cache::get("tenant_port_{$subdomain}");
    }

    /**
     * Stocke le port d'un tenant dans le cache
     */
    private function storeTenantPort($subdomain, $port)
    {
        Cache::put("tenant_port_{$subdomain}", $port, now()->addHours(2));
    }

    public function register(Request $request)
    {
        $steps = [];

        $validator = Validator::make($request->all(), [
            'company_name' => 'required|string|max:255',
            'subdomain' => 'required|string|max:255|alpha_dash|unique:tenants,subdomain',
            'admin_name' => 'required|string|max:255',
            'admin_email' => 'required|string|email|max:255',
            'admin_password' => ['required', 'confirmed', Password::min(8)],
            'project' => 'required|string',
        ]);

        if ($validator->fails()) {
            return redirect()->route('tenant.register')
                        ->withErrors($validator)
                        ->withInput();
        }

        $validated = $validator->validated();
        $subdomain = $validated['subdomain'];
        $databaseName = 'tenant_' . $subdomain;

        $steps[] = "Création de la base de données <strong>$databaseName</strong>...";

        try {
            // 1. CRÉER LA BASE DE DONNÉES DÉDIÉE
            $exists = DB::select("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = ?", [$databaseName]);
            if ($exists) {
                return redirect()->route('tenant.register')
                    ->withErrors(['subdomain' => 'Ce sous-domaine est déjà utilisé.'])
                    ->withInput();
            }
           
            // Créer la base de données
            DB::statement("CREATE DATABASE `$databaseName` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
           
            // Vérifier que la base a été créée
            $exists = DB::select("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = ?", [$databaseName]);
            if (!$exists) {
                throw new \Exception("La base de données $databaseName n'a pas été créée !");
            }

            $steps[] = "Base de données <strong>$databaseName</strong> créée avec succès.";

            // 2. CRÉER LE TENANT DANS LA BASE PRINCIPALE
            DB::beginTransaction();
            $tenant = Tenant::create([
                'name' => $validated['company_name'],
                'subdomain' => $subdomain,
                'database' => $databaseName,
                'is_active' => true,
            ]);
            DB::commit();

            $steps[] = "Tenant <strong>{$tenant->name}</strong> créé avec succès.";

            // 3. AJOUTER L'ENTRÉE DANS /etc/hosts (Linux)
            $this->addToHostsFile($subdomain);
            $steps[] = "Entrée ajoutée dans /etc/hosts pour <strong>{$subdomain}.localhost</strong>";

            // 4. CRÉER LE DOSSIER DANS /home/subdomain/subdomain.localhost
            $homePath = "/home/{$subdomain}";
            $tenantPath = "{$homePath}/www.{$subdomain}.localhost";
           
            // Créer le dossier utilisateur si il n'existe pas
            if (!file_exists($homePath)) {
                exec("sudo mkdir -p {$homePath}");
                exec("sudo chown www-data:www-data {$homePath}");
                exec("sudo chmod 755 {$homePath}");
            }
           
            // Créer le dossier du tenant
            if (!file_exists($tenantPath)) {
                exec("sudo mkdir -p {$tenantPath}");
                exec("sudo chown www-data:www-data {$tenantPath}");
                exec("sudo chmod 755 {$tenantPath}");
            }

            $steps[] = "Dossier tenant créé : <code>{$tenantPath}</code>";

            // 5. CLONER LE PROJET SÉLECTIONNÉ
            $selectedProjectName = $validated['project'];
            $project = Project::where('name', $selectedProjectName)->first();
            if (!$project) {
                throw new \Exception("Projet non trouvé !");
            }
           
            $repoUrl = $project->repo_url;
            $projectFolder = $project->name;
            $clonePath = $tenantPath . '/' . $projectFolder;

            $steps[] = "Clonage du projet <strong>$projectFolder</strong> depuis <code>$repoUrl</code>...";

            // Cloner le projet
            if (!File::exists($clonePath)) {
                exec("sudo -u www-data git clone $repoUrl $clonePath");
                exec("sudo chown -R www-data:www-data $clonePath");
            }

            $steps[] = "Projet cloné dans <code>$clonePath</code>.";
           // 6. PERSONNALISER LE .ENV DU PROJET CLONÉ 
           $envPath = $clonePath . '/.env';
           $envExamplePath = $clonePath . '/.env.example';
           $mainEnvSource = base_path('.env');

           $steps[] = "Configuration du fichier .env...";

           // Vérifier et créer le fichier .env pour le tenant
           if (file_exists($envExamplePath)) {
               // Copier depuis .env.example
               if (!copy($envExamplePath, $envPath)) {
                   Log::error("Erreur lors de la copie de .env.example");
                   throw new \Exception("Erreur lors de la copie de .env.example");
           }
             } elseif (file_exists($mainEnvSource) && is_readable($mainEnvSource)) {
               // Copier depuis le .env principal
               if (!copy($mainEnvSource, $envPath)) {
                   Log::error("Erreur lors de la copie de .env");
                   throw new \Exception("Erreur lors de la copie de .env");
        }
          } else {
               // Créer un fichier .env basique
               $basicEnvContent = "APP_NAME=Laravel\nAPP_ENV=local\nAPP_KEY=\nAPP_DEBUG=true\nAPP_URL=http://localhost\n\nDB_CONNECTION=mysql\nDB_HOST=127.0.0.1\nDB_PORT=3306\nDB_DATABASE=\nDB_USERNAME=root\nDB_PASSWORD=\n\nCACHE_DRIVER=file\nSESSION_DRIVER=file\nQUEUE_DRIVER=sync\n";
               if (file_put_contents($envPath, $basicEnvContent) === false) {
                   Log::error("Erreur lors de la création du fichier .env");
                   throw new \Exception("Erreur lors de la création du fichier .env");
               }
           }

         // Appliquer les permissions correctes
           chown($envPath, 'www-data');
           chmod($envPath, 0644);

         // Modifier les valeurs du .env
          $port = $this->findRandomFreePort();
           
           // Stocker le port dans le cache pour 2 heures
           Cache::put("tenant_port_{$subdomain}", $port, now()->addHours(2));
           
         $envContent = file_get_contents($envPath);

          // Remplacer les variables de config
         $envContent = preg_replace('/^DB_DATABASE=.*/m', "DB_DATABASE=$databaseName", $envContent);
         $envContent = preg_replace('/^DB_USERNAME=.*/m', "DB_USERNAME=root", $envContent);
         $envContent = preg_replace('/^DB_PASSWORD=.*/m', "DB_PASSWORD=" . config('database.connections.mysql.password'), $envContent);
         $envContent = preg_replace('/^DB_HOST=.*/m', "DB_HOST=127.0.0.1", $envContent);
         $envContent = preg_replace('/^APP_URL=.*/m', "APP_URL=http://{$subdomain}.localhost:$port", $envContent);

           // Sauvegarder le fichier .env modifié
           if (file_put_contents($envPath, $envContent) === false) {
               Log::error("Erreur lors de la sauvegarde du fichier .env");
               throw new \Exception("Erreur lors de la sauvegarde du fichier .env");
           }
           
           // Appliquer les permissions correctes
           chown($envPath, 'www-data');
           chmod($envPath, 0644);

            $steps[] = "Fichier .env configuré avec succès (APP_URL : <code>http://{$subdomain}.localhost:$port</code>)";



            // 7. INSTALLER LES DÉPENDANCES ET LANCER LES MIGRATIONS
            chdir($clonePath);
            set_time_limit(350);

            $steps[] = "Installation des dépendances Composer...";

            // Installer les dépendances
            exec('sudo -u www-data composer install', $output, $returnCode);
            if ($returnCode !== 0) {
                // Affiche le détail de l'erreur pour le debug
                throw new \Exception("Erreur lors de l'installation des dépendances Composer : " . implode("\n", $output));
            }

            $steps[] = "Dépendances installées avec succès.";

            // Générer la clé
            exec('sudo -u www-data php artisan key:generate', $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors de la génération de la clé");
            }

            // Créer le lien de stockage public
            exec('sudo -u www-data php artisan storage:link', $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors de la création du lien de stockage public");
            }
            $steps[] = "Lien de stockage public créé avec succès.";

            // Vider le cache de config
            exec('sudo -u www-data php artisan config:clear', $output, $returnCode);

            $steps[] = "Lancement des migrations et seeders...";

            // Lancer les migrations avec vérification
            exec('sudo -u www-data php artisan migrate --force', $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors de la migration : " . implode("\n", $output));
            }

            // Lancer les seeders
            exec('sudo -u www-data php artisan db:seed --force', $returnCode);

            $steps[] = "Migrations et seeders terminés avec succès.";

            // 8. CONFIGURER LA CONNEXION VERS LA BASE DU TENANT (depuis le projet principal)
            Config::set('database.connections.tenant.database', $databaseName);
            Config::set('database.connections.tenant.username', 'root');
            Config::set('database.connections.tenant.password', config('database.connections.mysql.password'));
            Config::set('database.connections.tenant.host', '127.0.0.1');
            DB::purge('tenant');
            DB::reconnect('tenant');

            // 9. VÉRIFIER QUE LA TABLE USERS EXISTE ET AJOUTER LES COLONNES MANQUANTES
            $maxAttempts = 3;
            $attempt = 0;
            $tableExists = false;

            while ($attempt < $maxAttempts && !$tableExists) {
                try {
                    $tableExists = DB::connection('tenant')->getSchemaBuilder()->hasTable('users');
                    if (!$tableExists) {
                        // Attendre un peu et relancer la migration depuis le projet principal
                        sleep(2);
                        Artisan::call('migrate', [
                            '--database' => 'tenant',
                            '--path' => 'database/migrations',
                            '--force' => true,
                        ]);
                    }
                } catch (\Exception $e) {
                    // Ignorer l'erreur et réessayer
                }
                $attempt++;
            }

            if (!$tableExists) {
                throw new \Exception("La table 'users' n'existe toujours pas après $maxAttempts tentatives de migration");
            }

            // Ajouter les colonnes manquantes si elles n'existent pas
            try {
                $hasTenantId = DB::connection('tenant')->getSchemaBuilder()->hasColumn('users', 'tenant_id');
                if (!$hasTenantId) {
                    DB::connection('tenant')->statement('ALTER TABLE users ADD COLUMN tenant_id BIGINT UNSIGNED NULL');
                }
            } catch (\Exception $e) {
                // Ignorer l'erreur si la colonne existe déjà
            }

            try {
                $hasIsAdmin = DB::connection('tenant')->getSchemaBuilder()->hasColumn('users', 'is_admin');
                if (!$hasIsAdmin) {
                    DB::connection('tenant')->statement('ALTER TABLE users ADD COLUMN is_admin TINYINT(1) NOT NULL DEFAULT 0');
                }
            } catch (\Exception $e) {
                // Ignorer l'erreur si la colonne existe déjà
            }

            // 10. CRÉER L'ADMIN DANS LA BASE DU TENANT
            DB::connection('tenant')->beginTransaction();
            $userId = DB::connection('tenant')->table('users')->insertGetId([
                'name' => $validated['admin_name'],
                'email' => $validated['admin_email'],
                'password' => Hash::make($validated['admin_password']),
                'is_admin' => true,
                'tenant_id' => $tenant->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $user = DB::connection('tenant')->table('users')->where('id', $userId)->first();
            DB::connection('tenant')->commit();

            $steps[] = "Utilisateur administrateur créé : <strong>{$user->email}</strong>";

            // 11. GÉNÉRER LES LIENS ET ENVOYER L'EMAIL
            $domain = config('app.domain', 'localhost');
            $tenantBaseUrl = "http://www.{$subdomain}.{$domain}:$port";
            $loginUrl = "{$tenantBaseUrl}/login";
           
            // Générer l'URL de vérification email (simplifiée)
            try {
            $verificationUrl = URL::temporarySignedRoute(
                'verification.verify',
                now()->addMinutes(60),
                ['id' => $user->id, 'hash' => sha1($user->email)]
            );
            } catch (\Exception $e) {
                // En cas d'erreur, utiliser une URL simple
                $verificationUrl = "{$tenantBaseUrl}/email/verify/{$user->id}/" . sha1($user->email);
            }

            // Envoyer l'email de vérification (désactivé temporairement)
            try {
                Mail::to($user->email)->send(new CustomVerifyEmail(
                    $tenant->name,
                    $user->email,
                    $loginUrl,
                    $verificationUrl,
                    $tenantBaseUrl
                ));
               
                event(new Registered($user));
                $steps[] = "Email de vérification envoyé à <strong>{$user->email}</strong>";
            } catch (\Exception $e) {
                Log::warning("Erreur lors de l'envoi de l'email : " . $e->getMessage());
                $steps[] = "⚠️ Email non envoyé (erreur configuration SMTP)";
            }

            // 12. CONFIGURER Nginx pour le tenant (utilise la config générale)
            $this->startLaravelServer($clonePath, $port);
            $steps[] = "Serveur Nginx configuré pour <strong>{$subdomain}.localhost</strong>";

            // 13. STOCKER EN SESSION POUR LA PAGE DE SUCCÈS
            $path = "/home/{$subdomain}/www.{$subdomain}.localhost/{$projectFolder}";
            session([
                'tenant_name' => $tenant->name,
                'subdomain' => $subdomain,
                'admin_email' => $validated['admin_email'],
                'path' => $path,
                'tenant_base_url' => $tenantBaseUrl,
                'port' => $port,
                'steps' => $steps,
            ]);

        } catch (\Exception $e) {
            if (DB::transactionLevel() > 0) {
                DB::rollBack();
            }
            if (DB::connection('tenant')->transactionLevel() > 0) {
                DB::connection('tenant')->rollBack();
            }
            return redirect()->route('tenant.register')
                ->withErrors(['error' => 'Une erreur est survenue lors de la création de votre espace: ' . $e->getMessage()])
                ->with('steps', $steps)
                ->withInput();
        }

        // 14. REDIRECTION VERS LA PAGE DE SUCCÈS
        return redirect()->route('tenant.register.success')->with([
            'tenant_name' => $tenant->name,
            'subdomain' => $subdomain,
            'tenant_base_url' => $tenantBaseUrl,
            'admin_email' => $user->email,
            'path' => $path,
            'steps' => $steps,
        ]);
    }

    /**
     * Ajoute une entrée dans le fichier /etc/hosts
     */
    private function addToHostsFile($subdomain)
    {
        $hostsFile = '/etc/hosts';
       
        // Vérifier si l'entrée existe déjà
        $hostsContent = file_get_contents($hostsFile);
        $hostEntry = "www.{$subdomain}.localhost";
       
        if (strpos($hostsContent, $hostEntry) === false) {
            // Ajouter l'entrée avec sudo
            exec("echo '127.0.0.1   {$hostEntry}' | sudo tee -a /etc/hosts");
            Log::info("Entrée ajoutée dans /etc/hosts pour {$hostEntry}");
        } else {
            Log::info("L'entrée pour {$hostEntry} existe déjà dans /etc/hosts");
        }
    }

    /**
     * Configure Nginx pour le tenant
     */
    private function startLaravelServer($clonePath, $port)
    {
        // Extraire le subdomain du chemin
        $pathParts = explode('/', $clonePath);
        $subdomain = $pathParts[2]; // /home/subdomain/www.subdomain.localhost/project
       
        // Créer la configuration Nginx automatiquement
        $this->configureNginxForTenant($subdomain, $port, $clonePath);
       
        // Attendre un peu pour que Nginx se recharge
        sleep(3);
       
        Log::info("Nginx configuré pour www.{$subdomain}.localhost:{$port}");
    }

    /**
     * Configure Nginx pour un tenant spécifique
     */
    private function configureNginxForTenant($subdomain, $port, $clonePath)
    {
        try {
            $serverName = "www.{$subdomain}.localhost";
            $documentRoot = "{$clonePath}/public";
            $confFile = "/etc/nginx/sites-available/{$serverName}-{$port}.conf";

            // Vérifier que le dossier public existe
            if (!file_exists($documentRoot)) {
                throw new \Exception("Le dossier public n'existe pas : {$documentRoot}");
            }

            // Créer le contenu du server block Nginx
            $nginxConfig = "
server {
    listen {$port};
    server_name {$serverName};
    root {$documentRoot};
    index index.php index.html index.htm;

    access_log /var/log/nginx/{$serverName}_{$port}_access.log;
    error_log /var/log/nginx/{$serverName}_{$port}_error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}";

            // Écrire le fichier de configuration via un fichier temporaire
            $tempFile = tempnam(sys_get_temp_dir(), 'nginx_');
            if (file_put_contents($tempFile, $nginxConfig) === false) {
                throw new \Exception("Impossible d'écrire le fichier temporaire");
            }
           
            // Copier avec sudo
            $output = [];
            $returnCode = 0;
            exec("sudo cp {$tempFile} {$confFile} 2>&1", $output, $returnCode);
            unlink($tempFile);
            
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors de la copie du fichier de configuration : " . implode("\n", $output));
            }
           
            // Appliquer les permissions correctes
            exec("sudo chown root:root {$confFile} 2>&1", $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors du changement de propriétaire : " . implode("\n", $output));
            }
           
            exec("sudo chmod 644 {$confFile} 2>&1", $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors du changement de permissions : " . implode("\n", $output));
            }
           
            // Activer le site et recharger Nginx
            $siteName = basename($confFile);
            $enabledLink = "/etc/nginx/sites-enabled/{$siteName}";
            
            if (!file_exists($enabledLink)) {
                $output = [];
                $returnCode = 0;
                exec("sudo ln -s {$confFile} {$enabledLink} 2>&1", $output, $returnCode);
                if ($returnCode !== 0) {
                    throw new \Exception("Erreur lors de l'activation du site Nginx : " . implode("\n", $output));
                }
            }

            // Tester la configuration Nginx
            $output = [];
            $returnCode = 0;
            exec("sudo nginx -t 2>&1", $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur dans la configuration Nginx : " . implode("\n", $output));
            }
           
            // Recharger Nginx
            exec("sudo systemctl reload nginx 2>&1", $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors du rechargement de Nginx : " . implode("\n", $output));
            }
           
            Log::info("Server block Nginx créé pour {$serverName}:{$port}");
           
        } catch (\Exception $e) {
            Log::error("Erreur lors de la configuration Nginx : " . $e->getMessage());
            throw new \Exception("Erreur lors de la configuration Nginx : " . $e->getMessage());
        }
    }

    public function success()
    {
        if (!session()->has('tenant_name')) {
            abort(403, 'Accès refusé.');
        }
       
        return view('auth.tenant-success', [
            'tenant_name' => session('tenant_name'),
            'subdomain' => session('subdomain'),
            'admin_email' => session('admin_email'),
            'path' => session('path'),
            'tenant_base_url' => session('tenant_base_url'),
            'steps' => session('steps', []),
        ]);
    }

    /**
     * Récupère le port d'un tenant depuis le cache
     * Méthode publique pour utilisation externe
     */
    public function getTenantPortFromCache($subdomain)
    {
        return Cache::get("tenant_port_{$subdomain}");
    }

    /**
     * Vérifie si un tenant a un port en cache
     */
    public function hasTenantPort($subdomain)
    {
        return Cache::has("tenant_port_{$subdomain}");
    }
}
