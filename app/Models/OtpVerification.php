<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OtpVerification extends Model
{
    use HasFactory;

    protected $fillable = ['mobile', 'otp', 'expires_at', 'name', 'email']; // ✅ Name & Email added
    public $timestamps = false; 
}
