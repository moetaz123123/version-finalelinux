@if(!isset($tenant_name))
    <script>window.location.href = '/login';</script>
    @php exit; @endphp
@endif

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Inscription Réussie ! - Laravel Multi-Tenant</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            font-family: 'Segoe UI', sans-serif; 
            margin: 0;
        }
        .card {
            background: #fff;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 3rem 2rem;
            max-width: 430px;
            width: 100%;
            text-align: center;
        }
        .icon {
            font-size: 4rem;
            color: #34D399;
            margin-bottom: 1.2rem;
        }
        h1 {
            color: #333;
            font-size: 2rem;
            margin-bottom: 1rem;
        }
        ul {
            list-style: none;
            padding: 0;
            margin-bottom: 2rem;
            text-align: left;
        }
        ul li {
            margin-bottom: 0.7rem;
            color: #444;
            font-size: 1.08rem;
        }
        ul li strong {
            color: #764ba2;
        }
        p {
            color: #666;
            font-size: 1.1rem;
            margin-bottom: 2rem;
        }
        .login-btn {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 14px 32px;
            border: none;
            border-radius: 10px;
            font-size: 1.1rem;
            text-decoration: none;
            transition: transform 0.2s;
            box-shadow: 0 4px 12px rgba(118,75,162,0.12);
        }
        .login-btn:hover {
            transform: translateY(-2px) scale(1.03);
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">🎉</div>
        <h1>Félicitations, {{ $tenant_name }} !</h1>
        <ul>
            <li><strong>Nom de l'entreprise :</strong> {{ $tenant_name }}</li>
            <li><strong>Sous-domaine :</strong> {{ $subdomain }}.localhost</li>
            <li><strong>Email admin :</strong> {{ $admin_email }}</li>
            <li><strong>Chemin :</strong> {{ $path }}</li>
        </ul>
        <p>Votre espace a été créé avec succès.<br>Vous pouvez maintenant vous connecter et commencer à utiliser notre service.</p>
        <a href="{{ $login_url }}" class="login-btn">Accéder à mon espace</a>
    </div>

    @if(session('steps'))
        <div style="background: #222; color: #eee; padding: 1em; border-radius: 8px; font-family: monospace;">
            @foreach(session('steps') as $step)
                <div>{!! $step !!}</div>
            @endforeach
        </div>
    @endif
</body>
</html> 