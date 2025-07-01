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
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
            min-height: 100vh; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            padding: 20px;
            position: relative;
            overflow: hidden;
        }
        
        /* Particules animées en arrière-plan */
        body::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="1" fill="rgba(255,255,255,0.1)"/></svg>') repeat;
            animation: float 20s ease-in-out infinite;
            pointer-events: none;
        }
        
        @keyframes float {
            0%, 100% { transform: translateY(0px) rotate(0deg); }
            50% { transform: translateY(-20px) rotate(180deg); }
        }
        
        .card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-radius: 25px;
            box-shadow: 0 25px 50px rgba(0,0,0,0.15);
            padding: 3.5rem 2.5rem;
            max-width: 500px;
            width: 100%;
            text-align: center;
            position: relative;
            border: 1px solid rgba(255, 255, 255, 0.2);
            animation: slideIn 0.8s ease-out;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(30px) scale(0.9);
            }
            to {
                opacity: 1;
                transform: translateY(0) scale(1);
            }
        }
        
        .success-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #34D399, #10B981);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 2rem;
            box-shadow: 0 10px 30px rgba(52, 211, 153, 0.3);
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }
        
        .success-icon i {
            font-size: 2.5rem;
            color: white;
        }
        
        h1 {
            color: #1F2937;
            font-size: 2.2rem;
            margin-bottom: 1.5rem;
            font-weight: 700;
            background: linear-gradient(135deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .info-grid {
            display: grid;
            gap: 1rem;
            margin-bottom: 2.5rem;
        }
        
        .info-item {
            background: linear-gradient(135deg, #f8fafc, #e2e8f0);
            border-radius: 15px;
            padding: 1.2rem;
            text-align: left;
            border-left: 4px solid #667eea;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .info-item:hover {
            transform: translateX(5px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.1);
        }
        
        .info-item::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, rgba(102, 126, 234, 0.05), rgba(118, 75, 162, 0.05));
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        
        .info-item:hover::before {
            opacity: 1;
        }
        
        .info-label {
            font-weight: 600;
            color: #374151;
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 0.3rem;
        }
        
        .info-value {
            color: #1F2937;
            font-size: 1.1rem;
            font-weight: 500;
        }
        
        .info-icon {
            position: absolute;
            right: 1rem;
            top: 50%;
            transform: translateY(-50%);
            color: #667eea;
            font-size: 1.2rem;
            opacity: 0.7;
        }
        
        .description {
            color: #6B7280;
            font-size: 1.1rem;
            margin-bottom: 2.5rem;
            line-height: 1.6;
        }
        
        .login-btn {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1rem 2rem;
            border: none;
            border-radius: 15px;
            font-size: 1.1rem;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.3);
            position: relative;
            overflow: hidden;
        }
        
        .login-btn::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
            transition: left 0.5s;
        }
        
        .login-btn:hover::before {
            left: 100%;
        }
        
        .login-btn:hover {
            transform: translateY(-3px) scale(1.02);
            box-shadow: 0 12px 35px rgba(102, 126, 234, 0.4);
        }
        
        .login-btn:active {
            transform: translateY(-1px) scale(1.01);
        }
        
        .login-btn i {
            font-size: 1.2rem;
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .card {
                padding: 2.5rem 1.5rem;
                margin: 1rem;
            }
            
            h1 {
                font-size: 1.8rem;
            }
            
            .info-item {
                padding: 1rem;
            }
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="success-icon">
            <i class="fas fa-check"></i>
        </div>
        
        <h1>Félicitations, {{ $tenant_name }} !</h1>
        
        <div class="info-grid">
            <div class="info-item">
                <div class="info-label">🏢 Nom de l'entreprise</div>
                <div class="info-value">{{ $tenant_name }}</div>
                <i class="fas fa-building info-icon"></i>
            </div>
            
            <div class="info-item">
                <div class="info-label">🌐 Sous-domaine</div>
                <div class="info-value">{{ $subdomain }}.localhost</div>
                <i class="fas fa-globe info-icon"></i>
            </div>
            
            <div class="info-item">
                <div class="info-label">👤 Email administrateur</div>
                <div class="info-value">{{ $admin_email }}</div>
                <i class="fas fa-user-shield info-icon"></i>
            </div>
            
            <div class="info-item">
                <div class="info-label">📁 Chemin d'accès</div>
                <div class="info-value">{{ $path }}</div>
                <i class="fas fa-folder info-icon"></i>
            </div>
        </div>
        
        <p class="description">
            Votre espace a été créé avec succès ! 🎉<br>
            Vous pouvez maintenant vous connecter et commencer à utiliser notre service.
        </p>
        
        <a href="{{ $login_url }}" class="login-btn">
            <i class="fas fa-sign-in-alt"></i>
            Accéder à mon espace
        </a>
    </div>
</body>
</html> 