<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromCollection;
use App\Models\CallbackRequest;
use Maatwebsite\Excel\Concerns\WithHeadings;
use DB;
use Illuminate\Contracts\View\View;
use Carbon\Carbon;

class CallbackRequestExport implements FromCollection, WithHeadings
{
    protected $fromDate;
    protected $toDate;

   public function __construct($fromDate, $toDate)
    {
       $this->fromDateUtc = Carbon::createFromFormat('Y-m-d', $fromDate, 'Asia/Kolkata')
            ->startOfDay()
            ->setTimezone('UTC');

        $this->toDateUtc = Carbon::createFromFormat('Y-m-d', $toDate, 'Asia/Kolkata')
            ->endOfDay()
            ->setTimezone('UTC');
    }

    public function collection()
{
    $records = \App\Models\CallbackRequest::whereBetween('created_at', [
        $this->fromDateUtc,
        $this->toDateUtc
    ])->get([
        'id', 'unique_id', 'user_name', 'mobile_number', 'request_date_time',
        'contact_reason', 'app_type', 'status', 'notes', 'created_at'
    ]);

    // Format created_at and return as collection
    return $records->map(function ($record) {
        return [
            'id' => $record->id,
            'unique_id' => $record->unique_id,
            'user_name' => $record->user_name,
            'mobile_number' => $record->mobile_number,
            'request_date_time' => $record->request_date_time,
            'contact_reason' => $record->contact_reason,
            'app_type' => $record->app_type,
            'status' => $record->status,
            'notes' => $record->notes,

            // ✅ format the date and time (and convert to local timezone if needed)
            'created_at' => \Carbon\Carbon::parse($record->created_at)
                ->timezone('Asia/Kolkata')  // optional: convert from UTC to your local timezone
                ->format('d-m-Y H:i:s'),    // or 'Y-m-d H:i:s'
        ];
    });
}


     public function headings(): array
    {
        return [
            'ID', 'Unique ID', 'User Name', 'Mobile Number', 'Request Date Time',
            'Contact Reason', 'App Type', 'Status', 'Notes', 'Created At',
        ];
    }
}
