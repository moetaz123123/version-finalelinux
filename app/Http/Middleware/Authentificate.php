<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;

class Authentificate extends Middleware
{
protected function redirectTo($request)
{
    // Retourner une erreur 403 si l'utilisateur n'est pas authentifié
    abort(403, 'Accès refusé.');
}
}