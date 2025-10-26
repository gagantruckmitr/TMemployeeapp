<?php
namespace App\Exports;

use Illuminate\Contracts\View\View;
use Maatwebsite\Excel\Concerns\FromView;
use Illuminate\Http\Request;
use DB;
use PhpOffice\PhpSpreadsheet\Shared\Date;
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;


class DriverExport implements FromView, WithColumnFormatting
{
    protected $request;

    public function __construct(Request $request) {
        $this->request = $request;
    }

    public function view(): View
    {
        $query = DB::table('users')
            ->leftJoin('states', function($join) {
                $join->on(DB::raw('CAST(users.states AS UNSIGNED)'), '=', 'states.id');
            })
            ->leftJoin('payments', function ($join) {
                $join->on('users.id', '=', 'payments.user_id')
                     ->where('payments.payment_status', '=', 'captured'); // only captured payments
            })
            ->where('users.role', 'driver')
            ->select(
                'users.*',
                'states.name as state_name',
                DB::raw('CASE WHEN payments.id IS NOT NULL THEN 1 ELSE 0 END as has_payment')
            )
            ->orderBy('users.created_at', 'desc');

        // Apply filters same as your driver_list method
        if ($this->request->filled('added_by')) {
            if ($this->request->added_by == 'transporter') {
                $query->whereNotNull('sub_id');
            } elseif ($this->request->added_by == 'self') {
                $query->whereNull('sub_id');
            }
        }

        if ($this->request->filled('state_name')) {
            $query->where('states', $this->request->state_name);
        }

        if ($this->request->filled('from_date') && $this->request->filled('to_date')) {
            $from = date('Y-m-d 00:00:00', strtotime($this->request->from_date));
            $to   = date('Y-m-d 23:59:59', strtotime($this->request->to_date));
            $query->whereBetween('users.created_at', [$from, $to]);
        }

        if ($this->request->filled('status')) {
            $query->where('status', $this->request->status == 'active' ? '1' : '0');
        }

    $driver = $query->get()->map(function ($d) {
    // Convert only date part into Excel format
    $d->Created_at = $d->Created_at ? Date::stringToExcel(date('Y-m-d', strtotime($d->Created_at))) : null;
    $d->Updated_at = $d->Updated_at ? Date::stringToExcel(date('Y-m-d', strtotime($d->Updated_at))) : null;
    return $d;
});

        return view('Admin.exports.driver', compact('driver'));
    }

    // Specify column formats for Excel
   public function columnFormats(): array
{
    return [
        'L' => 'DD MMM YYYY', // Created_at column
        'M' => 'DD MMM YYYY', // Updated_at column
    ];
}
}
