@extends('layouts.app')

@section('content')
    <div>
        <h1>Vérification de l'email</h1>
        <p>Avant de continuer, veuillez vérifier votre adresse email en cliquant sur le lien que nous venons de vous envoyer.</p>
        <form method="POST" action="{{ route('verification.resend') }}">
            @csrf
            <button type="submit">Renvoyer l'email de vérification</button>
        </form>
    </div>
@endsection
