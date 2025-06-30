<?php

namespace App\Models;

class Project
{
    // Liste statique des projets disponibles (tu peux aussi les stocker en BDD si besoin)
    public static function all()
    {
        return [
            [
                'name' => 'sas-laravel',
                'repo_url' => 'https://github.com/moetaz123123/sas-laravel.git',
            ],
            [
                'name' => 'hh-laravel',
                'repo_url' => 'https://github.com/moetaz123123/hh-laravel.git',
            ],
        ];
    }

    // Trouver un projet par son nom
    public static function findByName($name)
    {
        foreach (self::all() as $project) {
            if ($project['name'] === $name) {
                return $project;
            }
        }
        return null;
    }
}
