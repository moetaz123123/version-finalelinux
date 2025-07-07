@component('mail::message')
# Bienvenue, {{ $tenantName }} !

Merci pour votre inscription sur notre plateforme multi-tenant.

**Informations de votre espace :**

- **Nom du tenant** : {{ $tenantName }}
- **Email administrateur** : {{ $adminEmail }}
- **URL de connexion** : [{{ $loginUrl }}]({{ $loginUrl }})


Merci et bienvenue,<br>
L’équipe {{ config('app.name') }}
@endcomponent
