@if(!isset($tenant_name))
    @php exit; @endphp
@endif

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Succès de l'inscription - Multi-Tenant</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://fonts.googleapis.com/css?family=Montserrat:400,700&display=swap" rel="stylesheet">
    <style>
        body {
            background: #f4f6fb;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Montserrat', Arial, sans-serif;
            margin: 0;
        }
        .success-container {
            background: #fff;
            border-radius: 18px;
            box-shadow: 0 8px 32px rgba(80, 80, 160, 0.12);
            padding: 2.5rem 2.2rem 2rem 2.2rem;
            max-width: 540px;
            width: 100%;
            text-align: center;
        }
        .checkmark {
            font-size: 3.5rem;
            color: #4ade80;
            margin-bottom: 1.2rem;
        }
        h1 {
            color: #2d2e32;
            font-size: 2.1rem;
            margin-bottom: 0.7rem;
            font-weight: 700;
        }
        .tenant-fields {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.7rem 1.2rem;
            background: #f8fafc;
            border-radius: 12px;
            padding: 1.2rem 1rem 0.7rem 1rem;
            margin-bottom: 1.5rem;
            text-align: left;
            font-size: 1.04rem;
        }
        .tenant-fields .label {
            color: #6366f1;
            font-weight: 600;
        }
        .tenant-fields .value {
            color: #374151;
            word-break: break-all;
        }
        .timeline-title {
            color: #6366f1;
            font-size: 1.08rem;
            font-weight: 700;
            margin-bottom: 0.7rem;
            margin-top: 1.2rem;
            text-align: left;
        }
        .timeline {
            position: relative;
            margin: 0 0 1.5rem 0;
            padding-left: 25px;
            text-align: left;
        }
        .timeline:before {
            content: '';
            position: absolute;
            left: 10px;
            top: 0;
            bottom: 0;
            width: 3px;
            background: linear-gradient(180deg, #6366f1 0%, #a5b4fc 100%);
            border-radius: 2px;
        }
        .timeline-step {
            position: relative;
            margin-bottom: 1.1rem;
            padding-left: 18px;
            display: flex;
            align-items: flex-start;
        }
        .timeline-step:last-child { margin-bottom: 0; }
        .timeline-dot {
            position: absolute;
            left: -7px;
            top: 2px;
            width: 16px;
            height: 16px;
            background: #fff;
            border: 3px solid #6366f1;
            border-radius: 50%;
            z-index: 1;
        }
        .timeline-content {
            background: #eef2ff;
            border-radius: 8px;
            padding: 0.7rem 1rem;
            color: #3730a3;
            font-size: 1rem;
            margin-left: 10px;
            box-shadow: 0 2px 8px rgba(99,102,241,0.04);
            width: 100%;
        }
        .login-btn {
            display: inline-block;
            background: linear-gradient(90deg, #6366f1 0%, #a5b4fc 100%);
            color: white;
            padding: 14px 32px;
            border: none;
            border-radius: 10px;
            font-size: 1.1rem;
            text-decoration: none;
            transition: transform 0.2s;
            box-shadow: 0 4px 12px rgba(99,102,241,0.10);
            margin-top: 1.2rem;
            font-weight: 600;
        }
        .login-btn:hover {
            transform: translateY(-2px) scale(1.03);
            background: linear-gradient(90deg, #818cf8 0%, #6366f1 100%);
        }
        @media (max-width: 600px) {
            .success-container { padding: 1.2rem 0.5rem; }
            .tenant-fields { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="success-container">
        <div class="checkmark">✅</div>
        <h1>Bienvenue, {{ $tenant_name ?? $company_name }} !</h1>
        <div class="tenant-fields">
            <div class="label">Entreprise</div>
            <div class="value">{{ $tenant_name ?? $company_name }}</div>
            <div class="label">Sous-domaine</div>
            <div class="value">{{ $subdomain }}.localhost</div>
            <div class="label">Port</div>
            <div class="value">{{ session('port', 'N/A') }}</div>
            <div class="label">URL complète</div>
            <div class="value">http://{{ $subdomain }}.localhost:{{ session('port', 'N/A') }}</div>
            <div class="label">Email admin</div>
            <div class="value">{{ $admin_email }}</div>
            <div class="label">Chemin</div>
            <div class="value">{{ $path }}</div>
        </div>
        <br>
        @php
            $project_url = 'http://' . $subdomain . '.localhost:' . session('port', 'N/A');
        @endphp
        <a href="{{ $project_url }}" class="login-btn" target="_blank" style="margin-top:0.7rem;background:#4ade80;">Accéder à mon projet cloné</a>
        <div style="margin-top:1.2rem;font-size:1.08rem;color:#6366f1;">
            URL de votre projet : <span style="color:#374151;font-weight:600;">{{ $project_url }}</span>
        </div>
    </div>
</body>
</html> 