<?php

namespace App\Imports;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash; 
use App\Models\User; // Import your model
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Str;
use DB;
use PhpOffice\PhpSpreadsheet\Shared\Date;
use Carbon\Carbon;




use Maatwebsite\Excel\Concerns\WithValidation;
use Maatwebsite\Excel\Concerns\SkipsOnFailure;
use Maatwebsite\Excel\Concerns\SkipsFailures;
use Maatwebsite\Excel\Validators\Failure;

class DriverImport implements ToModel, WithHeadingRow, WithValidation, SkipsOnFailure
{
    use SkipsFailures; // This ensures failed rows are skipped

    public function model(array $row)
{
    // Trim and convert mobile number to string
    $mobile = trim((string) $row['mobile']);
    $email  = trim((string) $row['email'] ?? '');

    // Check if the mobile number already exists
    $mobileExists = User::where('mobile', $mobile)->exists();

    // Check if email exists only if it's not blank
    $emailExists = !empty($email) && User::where('email', $email)->exists();

    // If mobile or email exists, log the error and skip this row
    if ($mobileExists || $emailExists) {
        session()->push('import_errors', [
            'row'    => $row,
            'error'  => $mobileExists ? "Mobile number $mobile already exists." : "Email $email already exists.",
        ]);
        return null; 
    }

    return new User([
        'role'        => 'driver',
        'unique_id'   => generate_nomenclature_id('TD', $row['states_code']),
        'sub_id'      => Session::get('id'), 
        'name'        => $row['name'],
        'email'       => $email ?: null, // Allow email to be null
        'mobile'      => $mobile,
        'password'    => bcrypt('defaultpassword'),
        'states'      => $row['states_code'],
        'login_otp'   => 0,
        'images'      => 'images/default.jpg',
		'status'      => 1,
    ]);
}

// Define validation rules
public function rules(): array
{
    return [
        'mobile' => 'required|numeric|digits:10|unique:users,mobile', // Ensure mobile is unique
        'email'  => 'nullable|email|unique:users,email', // Email is optional but must be unique if provided
    ];
}

// Custom validation messages
public function customValidationMessages()
{
    return [
        'email.unique'  => 'The email :input is already registered.',
        'mobile.unique' => 'The mobile number :input is already registered.',
    ];
}

}

