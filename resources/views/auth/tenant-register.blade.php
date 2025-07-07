<!DOCTYPE html>
<html>
<head>
    <title>Créer votre Espace - Laravel Multi-Tenant</title>
    <style>
        /* Using the same styles as the login page for consistency */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
        .container { background: white; border-radius: 20px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); max-width: 500px; width: 100%; overflow: hidden; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2rem; text-align: center; }
        .header h1 { font-size: 2rem; margin-bottom: 0.5rem; }
        .header p { opacity: 0.9; font-size: 1.1rem; }
        .form-container { padding: 2rem; }
        .form-group { margin-bottom: 1.5rem; }
        label { display: block; margin-bottom: 0.5rem; color: #333; font-weight: 500; }
        input { width: 100%; padding: 12px 16px; border: 2px solid #e1e5e9; border-radius: 10px; font-size: 1rem; transition: border-color 0.3s ease; }
        input:focus { outline: none; border-color: #667eea; }
        .submit-btn { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 30px; border: none; border-radius: 10px; font-size: 1.1rem; cursor: pointer; width: 100%; transition: transform 0.3s ease; }
        .submit-btn:hover { transform: translateY(-2px); }
        .login-link { text-align: center; margin-top: 1.5rem; color: #666; }
        .login-link a { color: #667eea; text-decoration: none; font-weight: 500; }
        .login-link a:hover { text-decoration: underline; }
        .error { background: #fee; color: #c33; padding: 10px; border-radius: 5px; margin-bottom: 1rem; border: 1px solid #fcc; }
        .error ul { list-style-position: inside; padding-left: 0; }
        @keyframes spin { 100% { transform: rotate(360deg); } }
        .dot {
            display: inline-block;
            width: 10px; height: 10px;
            margin: 0 3px;
            background: #6366f1;
            border-radius: 50%;
            animation: bounce 1s infinite alternate;
        }
        .dot:nth-child(2) { animation-delay: 0.2s; }
        .dot:nth-child(3) { animation-delay: 0.4s; }
        @keyframes bounce { to { transform: translateY(-10px); } }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Créez votre Espace</h1>
            <p>Rejoignez-nous et lancez votre service en quelques secondes.</p>
        </div>
        
        <div class="form-container">
            @if($errors->any())
                <div class="error">
                    <ul>
                        @foreach($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif
            
            <form method="POST" action="{{ route('tenant.register.submit') }}">
                @csrf
                
                <div class="form-group">
                    <label for="company_name">Nom de votre entreprise *</label>
                    <input type="text" id="company_name" name="company_name" value="{{ old('company_name') }}" placeholder="Ex: Ma Super Entreprise" required>
                </div>

                <div class="form-group">
                    <label for="subdomain">Sous-domaine souhaité *</label>
                    <input type="text" id="subdomain" name="subdomain" value="{{ old('subdomain') }}" placeholder="Ex: masuperentreprise" required>
                    <small style="color: #666; display: block; margin-top: 5px;">Votre URL sera : <span style="font-weight: bold; color: #667eea;">votresousdomaine</span>.localhost:8000</small>
                </div>

                <div class="form-group">
                    <label for="project">Sélectionnez un projet à cloner :</label>
                    <select name="project" required>
                        <option value="">Choisir un projet</option>
                        @foreach($projects as $project)
                            <option value="{{ $project->name }}">{{ $project->display_name }}</option>
                        @endforeach
                    </select>
                </div>

                <hr style="border: 1px solid #eee; margin: 2rem 0;">

                <div class="form-group">
                    <label for="admin_name">Votre nom (Administrateur) *</label>
                    <input type="text" id="admin_name" name="admin_name" value="{{ old('admin_name') }}" required>
                </div>

                <div class="form-group">
                    <label for="admin_email">Votre email (Administrateur) *</label>
                    <input type="email" id="admin_email" name="admin_email" value="{{ old('admin_email') }}" required>
                </div>

                <div class="form-group">
                    <label for="admin_password">Votre mot de passe (Administrateur) *</label>
                    <input type="password" id="admin_password" name="admin_password" required>
                </div>

                <div class="form-group">
                    <label for="admin_password_confirmation">Confirmez votre mot de passe *</label>
                    <input type="password" id="admin_password_confirmation" name="admin_password_confirmation" required>
                </div>
                
                <button id="register-btn" type="submit" class="login-btn">
                    <span id="register-btn-text">Créer mon espace</span>
                    <span id="register-btn-spinner" style="display:none;margin-left:10px;">
                        <svg width="20" height="20" viewBox="0 0 50 50">
                            <circle cx="25" cy="25" r="20" fill="none" stroke="#6366f1" stroke-width="5" stroke-linecap="round" stroke-dasharray="31.4 31.4" transform="rotate(-90 25 25)">
                                <animateTransform attributeName="transform" type="rotate" from="0 25 25" to="360 25 25" dur="1s" repeatCount="indefinite"/>
                            </circle>
                        </svg>
                    </span>
                </button>
            </form>
        </div>
    </div>
    <div id="loader-overlay" style="display:none;position:fixed;top:0;left:0;width:100vw;height:100vh;background:rgba(255,255,255,0.85);z-index:9999;align-items:center;justify-content:center;">
        <div style="font-size:2rem;color:#6366f1;">
            <span class="spinner" style="display:inline-block;width:2.5rem;height:2.5rem;border:4px solid #6366f1;border-top:4px solid #fff;border-radius:50%;animation:spin 1s linear infinite;margin-bottom:1rem;"></span>
            <br>
            Création de votre espace en cours...
        </div>
    </div>
    <div id="progress-bar" style="position:fixed;top:0;left:0;width:0;height:4px;background:#6366f1;z-index:9999;transition:width 0.4s;"></div>
    <div id="dots-loader" style="display:none;text-align:center;">
        <span class="dot"></span><span class="dot"></span><span class="dot"></span>
    </div>
    <script>
    document.addEventListener('DOMContentLoaded', function() {
        var form = document.querySelector('form');
        var btn = document.getElementById('register-btn');
        var text = document.getElementById('register-btn-text');
        var spinner = document.getElementById('register-btn-spinner');
        var bar = document.getElementById('progress-bar');
        if(form && btn && spinner && bar) {
            form.addEventListener('submit', function() {
                btn.disabled = true;
                text.textContent = 'Création en cours...';
                spinner.style.display = 'inline-block';
                bar.style.width = '100vw';
                document.getElementById('dots-loader').style.display = 'block';
            });
        }
    });
    </script>
</body>
</html> 