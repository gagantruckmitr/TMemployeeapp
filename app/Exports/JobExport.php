<?php
namespace App\Exports;

use DB;
use App\Models\Job;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Concerns\FromView;
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use PhpOffice\PhpSpreadsheet\Shared\Date;

class JobExport implements FromView, WithColumnFormatting
{
    protected $request;

    public function __construct(Request $request)
    {
        $this->request = $request;
    }

       public function view(): View
    {
        $query = DB::table('jobs')
            ->leftJoin('users', 'jobs.transporter_id', '=', 'users.id')
            ->select(
                'jobs.*',
                'users.unique_id as tm_id',
                'users.name as transporter_name',
                'users.mobile as transporter_mobile'
            );

        // 🔹 Apply filters
        if ($this->request->filled('tm_id')) {
            $query->where('users.unique_id', $this->request->tm_id);
        }

        if ($this->request->filled('status')) {
            $query->where('jobs.status', $this->request->status === 'active' ? 1 : 0);
        }

        if ($this->request->filled('active_inactive')) {
            $query->where('jobs.active_inactive', $this->request->active_inactive === 'active' ? 1 : 0);
        }

        if ($this->request->filled('from_date')) {
            $query->whereDate('jobs.Created_at', '>=', $this->request->from_date);
        }

        if ($this->request->filled('to_date')) {
            $query->whereDate('jobs.Created_at', '<=', $this->request->to_date);
        }

        // 🔹 Fetch results
        $Jobs = $query->orderBy('jobs.id', 'desc')->get();

        // 🔹 Convert only date part for Excel
        $Jobs->transform(function ($j) {
            $j->Created_at = $j->Created_at 
                ? Date::stringToExcel(date('Y-m-d', strtotime($j->Created_at))) 
                : null;

            $j->Application_Deadline = $j->Application_Deadline 
                ? Date::stringToExcel(date('Y-m-d', strtotime($j->Application_Deadline))) 
                : null;

            return $j;
        });

        return view('Admin.exports.jobs', compact('Jobs'));
    }

    // Specify column formats for Excel
    public function columnFormats(): array
    {
        return [
            'N' => 'DD MMM YYYY', // Created_at column
            'O' => 'DD MMM YYYY', // Deadline column
        ];
    }
}
