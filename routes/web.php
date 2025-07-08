<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\RegisterController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\TenantRegistrationController;
use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Http\Request;
use App\Http\Controllers\Admin\PortController;
// Route d'accueil
Route::get('/', function () {
    return view('welcome');
})->name('home');

// Routes d'inscription du locataire
Route::get('/register/tenant', [TenantRegistrationController::class, 'showRegistrationForm'])->name('tenant.register');
Route::post('/register/tenant', [TenantRegistrationController::class, 'register'])->name('tenant.register.submit');
Route::get('/register/tenant/success', [TenantRegistrationController::class, 'success'])->name('tenant.register.success');

// Route pour récupérer le port d'un tenant
Route::get('/tenant/{subdomain}/port', [TenantRegistrationController::class, 'getTenantPortFromCache'])->name('tenant.port');



// Routes d'inscription
Route::get('/register', [RegisterController::class, 'showRegistrationForm'])->name('register');
Route::post('/register', [RegisterController::class, 'register']);

// Route du dashboard (protégée par le middleware d'authentification)
Route::middleware(['auth'])->group(function () {
    
    
    // Routes de gestion des utilisateurs
    Route::resource('users', UserController::class);

    // Routes d'administration (protégées par middleware auth et admin)
    Route::middleware(['admin'])->prefix('admin')->name('admin.')->group(function () {
        // Routes admin spécifiques si nécessaire
    });
});



// Affiche la page demandant de vérifier l'email
Route::get('/email/verify', function () {
    return view('auth.verify-email');
})->middleware('auth')->name('verification.notice');
Route::get('/email/verify/{id}/{hash}', function (EmailVerificationRequest $request) {
    $request->fulfill();

    // Récupérer l'URL du projet cloné depuis la session (ou la base, ou un helper)
    $projectUrl = session('tenant_base_url');
    if (!$projectUrl) {
        // Valeur de secours si la session n'a pas l'URL
        $projectUrl = '/';
    }
    return redirect($projectUrl);
})->middleware(['auth', 'signed'])->name('verification.verify');
Route::post('/email/verification-notification', function (Request $request) {
    $request->user()->sendEmailVerificationNotification();
    return back()->with('resent', true);
})->middleware(['auth', 'throttle:6,1'])->name('verification.resend');

// Routes admin pour la gestion des ports
Route::middleware(['auth', 'admin'])->prefix('admin/ports')->group(function () {
    
    // Voir toutes les associations port <-> sous-domaine
    Route::get('/', [PortController::class, 'index'])->name('admin.ports.index');
    
    // Libérer un port spécifique
    Route::delete('/{port}', [PortController::class, 'releasePort'])->name('admin.ports.release');
    
    // Réassigner un port à un sous-domaine
    Route::put('/reassign', [PortController::class, 'reassignPort'])->name('admin.ports.reassign');
    
    // Assigner un port à un nouveau tenant
    Route::post('/assign', [PortController::class, 'assignPort'])->name('admin.ports.assign');
    
    // Nettoyer les associations orphelines
    Route::post('/cleanup', [PortController::class, 'cleanup'])->name('admin.ports.cleanup');
});