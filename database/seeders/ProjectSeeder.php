<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Project;

class ProjectSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $projects = [
            [
                'name' => 'sas-laravel',
                'display_name' => 'SAS Laravel Application',
                'description' => 'Application Laravel complète avec authentification et gestion des utilisateurs',
                'repo_url' => 'https://github.com/moetaz123123/sas-laravel.git',
                'repo_name' => 'sas-laravel',
                'category' => 'Laravel',
                'version' => '1.0.0',
                'is_active' => true,
            ],
            [
                'name' => 'hh-laravel',
                'display_name' => 'HH Laravel Application',
                'description' => 'Application Laravel avec fonctionnalités avancées',
                'repo_url' => 'https://github.com/moetaz123123/hh-laravel.git',
                'repo_name' => 'hh-laravel',
                'category' => 'Laravel',
                'version' => '1.0.0',
                'is_active' => true,
            ],
            [
                'name' => 'ecommerce-laravel',
                'display_name' => 'E-commerce Laravel',
                'description' => 'Application e-commerce complète avec panier et paiements',
                'repo_url' => 'https://github.com/moetaz123123/ecommerce-laravel.git',
                'repo_name' => 'ecommerce-laravel',
                'category' => 'E-commerce',
                'version' => '1.0.0',
                'is_active' => true,
            ],
            [
                'name' => 'blog-laravel',
                'display_name' => 'Blog Laravel',
                'description' => 'Système de blog avec gestion des articles et commentaires',
                'repo_url' => 'https://github.com/moetaz123123/blog-laravel.git',
                'repo_name' => 'blog-laravel',
                'category' => 'Blog',
                'version' => '1.0.0',
                'is_active' => true,
            ],
        ];

        foreach ($projects as $project) {
            Project::updateOrCreate(
                ['name' => $project['name']],
                $project
            );
        }
    }
}
