<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class CustomVerifyEmail extends Mailable
{
    use Queueable, SerializesModels;

    public $tenantName;
    public $adminEmail;
    public $loginUrl;
    public $verificationUrl;
    public $projectUrl;

    /**
     * Create a new message instance.
     */
    public function __construct($tenantName, $adminEmail, $loginUrl, $verificationUrl, $projectUrl)
    {
        $this->tenantName = $tenantName;
        $this->adminEmail = $adminEmail;
        $this->loginUrl = $loginUrl;
        $this->verificationUrl = $verificationUrl;
        $this->projectUrl = $projectUrl;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Custom Verify Email',
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            markdown: 'emails.verify',
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }

    public function build()
    {
        return $this->subject('Vérifiez votre adresse email')
            ->markdown('emails.verify');
    }
}
