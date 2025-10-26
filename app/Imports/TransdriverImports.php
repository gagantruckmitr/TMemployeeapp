<?php
namespace App\Imports;

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;
use Maatwebsite\Excel\Concerns\SkipsOnFailure;
use Maatwebsite\Excel\Concerns\SkipsFailures;
use Illuminate\Validation\Rule;

class DriverImport implements ToModel, WithHeadingRow, WithValidation, SkipsOnFailure
{
    use SkipsFailures;

    protected $transporter_id;

    public function __construct()
    {
        $this->transporter_id = Auth::id(); // Logged-in transporter ID
    }

    public function model(array $row)
    {
        return new User([
            'name'           => $row['name'] ?? '',
            'email'          => $row['email'] ?? null,
            'mobile'         => $row['mobile'] ?? '',
            'states_code'    => $row['states_code'] ?? null,
            'user_type'      => 'driver',
            'transporter_id' => $this->transporter_id,
            'password'       => bcrypt('12345678'), // Default password
        ]);
    }

    public function rules(): array
    {
        return [
            'mobile' => [
                'required',
                'numeric',
                'digits:10',
                Rule::unique('users', 'mobile'),
            ],
            'email' => [
                'nullable',
                'email',
                Rule::unique('users', 'email'),
            ],
        ];
    }

    public function customValidationMessages()
    {
        return [
            'email.unique'  => 'The email :input is already registered.',
            'mobile.unique' => 'The mobile number :input is already registered.',
        ];
    }
}
