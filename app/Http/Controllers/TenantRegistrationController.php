<?php

namespace App\Http\Controllers;

use App\Models\Tenant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use App\Mail\CustomVerifyEmail;
use Illuminate\Support\Facades\Mail;
use Illuminate\Auth\Events\Registered;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\File;
use App\Models\Project;
use Illuminate\Support\Facades\Log;

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
        if (!session('tenant_name') || !session('login_url') || !session('admin_email')) {
            return redirect()->route('tenant.register');
        }

        return view('auth.tenant-success', [
            'tenant_name' => session('tenant_name'),
            'subdomain' => session('subdomain'),
            'admin_email' => session('admin_email'),
            'path' => session('path'),
            'login_url' => session('login_url'),
        ]);
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

            // 3. CLONER LE PROJET SÉLECTIONNÉ
            $selectedProjectName = $validated['project'];
            $project = Project::where('name', $selectedProjectName)->first();
            if (!$project) {
                throw new \Exception("Projet non trouvé !");
            }
            
            $repoUrl = $project->repo_url;
            $projectFolder = $project->name;
            $tenantPath = public_path("{$validated['company_name']}/{$subdomain}.localhost");
            $clonePath = $tenantPath . '/' . $projectFolder;

            $steps[] = "Clonage du projet <strong>$projectFolder</strong> depuis <code>$repoUrl</code>...";

            // Créer le dossier et cloner
            if (!File::exists($tenantPath)) {
                File::makeDirectory($tenantPath, 0755, true);
            }
            if (!File::exists($clonePath)) {
                exec("git clone $repoUrl $clonePath");
            }

            $steps[] = "Projet cloné dans <code>$clonePath</code>.";

            // 4. PERSONNALISER LE .ENV DU PROJET CLONÉ
            $envPath = $clonePath . '/.env';
            if (file_exists($clonePath . '/.env.example')) {
                copy($clonePath . '/.env.example', $envPath);
            } elseif (file_exists(base_path('.env'))) {
                copy(base_path('.env'), $envPath);
            } else {
                throw new \Exception("Aucun fichier .env.example ou .env source trouvé !");
            }

            // 1. Trouver un port libre aléatoire
            function findRandomFreePort($min = 1025, $max = 65535, $tries = 20) {
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
            $port = findRandomFreePort(1025, 65535);
            $host = "{$subdomain}.localhost";

            // Modifier le .env AVANT toute commande
            $mainEnv = file_get_contents($envPath);
            $mainEnv = preg_replace('/DB_DATABASE=.*/', "DB_DATABASE=$databaseName", $mainEnv);
            $mainEnv = preg_replace('/DB_USERNAME=.*/', "DB_USERNAME=root", $mainEnv);
            $mainEnv = preg_replace('/DB_PASSWORD=.*/', "DB_PASSWORD=", $mainEnv);
            $mainEnv = preg_replace('/DB_HOST=.*/', "DB_HOST=127.0.0.1", $mainEnv);
            $mainEnv = preg_replace('/APP_URL=.*/', "APP_URL=http://{$host}:{$port}", $mainEnv);
            file_put_contents($envPath, $mainEnv);


            // 5. INSTALLER LES DÉPENDANCES ET LANCER LES MIGRATIONS
            chdir($clonePath);
            set_time_limit(300);

            $steps[] = "Installation des dépendances Composer...";

            // Installer les dépendances
            exec('composer install', $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors de l'installation des dépendances Composer");
            }

            $steps[] = "Dépendances installées.";

            // Générer la clé
            exec('php artisan key:generate', $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors de la génération de la clé");
            }

            // Vider le cache de config
            exec('php artisan config:clear', $output, $returnCode);

            // Lancer les migrations avec vérification
            exec('php artisan migrate --force', $output, $returnCode);
            if ($returnCode !== 0) {
                throw new \Exception("Erreur lors de la migration : " . implode("\n", $output));
            }

            // Lancer les seeders
            exec('php artisan db:seed --force', $returnCode);

            $steps[] = "Lancement des migrations et seeders...";

            // 6. CONFIGURER LA CONNEXION VERS LA BASE DU TENANT (depuis le projet principal)
            Config::set('database.connections.tenant.database', $databaseName);
            Config::set('database.connections.tenant.username', 'root');
            Config::set('database.connections.tenant.password', '');
            Config::set('database.connections.tenant.host', '127.0.0.1');
            DB::purge('tenant');
            DB::reconnect('tenant');

            // 7. VÉRIFIER QUE LA TABLE USERS EXISTE
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

            $steps[] = "Migrations et seeders terminés.";

            // 8. CRÉER L'ADMIN DANS LA BASE DU TENANT
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

            // 9. GÉNÉRER LES LIENS ET ENVOYER L'EMAIL
            $domain = config('app.domain', 'localhost');
            $loginUrl = "http://{$subdomain}.{$domain}:{$port}/login";
            
            $verificationUrl = URL::temporarySignedRoute(
                'verification.verify',
                now()->addMinutes(60),
                ['id' => $user->id, 'hash' => sha1($user->email)]
            );

            Mail::to($user->email)->send(new CustomVerifyEmail(
                $tenant->name,
                $user->email,
                $loginUrl,
                $verificationUrl
            ));

            event(new Registered($user));

            // 2. Lancer le serveur Laravel en arrière-plan (Windows)
            $command = "start /MIN cmd /C \"cd /d {$clonePath} && php artisan serve --host={$host} --port={$port}\"";
            pclose(popen($command, "r"));
            // 10. STOCKER EN SESSION POUR LA PAGE DE SUCCÈS
            $path = "/public/{$validated['company_name']}/{$subdomain}.localhost/{$projectFolder}";
            session([
                'tenant_name' => $tenant->name,
                'subdomain' => $subdomain,
                'admin_email' => $validated['admin_email'],
                'path' => $path,
                'login_url' => $loginUrl,
                'port' => $port,
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

        // 11. REDIRECTION VERS LA PAGE DE SUCCÈS
        return redirect()->route('tenant.register.success')->with([
            'tenant_name' => $tenant->name,
            'login_url' => $loginUrl,
            'admin_email' => $user->email,
            'steps' => $steps,
        ]);
    }

    public function success()
    {
        if (!session()->has('company_name')) {
            abort(403, 'Accès refusé.');
        }
        return view('auth.tenant-success', [
            'company_name' => session('company_name'),
            'subdomain' => session('subdomain'),
            'admin_email' => session('admin_email'),
            'path' => session('path'),
            'login_url' => route('login'),
        ]);
    }
}
