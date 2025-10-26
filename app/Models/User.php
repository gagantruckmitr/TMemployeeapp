<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;
use App\Models\Payment;  
class User extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
		'job_id',
        'unique_id',
        'sub_id',
        'role',
        'name',
        'name_eng',
        'mobile',
        'email',
        'password',
        'states',
        'city',
        'pincode',
        'address',
        'father_name',
        'dob',
        'status',
        'sex',
        'marital_status',
        'highest_education',
        'vehicle_type',
        'driving_experience',
        'preferred_location',
        'current_monthly_income',
        'expected_monthly_income',
        'type_of_license',
        'license_number',
        'expiry_date_of_license',
        'Aadhar_Number',
        'abroad_job_interest',
        'reference_check',
        'aadhar_photo',
        'driving_license',
        'login_otp',
        'provider',
        'provider_id',
        'previous_employer',
        'job_placement',
        'avatar',
        'abroad_job_interest',
        'reference_check',
        'images', 
        'pan_image', 
        'gst_certificate', 
        'registered_id', 
        'transport_name',
        'year_of_establishment', 
        'fleet_size', 
        'operational_segment', 
        'average_km', 
        'pan_number', 
        'user_lang',
        'gst_number'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'otp',  // Hiding OTP for security
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'operational_segment' => 'array',
		'Operational_Segment' => 'array',
        'email_verified_at' => 'datetime',
    ];
	

    /**
     * Get the identifier that will be stored in the subject claim of the JWT.
     *
     * @return mixed
     */
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

  public function payments()
    {
        return $this->hasMany(Payment::class);  
    }
    /**
     * Get custom claims to add to the JWT.
     *
     * @return array
     */
    public function getJWTCustomClaims()
    {
        return [];
    }
	
public function fcmTokens()
{
    return $this->hasMany(UserFcmToken::class);
}
	public function notifications()
{
    return $this->hasMany(Notification::class);
}

    // Define subscription relationship
    public function subscription()
    {
        return $this->hasOne(Subscription::class); // assumes 1 subscription per user
    }

}
