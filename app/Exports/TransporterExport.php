<?php
namespace App\Exports;

use Illuminate\Contracts\View\View;
use Maatwebsite\Excel\Concerns\FromView;
use Illuminate\Http\Request;
use DB;
use PhpOffice\PhpSpreadsheet\Shared\Date;
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;


class TransporterExport implements FromView, WithColumnFormatting
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
            ->where('users.role', 'transporter')
            ->select(
                'users.*',
                'states.name as state_name',
                DB::raw('CASE WHEN payments.id IS NOT NULL THEN 1 ELSE 0 END as has_payment')
            )
            ->orderBy('users.created_at', 'desc');

        // Apply filters
        if ($this->request->filled('state')) {
            $query->where('state', $this->request->state);
        }

        if ($this->request->filled('status')) {
            if ($this->request->status == 'active') {
                $query->where('status', 1);
            } elseif ($this->request->status == 'inactive') {
                $query->where('status', 0);
            }
        }

        if ($this->request->filled('from_date') && $this->request->filled('to_date')) {
            $from = date('Y-m-d 00:00:00', strtotime($this->request->from_date));
            $to   = date('Y-m-d 23:59:59', strtotime($this->request->to_date));
            $query->whereBetween('created_at', [$from, $to]);
        }

    $transporter = $query->get()->map(function ($t) {
    // Convert only date part into Excel format
    $t->Created_at = $t->Created_at ? Date::stringToExcel(date('Y-m-d', strtotime($t->Created_at))) : null;
    $t->Updated_at = $t->Updated_at ? Date::stringToExcel(date('Y-m-d', strtotime($t->Updated_at))) : null;
    return $t;
});

        return view('Admin.exports.export', compact('transporter'));
    }

    // Specify column formats for Excel
   public function columnFormats(): array
{
    return [
        'H' => 'DD MMM YYYY', // Created_at column
        'I' => 'DD MMM YYYY', // Updated_at column
    ];
}
}
