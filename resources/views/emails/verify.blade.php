@component('mail::message')
# Bienvenue, {{ $tenantName }} !

Merci pour votre inscription. Voici vos informations :

- **Nom du tenant** : {{ $tenantName }}
- **Email administrateur** : {{ $adminEmail }}
- **URL de connexion** : [{{ $loginUrl }}]({{ $loginUrl }})

Avant de pouvoir accéder à votre espace, veuillez vérifier votre adresse email en cliquant sur le bouton ci-dessous.

@component('mail::button', ['url' => $verificationUrl])
Vérifier mon email
@endcomponent

Merci,<br>
L’équipe {{ config('app.name') }}
@endcomponent
