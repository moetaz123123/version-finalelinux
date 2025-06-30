@extends('layouts.app')

@section('content')
    <h2>Contenu du dossier : {{ $path }}</h2>
    <ul>
        @foreach($files as $file)
            @if($file !== '.' && $file !== '..')
                <li>{{ $file }}</li>
            @endif
        @endforeach
    </ul>
    <a href="{{ url('/home') }}">Retour</a>
@endsection
